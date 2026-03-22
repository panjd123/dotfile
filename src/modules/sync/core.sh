# Shared rsync/scp sync engine used by all higher-level sync commands.
_remote_sync_scp_fallback() {
    local mode="$1"
    local local_dir="$2"
    local remote_dir="$3"
    local remote_target="$4"
    local patterns_csv="$5"
    local extra_opts="$6"
    shift 6
    local remote_opts=("$@")

    local local_dir_clean="${local_dir%/}"
    local remote_dir_clean="${remote_dir%/}"
    local ignore_existing=0
    if [[ " $extra_opts " == *" --ignore-existing "* ]]; then
        ignore_existing=1
    fi

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
            local normalized_pattern
            local local_file
            local has_source=0
            read -r -a patterns <<< "$patterns_csv"
            IFS=$' \t\n'

            for pattern in "${patterns[@]}"; do
                normalized_pattern="${pattern%/}"
                local matched=0
                local -a matched_files=()
                while IFS= read -r -d '' local_file; do
                    matched_files+=("$local_file")
                done < <(find "$local_dir_clean" -mindepth 1 -maxdepth 1 \
                    \( -type f -o -type d \) -name "$normalized_pattern" -print0)

                if [ ${#matched_files[@]} -eq 0 ]; then
                    echo "⚠️  跳过不存在的路径: $local_dir_clean/$normalized_pattern"
                    continue
                fi

                for local_file in "${matched_files[@]}"; do
                    has_source=1
                    # `--ignore-existing` is implemented here so the scp fallback
                    # preserves rsync's "seed missing files only" behavior.
                    if [ "$ignore_existing" -eq 1 ] && \
                        "${ssh_cmd[@]}" "$remote_target" "[ -e ${remote_dir_clean}/$(basename "$local_file") ]"; then
                        echo "ℹ️  目标已存在，跳过: ${remote_dir_clean}/$(basename "$local_file")"
                        matched=1
                        continue
                    fi
                    "${scp_cmd[@]}" "$local_file" "${remote_target}:${remote_dir_clean}/"
                    if [ $? -ne 0 ]; then
                        return 1
                    fi
                    matched=1
                done
                if [ "$matched" -eq 0 ]; then
                    echo "⚠️  未匹配到路径: $local_dir_clean/$normalized_pattern"
                fi
            done
            if [ "$has_source" -eq 0 ]; then
                echo "⚠️  未发现可同步路径，已按无变更处理"
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
            local normalized_pattern
            local remote_files
            local found_any=0
            read -r -a patterns <<< "$patterns_csv"
            IFS=$' \t\n'

            for pattern in "${patterns[@]}"; do
                normalized_pattern="${pattern%/}"
                remote_files=$("${ssh_cmd[@]}" "$remote_target" \
                    "for f in ${remote_dir_clean}/${normalized_pattern}; do
                        [ -e \"$f\" ] && printf '%s\n' \"$f\";
                    done")
                if [ -z "$remote_files" ]; then
                    echo "⚠️  未找到远程路径: ${remote_dir_clean}/${normalized_pattern}"
                    continue
                fi

                while IFS= read -r remote_file; do
                    [ -z "$remote_file" ] && continue
                    found_any=1
                    if [ "$ignore_existing" -eq 1 ] && [ -e "$local_dir_clean/$(basename "$remote_file")" ]; then
                        echo "ℹ️  本地已存在，跳过: $local_dir_clean/$(basename "$remote_file")"
                        continue
                    fi
                    "${scp_cmd[@]}" "${remote_target}:${remote_file}" "$local_dir_clean/"
                    if [ $? -ne 0 ]; then
                        return 1
                    fi
                done <<< "$remote_files"
            done
            if [ "$found_any" -eq 0 ]; then
                echo "⚠️  未找到可同步路径，已按无变更处理"
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

    local -a rsync_opts=(--mkpath)
    if [ -n "$extra_opts" ]; then
        # extra_opts is passed as shell-style flags such as `--links` or
        # `--ignore-existing`; split it so rsync receives each flag separately.
        # shellcheck disable=SC2206
        local -a parsed_extra_opts=($extra_opts)
        rsync_opts+=("${parsed_extra_opts[@]}")
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
        # The full-tree fast path still needs separate push/pull argument order.
        # Otherwise pull commands log the right direction but actually push.
        if [ "$mode" = "push" ]; then
            rsync -avzP "${rsync_opts[@]}" -e "$ssh_cmd" \
                "$local_dir" "${remote_target}:$remote_dir"
            rsync_exit=$?
        else
            rsync -avzP "${rsync_opts[@]}" -e "$ssh_cmd" \
                "${remote_target}:$remote_dir" "$local_dir"
            rsync_exit=$?
        fi
    else
        local -a patterns=()
        local IFS='|'
        read -r -a patterns <<< "$patterns_csv"
        IFS=$' \t\n'

        local -a rsync_includes=()
        local pattern
        for pattern in "${patterns[@]}"; do
            rsync_includes+=(--include="$pattern")
            # A trailing slash marks a top-level directory pattern. rsync needs
            # the directory itself and all descendants included before exclude='*'.
            if [[ "$pattern" == */ ]]; then
                rsync_includes+=(--include="${pattern}***")
            fi
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
    _remote_sync_scp_fallback "$mode" "$local_dir" "$remote_dir" "$remote_target" "$patterns_csv" "$extra_opts" "${remote_opts[@]}"
    if [ $? -eq 0 ]; then
        echo "✅ scp 回退同步完成"
        return 0
    fi
    echo "❌ scp 回退同步失败"
    return 1
}
