_remote_sync_scp_fallback() {
    local mode="$1"
    local local_dir="$2"
    local remote_dir="$3"
    local remote_target="$4"
    local patterns_csv="$5"
    shift 5
    local remote_opts=("$@")

    local local_dir_clean="${local_dir%/}"
    local remote_dir_clean="${remote_dir%/}"

    local -a scp_cmd=(scp -r)
    if [ ${#remote_opts[@]} -gt 0 ]; then
        scp_cmd+=("${remote_opts[@]}")
    fi

    local -a ssh_cmd=(ssh)
    if [ ${#remote_opts[@]} -gt 0 ]; then
        ssh_cmd+=("${remote_opts[@]}")
    fi

    case "$mode" in
        push)
            "${ssh_cmd[@]}" "$remote_target" "mkdir -p $remote_dir_clean"
            if [ $? -ne 0 ]; then
                return 1
            fi
            if [ -z "$patterns_csv" ]; then
                "${scp_cmd[@]}" "$local_dir_clean/." "${remote_target}:${remote_dir_clean}/"
                return $?
            fi

            local IFS='|'
            local -a patterns=()
            local pattern
            local local_file
            local has_source=0
            read -r -a patterns <<< "$patterns_csv"
            IFS=$' \t\n'

            for pattern in "${patterns[@]}"; do
                local matched=0
                local -a matched_files=()
                while IFS= read -r -d '' local_file; do
                    matched_files+=("$local_file")
                done < <(find "$local_dir_clean" -maxdepth 1 -type f -name "$pattern" -print0)

                if [ ${#matched_files[@]} -eq 0 ]; then
                    echo "⚠️  跳过不存在的文件: $local_dir_clean/$pattern"
                    continue
                fi

                for local_file in "${matched_files[@]}"; do
                    "${scp_cmd[@]}" "$local_file" "${remote_target}:${remote_dir_clean}/"
                    if [ $? -ne 0 ]; then
                        return 1
                    fi
                    has_source=1
                    matched=1
                done
                if [ "$matched" -eq 0 ]; then
                    echo "⚠️  未匹配到文件: $local_dir_clean/$pattern"
                fi
            done
            if [ "$has_source" -eq 0 ]; then
                echo "⚠️  未发现可同步文件，已按无变更处理"
            fi
            ;;
        pull)
            mkdir -p "$local_dir_clean"
            if [ -z "$patterns_csv" ]; then
                "${scp_cmd[@]}" "${remote_target}:${remote_dir_clean}/." "$local_dir_clean/"
                return $?
            fi

            local IFS='|'
            local -a patterns=()
            local pattern
            local remote_files
            local found_any=0
            read -r -a patterns <<< "$patterns_csv"
            IFS=$' \t\n'

            for pattern in "${patterns[@]}"; do
                remote_files=$("${ssh_cmd[@]}" "$remote_target" \
                    "for f in ${remote_dir_clean}/${pattern}; do
                        [ -e \"$f\" ] && printf '%s\n' \"$f\";
                    done")
                if [ -z "$remote_files" ]; then
                    echo "⚠️  未找到远程文件: ${remote_dir_clean}/${pattern}"
                    continue
                fi

                while IFS= read -r remote_file; do
                    [ -z "$remote_file" ] && continue
                    "${scp_cmd[@]}" "${remote_target}:${remote_file}" "$local_dir_clean/"
                    if [ $? -ne 0 ]; then
                        return 1
                    fi
                    found_any=1
                done <<< "$remote_files"
            done
            if [ "$found_any" -eq 0 ]; then
                echo "⚠️  未找到可同步文件，已按无变更处理"
            fi
            ;;
        *)
            echo "Unknown sync mode: $mode"
            return 1
            ;;
    esac
    return 0
}

_remote_sync() {
    local mode="$1"
    local local_dir="$2"
    local remote_dir="$3"
    local patterns_csv="$4"
    local sync_label="$5"
    local extra_opts="$6"
    shift 6

    if [ "$mode" != "push" ] && [ "$mode" != "pull" ]; then
        echo "Unknown sync mode: $mode"
        return 1
    fi

    if [ $# -lt 1 ]; then
        echo "Usage: ${sync_label}_${mode} <ssh_target> [ssh_opts...]"
        echo "Example: ${sync_label}_${mode} user@host -p 2022"
        return 1
    fi

    local -a remote_args=("$@")
    local remote_target="${remote_args[0]}"

    local -a remote_opts=()
    if [ ${#remote_args[@]} -gt 1 ]; then
        remote_opts=("${remote_args[@]:1}")
    fi

    local ssh_cmd="ssh"
    if [ ${#remote_opts[@]} -gt 0 ]; then
        ssh_cmd+=" ${remote_opts[*]}"
    fi

    local rsync_opts=(--mkpath)
    if [ -n "$extra_opts" ]; then
        rsync_opts+=("$extra_opts")
    fi

    if [ "$mode" = "push" ]; then
        echo "Pushing local -> remote"
        echo "From: $local_dir"
        echo "To:   ${remote_target}:$remote_dir"
    else
        echo "Pulling remote -> local"
        echo "From: ${remote_target}:$remote_dir"
        echo "To:   $local_dir"
    fi

    local rsync_exit=1
    if [ -z "$patterns_csv" ]; then
        rsync -avzP "${rsync_opts[@]}" -e "$ssh_cmd" \
            "$local_dir" "${remote_target}:$remote_dir"
        rsync_exit=$?
    else
        local -a patterns=()
        local IFS='|'
        read -r -a patterns <<< "$patterns_csv"
        IFS=$' \t\n'

        local -a rsync_includes=()
        local pattern
        for pattern in "${patterns[@]}"; do
            rsync_includes+=(--include="$pattern")
        done

        if [ "$mode" = "push" ]; then
            rsync -avzP "${rsync_opts[@]}" -e "$ssh_cmd" \
                "${rsync_includes[@]}" \
                --exclude='*' \
                "$local_dir" "${remote_target}:$remote_dir"
            rsync_exit=$?
        else
            rsync -avzP "${rsync_opts[@]}" -e "$ssh_cmd" \
                "${rsync_includes[@]}" \
                --exclude='*' \
                "${remote_target}:$remote_dir" "$local_dir"
            rsync_exit=$?
        fi
    fi

    if [ $rsync_exit -eq 0 ]; then
        echo "Sync complete"
        return 0
    fi

    echo "⚠️  rsync 同步失败，自动回退到 scp ..."
    _remote_sync_scp_fallback "$mode" "$local_dir" "$remote_dir" "$remote_target" "$patterns_csv" "${remote_opts[@]}"
    if [ $? -eq 0 ]; then
        echo "✅ scp 回退同步完成"
        return 0
    fi
    echo "❌ scp 回退同步失败"
    return 1
}

_hf_sync() {
    if [ $# -lt 2 ]; then
        local func_name="${FUNCNAME[1]}"
        echo "Usage: $func_name <ssh_target> [ssh_opts...] <model_name>"
        echo "Example: $func_name user@host -p 2022 Qwen/Qwen3-8B"
        return 1
    fi

    local model="${@: -1}"
    local remote_args=("${@:1:$#-1}")
    local mode
    case "${FUNCNAME[1]}" in
        hf_push) mode="push" ;;
        hf_pull) mode="pull" ;;
        *) echo "❌ Unknown function name"; return 1 ;;
    esac

    local local_base="$HOME/.cache/huggingface/hub"
    local model_dir="models--${model//\//--}"
    local local_dir="$local_base/$model_dir/"
    local remote_dir="~/.cache/huggingface/hub/$model_dir/"

    echo "🔄 Syncing HuggingFace model cache: $model"
    _remote_sync "$mode" "$local_dir" "$remote_dir" "" "hf" "--links" "${remote_args[@]}"
}

hf_push() { _hf_sync "$@"; }
hf_pull() { _hf_sync "$@"; }
alias hf-push='hf_push'
alias hf-pull='hf_pull'

_data_sync() {
    if [ $# -lt 2 ]; then
        local func_name="${FUNCNAME[1]}"
        echo "Usage: $func_name <ssh_target> [ssh_opts...] <dir_name>"
        echo "Example: $func_name user@host -p 2022 data"
        return 1
    fi

    local dir="${@: -1}"
    local remote_args=("${@:1:$#-1}")
    local mode
    case "${FUNCNAME[1]}" in
        data_push) mode="push" ;;
        data_pull) mode="pull" ;;
        *) echo "❌ Unknown function name"; return 1 ;;
    esac

    local local_dir="$HOME/$dir"
    local remote_dir="~/$dir"

    echo "🔄 Syncing directory: $dir"
    _remote_sync "$mode" "$local_dir/" "$remote_dir/" "" "data" "--links" "${remote_args[@]}"
}

# 对外接口
data_push() { _data_sync "$@"; }
data_pull() { _data_sync "$@"; }
alias data-push='data_push'
alias data-pull='data_pull'

hf_list() {
    local CACHE_DIR="${HF_HOME:-$HOME/.cache}/huggingface/hub"

    if [ ! -d "$CACHE_DIR" ]; then
        echo "Cache directory does not exist: $CACHE_DIR"
        return 1
    fi

    declare -A grouped_models

    # 遍历所有模型目录
    for dir in "$CACHE_DIR"/models--*/; do
        local model_dir
        model_dir=$(basename "$dir")
        # 去掉 models-- 前缀
        local model_name="${model_dir//models--/}"
        # 将 -- 替换为 /，得到 user/model-name
        model_name="${model_name//--//}"
        # 取前缀作为分组 key
        local prefix="${model_name%%/*}"
        grouped_models["$prefix"]+="$model_name"$'\n'
    done

    echo "Models in Hugging Face cache (grouped by prefix):"
    echo "-------------------------------------------------"

    # 输出分组，前缀排序
    for prefix in $(printf "%s\n" "${!grouped_models[@]}" | sort); do
        echo "$prefix:"
        while IFS= read -r model; do
            [ -z "$model" ] && continue
            echo "  - $model"
        done <<< "$(printf "%s" "${grouped_models[$prefix]}" | sort)"
    done
}
alias hf-list='hf_list'

_claude_sync() {
    local sync_mode="$1"
    shift
    _remote_sync "$sync_mode" "$HOME/.claude/" "~/.claude/" "settings.json|settings.json.*" "claude" "" "$@"
}

claude_push() { _claude_sync "push" "$@"; }
claude_pull() { _claude_sync "pull" "$@"; }
alias claude-push='claude_push'
alias claude-pull='claude_pull'

_codex_sync() {
    local sync_mode="$1"
    shift
    local patterns="auth.json|auth.json.*|config.toml.*"
    _remote_sync "$sync_mode" "$HOME/.codex/" "~/.codex/" "$patterns" "codex" "" "$@"
}

codex_push() { _codex_sync "push" "$@"; }
codex_pull() { _codex_sync "pull" "$@"; }
alias codex-push='codex_push'
alias codex-pull='codex_pull'
