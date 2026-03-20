# Sync Codex local auth/config files between machines.
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
