# Sync OpenCode local config files between machines.
_opencode_sync() {
    local sync_mode="$1"
    shift
    # Plugins are managed as their own git repo and are not part of opencode sync.
    local patterns="opencode.json|oh-my-opencode.json"
    _remote_sync "$sync_mode" "$HOME/.config/opencode/" "~/.config/opencode/" "$patterns" "opencode" "" "$@"
}

opencode_push() { _opencode_sync "push" "$@"; }
opencode_pull() { _opencode_sync "pull" "$@"; }
alias opencode-push='opencode_push'
alias opencode-pull='opencode_pull'
