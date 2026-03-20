# Sync arbitrary home-directory subtrees between machines.
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
