# Sync Hugging Face model cache directories between machines.
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
