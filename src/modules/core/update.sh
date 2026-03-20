# Manual update entrypoint available after the file has been sourced.
# -------- 手动更新命令 --------
update_dotfile() {
  echo "[dotfile] 正在更新..."
  if [ -d "$DOTFILES_DIR/.git" ]; then
    if ! git -C "$DOTFILES_DIR" pull --rebase --autostash; then
      echo "[dotfile] 错误: 更新失败。"
      return 1
    fi
    echo "[dotfile] 更新完成 ✅"
    dotfile_reload_common_file
  else
    echo "[dotfile] 未检测到 git 仓库，使用直接下载方式获取 bashrc_common.sh ..."
    if ! dotfile_download_common_file; then
      echo "[dotfile] 错误: 下载失败。"
      return 1
    fi
    echo "[dotfile] 下载完成 ✅"
    dotfile_reload_common_file
  fi
}
alias update_dotfile='update_dotfile'
alias update-dotfile='update_dotfile'
