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
  local rc_file_display=""
  local desired_source_line="source $COMMON_FILE_DISPLAY"
  local legacy_source_line="source $COMMON_FILE"

  rc_file_display=$(dotfile_display_path "$rc_file")

  if [ ! -f "$rc_file" ]; then
    touch "$rc_file" || return 1
    echo "[dotfile] 已创建 $rc_file_display"
  fi

  if grep -qF "$desired_source_line" "$rc_file"; then
    echo "[dotfile] $rc_file_display 已包含对 $COMMON_FILE_DISPLAY 的引用，跳过此步骤。"
    return 0
  fi

  if grep -qF "$legacy_source_line" "$rc_file"; then
    local tmp_file=""
    tmp_file=$(mktemp) || return 1

    # Rewrite only the legacy line we previously generated.
    if ! awk -v old="$legacy_source_line" -v new="$desired_source_line" '{ print ($0 == old ? new : $0) }' "$rc_file" > "$tmp_file"; then
      rm -f "$tmp_file"
      return 1
    fi

    if ! mv "$tmp_file" "$rc_file"; then
      rm -f "$tmp_file"
      return 1
    fi

    echo "[dotfile] 已将 $rc_file_display 中的引用更新为 $COMMON_FILE_DISPLAY"
    return 0
  fi

  printf 'source %s\n' "$COMMON_FILE_DISPLAY" >> "$rc_file" || return 1
  echo "[dotfile] 已自动将 $COMMON_FILE_DISPLAY 加入 $rc_file_display"
}

dotfile_ensure_shell_sources() {
  local rc_file=""

  for rc_file in $(dotfile_detect_shell_rc_files); do
    dotfile_ensure_shell_rc_source "$rc_file" || return 1
  done
}
