# Sync Claude local config files between machines.
_claude_sync() {
    local sync_mode="$1"
    shift
    # Profile settings can be machine-specific, so we only seed missing
    # settings.json.* files and never sync the active settings.json directly.
    _remote_sync "$sync_mode" "$HOME/.claude/" "~/.claude/" "settings.json.*" "claude" "--ignore-existing" "$@"
}

claude_push() { _claude_sync "push" "$@"; }
claude_pull() { _claude_sync "pull" "$@"; }
alias claude-push='claude_push'
alias claude-pull='claude_pull'
