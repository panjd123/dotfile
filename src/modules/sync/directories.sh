# Bash expands an unquoted `~` before the function sees it, so accept both
# literal `~/...` and already-expanded `$HOME/...`. Paths under the current
# user's home are re-mapped to each machine's own home; other absolute paths
# are kept as-is on both sides.
_data_sync_resolve_paths() {
    local input_path="$1"
    local normalized_path
    local local_dir
    local remote_dir

    case "$input_path" in
        "~"|"~/")
            normalized_path=""
            local_dir="$HOME"
            remote_dir="~"
            ;;
        "~/"*)
            normalized_path="${input_path#\~/}"
            local_dir="$HOME/$normalized_path"
            remote_dir="~/$normalized_path"
            ;;
        "~"*)
            echo "❌ 只支持当前用户的 ~ 路径，不支持 ~otheruser: $input_path" >&2
            return 1
            ;;
        "$HOME"|"$HOME"/)
            normalized_path=""
            local_dir="$HOME"
            remote_dir="~"
            ;;
        "$HOME"/*)
            normalized_path="${input_path#"$HOME"/}"
            local_dir="$HOME/$normalized_path"
            remote_dir="~/$normalized_path"
            ;;
        /*)
            normalized_path="${input_path%/}"
            local_dir="$normalized_path"
            remote_dir="$normalized_path"
            ;;
        *)
            normalized_path="$input_path"
            while [[ "$normalized_path" == ./* ]]; do
                normalized_path="${normalized_path#./}"
            done
            local_dir="$HOME/$normalized_path"
            remote_dir="~/$normalized_path"
            ;;
    esac

    normalized_path="${normalized_path%/}"
    if [[ "$normalized_path" == ".." || "$normalized_path" == ../* || "$normalized_path" == */../* || "$normalized_path" == */.. ]]; then
        echo "❌ data-push/data-pull 不支持包含 .. 的路径: $input_path" >&2
        return 1
    fi

    printf '%s\n%s\n' "$local_dir" "$remote_dir"
}

# Sync arbitrary home-directory subtrees between machines.
_data_sync() {
    if [ $# -lt 2 ]; then
        local func_name="${FUNCNAME[1]}"
        echo "Usage: $func_name <ssh_target> [ssh_opts...] <path>"
        echo "Example: $func_name user@host -p 2022 data"
        echo "Example: $func_name user@host '~/.cache/huggingface'"
        echo "Example: $func_name user@host /mnt/shared"
        echo "Paths under the current user's home are remapped to each machine's own ~."
        echo "Other absolute paths are synced as the same absolute path on both sides."
        return 1
    fi

    local input_path="${@: -1}"
    local remote_args=("${@:1:$#-1}")
    local mode
    case "${FUNCNAME[1]}" in
        data_push) mode="push" ;;
        data_pull) mode="pull" ;;
        *) echo "❌ Unknown function name"; return 1 ;;
    esac

    local resolved_paths
    resolved_paths="$(_data_sync_resolve_paths "$input_path")" || return 1
    local local_dir
    local remote_dir
    local_dir="$(printf '%s\n' "$resolved_paths" | sed -n '1p')"
    remote_dir="$(printf '%s\n' "$resolved_paths" | sed -n '2p')"

    echo "🔄 Syncing path: $input_path"
    _remote_sync "$mode" "$local_dir/" "$remote_dir/" "" "data" "--links" "${remote_args[@]}"
}

# 对外接口
data_push() { _data_sync "$@"; }
data_pull() { _data_sync "$@"; }
alias data-push='data_push'
alias data-pull='data_pull'
