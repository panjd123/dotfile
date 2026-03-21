# Sync Claude local config files between machines.
_claude_sync() {
    local sync_mode="$1"
    shift
    # Claude settings can be machine-specific, so push/pull only seeds missing
    # files on the receiver and never overwrites an existing one.
    _remote_sync "$sync_mode" "$HOME/.claude/" "~/.claude/" "settings.json|settings.json.*" "claude" "--ignore-existing" "$@"
}

claude_push() { _claude_sync "push" "$@"; }
claude_pull() { _claude_sync "pull" "$@"; }
alias claude-push='claude_push'
alias claude-pull='claude_pull'
