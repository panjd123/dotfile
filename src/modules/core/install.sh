# End-user install command, usable from both repo checkouts and curl installs.
dotfile_install() {
  echo "[dotfile] 检查 dotfile 仓库..."

  # Install works in both "full repo checkout" and "curl single-file" modes.
  if [ ! -d "$DOTFILES_DIR/.git" ]; then
    echo "[dotfile] 使用直接下载方式获取 bashrc_common.sh ..."
    if ! dotfile_download_common_file; then
      echo "[dotfile] 错误: 下载 bashrc_common.sh 失败。"
      return 1
    fi
  else
    echo "[dotfile] 更新已有仓库..."
    if ! git -C "$DOTFILES_DIR" pull --quiet; then
      echo "[dotfile] 错误: 更新仓库失败。"
      return 1
    fi
  fi

  dotfile_refresh_network_region
  dotfile_ensure_bashrc_source

  echo "正在扫描系统变更..."
  dotfile_install_reset_plan
  dotfile_plan_sshd_changes
  dotfile_plan_key_changes

  if [ ${#DOTFILE_INSTALL_PLAN_SSH_CONFIG[@]} -eq 0 ] && [ ${#DOTFILE_INSTALL_PLAN_SSH_KEYS[@]} -eq 0 ]; then
    echo "[dotfile] SSH 配置与公钥均已是最新状态，无需操作。"
    echo "[dotfile] 安装完成。重新打开终端或执行 'source $COMMON_FILE' 生效。"
    return 0
  fi

  echo ""
  echo "=========================================="
  echo "         检测到以下待变更项"
  echo "=========================================="

  if [ ${#DOTFILE_INSTALL_PLAN_SSH_CONFIG[@]} -eq 0 ]; then
    echo -e "\n[SSH 配置] 已是最新状态，无需修改。"
  else
    echo -e "\n[SSH 配置变更] (将修改 $DOTFILE_SSHD_CONFIG_FILE):"
    printf "  - %s\n" "${DOTFILE_INSTALL_PLAN_SSH_CONFIG[@]}"
  fi

  if [ ${#DOTFILE_INSTALL_PLAN_SSH_KEYS[@]} -gt 0 ]; then
    echo -e "\n[SSH 公钥变更] (将写入 $DOTFILE_AUTHORIZED_KEYS_FILE):"
    printf "  - %s\n" "${DOTFILE_INSTALL_PLAN_SSH_KEYS[@]}"
  fi

  echo ""
  read -p "[dotfile] 是否执行上述变更？: " -n 1 -r < /dev/tty
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "[dotfile] 开始执行变更..."

    if [ ${#DOTFILE_INSTALL_PLAN_SSH_CONFIG[@]} -gt 0 ]; then
      if [ -w "$DOTFILE_SSHD_CONFIG_FILE" ]; then
        echo "[dotfile] 检测到有写权限，直接修改配置..."
        dotfile_apply_sshd_changes false
      else
        echo "[dotfile] SSH 配置文件需要管理员权限，正在请求 sudo..."
        if sudo -v 2>/dev/null; then
          dotfile_apply_sshd_changes true
        else
          echo "[dotfile] 错误: 无法获取 sudo 权限，跳过 SSH 配置修改。"
        fi
      fi
    fi

    if [ ${#DOTFILE_INSTALL_PLAN_SSH_KEYS[@]} -gt 0 ]; then
      dotfile_apply_key_changes
    fi

    echo "[dotfile] 变更已完成。"
  else
    echo "[dotfile] 已取消变更。"
  fi

  echo "[dotfile] 安装完成。重新打开终端或执行 'source $COMMON_FILE' 生效。"
}
