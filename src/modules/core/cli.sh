# CLI subcommands exposed when bashrc_common.sh is executed instead of sourced.
dotfile_cli_usage() {
  cat <<'EOF'
Usage:
  bashrc_common.sh install [options]
  bashrc_common.sh refresh-region
  bashrc_common.sh detect-region
  bashrc_common.sh help

Install options:
  -y, --yes, -b, --batch
  --ssh=prompt|apply|skip
  --ssh-keys=prompt|apply|skip
  --sshd=prompt|apply|skip
EOF
}

dotfile_cli() {
  local command="${1:-help}"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  case "$command" in
    install)
      dotfile_install "$@"
      ;;
    refresh-region)
      dotfile_refresh_network_region
      ;;
    detect-region)
      dotfile_detect_network_region
      ;;
    help|-h|--help)
      dotfile_cli_usage
      ;;
    *)
      echo "[dotfile] 未知命令: $command" >&2
      dotfile_cli_usage >&2
      return 1
      ;;
  esac
}

dotfile_cli_dispatch_if_executed() {
  # Zsh exposes sourced files through ZSH_EVAL_CONTEXT, while Bash uses
  # BASH_SOURCE. Check both so `source bashrc_common.sh` does not dispatch.
  case "${ZSH_EVAL_CONTEXT-}" in
    *:file|*:file:*)
      return 0
      ;;
  esac

  local source0="${BASH_SOURCE[0]-}"

  # `source file.sh` keeps BASH_SOURCE[0] as the file path, while `bash -s --`
  # reports `main`. We only dispatch for true execution paths.
  if [ -n "$source0" ] && [ "$source0" != "$0" ] && [ "$source0" != "main" ]; then
    return 0
  fi

  dotfile_cli "$@"
  exit $?
}
