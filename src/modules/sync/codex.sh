# Sync Codex local auth/config files between machines.
_codex_sync() {
    local sync_mode="$1"
    shift
    _remote_sync "$sync_mode" "$HOME/.codex/" "~/.codex/" "auth.json|config.toml.*" "codex" "" "$@" || return 1

    # Profile auth files can contain machine-specific credentials, so they only
    # seed missing files on the receiver and never overwrite an existing one.
    _remote_sync "$sync_mode" "$HOME/.codex/" "~/.codex/" "auth.json.*" "codex" "--ignore-existing" "$@"
}

codex_push() { _codex_sync "push" "$@"; }
codex_pull() { _codex_sync "pull" "$@"; }
alias codex-push='codex_push'
alias codex-pull='codex_pull'
