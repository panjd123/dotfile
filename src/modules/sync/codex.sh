# Sync Codex auth/config files between machines.
_codex_sync() {
    local sync_mode="$1"
    shift
    # Codex auth/config files can be machine-specific, so push/pull only seeds
    # missing files on the receiver and never overwrites an existing one.
    _remote_sync "$sync_mode" "$HOME/.codex/" "~/.codex/" "auth.json|auth.json.*|config.toml|config.toml.*" "codex" "--ignore-existing" "$@"
}

codex_push() { _codex_sync "push" "$@"; }
codex_pull() { _codex_sync "pull" "$@"; }
alias codex-push='codex_push'
alias codex-pull='codex_pull'
