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

dotfile_ensure_bashrc_source() {
  if ! grep -qF "source $COMMON_FILE" "$HOME/.bashrc"; then
    echo "source $COMMON_FILE" >> "$HOME/.bashrc"
    echo "[dotfile] 已自动将 $COMMON_FILE 加入 ~/.bashrc"
  else
    echo "[dotfile] ~/.bashrc 已包含对 $COMMON_FILE 的引用，跳过此步骤。"
  fi
}
