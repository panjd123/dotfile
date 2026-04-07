# Install options are handled here instead of the top-level CLI so curl-piped
# and sourced usage share the same behavior.
dotfile_install_usage() {
  cat <<'EOF'
Usage:
  bashrc_common.sh install [options]

Options:
  -y, --yes, -b, --batch
      Non-interactive mode. By default it applies SSH key and sshd changes.
  --ssh=prompt|apply|skip
      Set the default policy for both SSH key and sshd changes.
  --ssh-keys=prompt|apply|skip
      Override only authorized_keys updates.
  --sshd=prompt|apply|skip
      Override only sshd_config updates.
  -h, --help
      Show this help.
EOF
}

dotfile_install_validate_policy() {
  case "$1" in
    prompt|apply|skip)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

dotfile_install_confirm() {
  local prompt="$1"

  if ! read -p "$prompt" -n 1 -r < /dev/tty; then
    echo ""
    return 1
  fi

  echo ""
  [[ $REPLY =~ ^[Yy]$ ]]
}

dotfile_apply_sshd_changes_with_auto_sudo() {
  local non_interactive="$1"

  if [ ${#DOTFILE_INSTALL_PLAN_SSH_CONFIG[@]} -eq 0 ]; then
    return 0
  fi

  if [ -w "$DOTFILE_SSHD_CONFIG_FILE" ]; then
    echo "[dotfile] 检测到有写权限，直接修改配置..."
    dotfile_apply_sshd_changes none
    return $?
  fi

  if [ "$non_interactive" = true ]; then
    echo "[dotfile] SSH 配置文件需要管理员权限，正在尝试 sudo -n ..."
    if sudo -n true >/dev/null 2>&1; then
      dotfile_apply_sshd_changes noninteractive
      return $?
    fi

    echo "[dotfile] 错误: 修改 $DOTFILE_SSHD_CONFIG_FILE 需要 sudo，但当前环境无法无交互获取 sudo 权限。"
    return 1
  fi

  echo "[dotfile] SSH 配置文件需要管理员权限，正在请求 sudo..."
  if sudo -v; then
    dotfile_apply_sshd_changes interactive
    return $?
  fi

  echo "[dotfile] 错误: 无法获取 sudo 权限。"
  return 1
}

# End-user install command, usable from both repo checkouts and curl installs.
dotfile_install() {
  local non_interactive=false
  local ssh_policy=""
  local ssh_keys_policy=""
  local sshd_policy=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -y|--yes|-b|--batch)
        non_interactive=true
        ;;
      --ssh=*)
        ssh_policy="${1#*=}"
        ;;
      --ssh-keys=*)
        ssh_keys_policy="${1#*=}"
        ;;
      --sshd=*)
        sshd_policy="${1#*=}"
        ;;
      -h|--help)
        dotfile_install_usage
        return 0
        ;;
      *)
        echo "[dotfile] 错误: install 不支持参数: $1" >&2
        dotfile_install_usage >&2
        return 1
        ;;
    esac
    shift
  done

  if [ -n "$ssh_policy" ] && ! dotfile_install_validate_policy "$ssh_policy"; then
    echo "[dotfile] 错误: --ssh 仅支持 prompt、apply、skip。" >&2
    return 1
  fi

  if [ -n "$ssh_keys_policy" ] && ! dotfile_install_validate_policy "$ssh_keys_policy"; then
    echo "[dotfile] 错误: --ssh-keys 仅支持 prompt、apply、skip。" >&2
    return 1
  fi

  if [ -n "$sshd_policy" ] && ! dotfile_install_validate_policy "$sshd_policy"; then
    echo "[dotfile] 错误: --sshd 仅支持 prompt、apply、skip。" >&2
    return 1
  fi

  if [ -z "$ssh_policy" ]; then
    if [ "$non_interactive" = true ]; then
      ssh_policy="apply"
    else
      ssh_policy="prompt"
    fi
  fi

  if [ -z "$ssh_keys_policy" ]; then
    ssh_keys_policy="$ssh_policy"
  fi

  if [ -z "$sshd_policy" ]; then
    sshd_policy="$ssh_policy"
  fi

  if [ "$non_interactive" = true ]; then
    if [ "$ssh_keys_policy" = "prompt" ] || [ "$sshd_policy" = "prompt" ]; then
      echo "[dotfile] 错误: 非交互模式下不能使用 prompt 策略，请改用 apply 或 skip。" >&2
      return 1
    fi
  fi

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
  dotfile_ensure_shell_sources || return 1

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

  if [ ${#DOTFILE_INSTALL_PLAN_SSH_KEYS[@]} -gt 0 ]; then
    case "$ssh_keys_policy" in
      apply)
        echo "[dotfile] 开始写入 SSH 公钥..."
        dotfile_apply_key_changes || return 1
        ;;
      skip)
        echo "[dotfile] 根据策略跳过 SSH 公钥变更。"
        ;;
      prompt)
        echo ""
        if dotfile_install_confirm "[dotfile] 是否写入上述 SSH 公钥变更？: "; then
          echo "[dotfile] 开始写入 SSH 公钥..."
          dotfile_apply_key_changes || return 1
        else
          echo "[dotfile] 已跳过 SSH 公钥变更。"
        fi
        ;;
    esac
  fi

  if [ ${#DOTFILE_INSTALL_PLAN_SSH_CONFIG[@]} -gt 0 ]; then
    case "$sshd_policy" in
      apply)
        echo "[dotfile] 开始修改 SSH 配置..."
        dotfile_apply_sshd_changes_with_auto_sudo "$non_interactive" || return 1
        ;;
      skip)
        echo "[dotfile] 根据策略跳过 SSH 配置变更。"
        ;;
      prompt)
        echo ""
        if dotfile_install_confirm "[dotfile] 是否修改上述 SSH 配置？: "; then
          echo "[dotfile] 开始修改 SSH 配置..."
          dotfile_apply_sshd_changes_with_auto_sudo false || return 1
        else
          echo "[dotfile] 已跳过 SSH 配置变更。"
        fi
        ;;
    esac
  fi

  echo "[dotfile] 安装完成。重新打开终端或执行 'source $COMMON_FILE' 生效。"
}
