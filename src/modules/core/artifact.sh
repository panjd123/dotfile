# Fetch, reload, and register the generated single-file artifact.
dotfile_download_common_file() {
  mkdir -p "$DOTFILES_DIR"
  curl -sSfL "$DOTFILE_RAW_COMMON_URL" -o "$COMMON_FILE"
}

dotfile_reload_common_file() {
  if [ ! -f "$COMMON_FILE" ]; then
    return 0
  fi

  echo "[dotfile] 重新加载配置..."
  # Reload from the generated single-file artifact so updates take effect in the
  # current shell without requiring a new login shell.
  source "$COMMON_FILE"
  dotfile_refresh_network_region
  dotfile_apply_region_network_settings
  echo "[dotfile] 已重新加载 ✅"
}

dotfile_detect_shell_rc_files() {
  local -a rc_files=()

  if [ -f "$HOME/.bashrc" ] || command -v bash >/dev/null 2>&1; then
    rc_files+=("$HOME/.bashrc")
  fi

  if [ -f "$HOME/.zshrc" ] || command -v zsh >/dev/null 2>&1; then
    rc_files+=("$HOME/.zshrc")
  fi

  if [ ${#rc_files[@]} -eq 0 ]; then
    rc_files=("$HOME/.bashrc")
  fi

  printf '%s\n' "${rc_files[@]}"
}

dotfile_ensure_shell_rc_source() {
  local rc_file="$1"

  if [ ! -f "$rc_file" ]; then
    touch "$rc_file" || return 1
    echo "[dotfile] 已创建 $(basename "$rc_file")"
  fi

  if ! grep -qF "source $COMMON_FILE" "$rc_file"; then
    printf 'source %s\n' "$COMMON_FILE" >> "$rc_file" || return 1
    echo "[dotfile] 已自动将 $COMMON_FILE 加入 $rc_file"
  else
    echo "[dotfile] $rc_file 已包含对 $COMMON_FILE 的引用，跳过此步骤。"
  fi
}

dotfile_ensure_shell_sources() {
  local rc_file=""

  for rc_file in $(dotfile_detect_shell_rc_files); do
    dotfile_ensure_shell_rc_source "$rc_file" || return 1
  done
}
