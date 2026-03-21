# Batch-sync Claude, Codex, and OpenCode configs with one command.
_vibe_sync() {
    local sync_mode="$1"
    shift

    if [ "$sync_mode" != "push" ] && [ "$sync_mode" != "pull" ]; then
        echo "Unknown sync mode: $sync_mode"
        return 1
    fi

    if [ $# -lt 1 ]; then
        echo "Usage: vibe_${sync_mode} <ssh_target> [ssh_opts...]"
        echo "Example: vibe_${sync_mode} user@host -p 2022"
        return 1
    fi

    local sync_func=""
    local sync_label=""
    local -a sync_targets=(
        "claude"
        "codex"
        "opencode"
    )
    local target

    for target in "${sync_targets[@]}"; do
        sync_func="${target}_${sync_mode}"
        sync_label="${target}-${sync_mode}"
        echo "==> ${sync_label}"
        "$sync_func" "$@" || return 1
    done
}

vibe_push() { _vibe_sync "push" "$@"; }
vibe_pull() { _vibe_sync "pull" "$@"; }
alias vibe-push='vibe_push'
alias vibe-pull='vibe_pull'
