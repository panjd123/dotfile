DOTFILES_DIR="$HOME/.dotfile"
COMMON_FILE="$DOTFILES_DIR/bashrc_common.sh"
DOTFILE_RAW_COMMON_URL="https://raw.githubusercontent.com/panjd123/dotfile/master/bashrc_common.sh"
DOTFILE_NETWORK_REGION_FILE="$DOTFILES_DIR/.network_region"
DOTFILE_CN_PYPI_INDEX="https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
DOTFILE_CN_PYPI_HOST="mirrors.tuna.tsinghua.edu.cn"
DOTFILE_CN_HF_ENDPOINT="https://hf-mirror.com"
DOTFILE_AUTHORIZED_KEYS_FILE="$HOME/.ssh/authorized_keys"
DOTFILE_SSHD_CONFIG_FILE="/etc/ssh/sshd_config"

DOTFILE_SSH_PUBLIC_KEYS=(
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3Mt/bijvkMa15XthVwRu1BHH/WE66IaiYXyQonN6RX 1747366367@qq.com"
)

DOTFILE_SSH_CONFIG_CHECKS=(
  "PubkeyAuthentication yes"
)

declare -A DOTFILE_DEFAULT_SSH_VALUES
DOTFILE_DEFAULT_SSH_VALUES["PubkeyAuthentication"]="yes"
DOTFILE_DEFAULT_SSH_VALUES["PasswordAuthentication"]="yes"
DOTFILE_DEFAULT_SSH_VALUES["PermitRootLogin"]="prohibit-password"

declare -a DOTFILE_INSTALL_PLAN_SSH_CONFIG=()
declare -a DOTFILE_INSTALL_PLAN_SSH_KEYS=()

dotfile_read_network_region() {
  if [ ! -f "$DOTFILE_NETWORK_REGION_FILE" ]; then
    echo "UNKNOWN"
    return 0
  fi

  head -n 1 "$DOTFILE_NETWORK_REGION_FILE" 2>/dev/null | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]'
}

dotfile_write_network_region() {
  local region="${1:-UNKNOWN}"
  mkdir -p "$DOTFILES_DIR"
  printf '%s\n' "$region" > "$DOTFILE_NETWORK_REGION_FILE"
}

dotfile_detect_network_region() {
  local country_code=""
  local response=""
  local url=""
  local -a country_code_urls=(
    "https://ipinfo.io/country"
    "https://ifconfig.co/country-iso"
    "https://ipapi.co/country/"
  )

  if ! command -v curl >/dev/null 2>&1; then
    echo "UNKNOWN"
    return 0
  fi

  for url in "${country_code_urls[@]}"; do
    response=$(curl -fsSL --connect-timeout 2 --max-time 5 "$url" 2>/dev/null || true)
    country_code=$(printf '%s' "$response" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
    if [[ "$country_code" =~ ^[A-Z]{2}$ ]]; then
      break
    fi
  done

  if [[ ! "$country_code" =~ ^[A-Z]{2}$ ]]; then
    response=$(curl -fsSL --connect-timeout 2 --max-time 5 "https://cip.cc" 2>/dev/null || true)
    if printf '%s' "$response" | grep -Eiq '中国|china'; then
      country_code="CN"
    elif [ -n "$response" ]; then
      country_code="NON_CN"
    fi
  fi

  if [ "$country_code" = "CN" ]; then
    echo "CN"
  elif [[ "$country_code" =~ ^[A-Z]{2}$ ]] || [ "$country_code" = "NON_CN" ]; then
    echo "OVERSEAS"
  else
    echo "UNKNOWN"
  fi
}

dotfile_refresh_network_region() {
  local region
  region=$(dotfile_detect_network_region)
  dotfile_write_network_region "$region"
  echo "[dotfile] 当前网络区域: $region"
}

dotfile_apply_cn_network_settings() {
  export UV_DEFAULT_INDEX="$DOTFILE_CN_PYPI_INDEX"
  export PIP_INDEX_URL="$DOTFILE_CN_PYPI_INDEX"
  export PIP_TRUSTED_HOST="$DOTFILE_CN_PYPI_HOST"
  export HF_ENDPOINT="$DOTFILE_CN_HF_ENDPOINT"
}

dotfile_clear_cn_network_settings() {
  if [ "${UV_DEFAULT_INDEX:-}" = "$DOTFILE_CN_PYPI_INDEX" ]; then
    unset UV_DEFAULT_INDEX
  fi
  if [ "${PIP_INDEX_URL:-}" = "$DOTFILE_CN_PYPI_INDEX" ]; then
    unset PIP_INDEX_URL
  fi
  if [ "${PIP_TRUSTED_HOST:-}" = "$DOTFILE_CN_PYPI_HOST" ]; then
    unset PIP_TRUSTED_HOST
  fi
  if [ "${HF_ENDPOINT:-}" = "$DOTFILE_CN_HF_ENDPOINT" ]; then
    unset HF_ENDPOINT
  fi
}

dotfile_apply_region_network_settings() {
  if [ "$(dotfile_read_network_region)" = "CN" ]; then
    dotfile_apply_cn_network_settings
  else
    dotfile_clear_cn_network_settings
  fi
}

dotfile_download_common_file() {
  mkdir -p "$DOTFILES_DIR"
  curl -sSfL "$DOTFILE_RAW_COMMON_URL" -o "$COMMON_FILE"
}

dotfile_reload_common_file() {
  if [ ! -f "$COMMON_FILE" ]; then
    return 0
  fi

  echo "[dotfile] 重新加载配置..."
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

dotfile_install_reset_plan() {
  DOTFILE_INSTALL_PLAN_SSH_CONFIG=()
  DOTFILE_INSTALL_PLAN_SSH_KEYS=()
}

dotfile_plan_sshd_changes() {
  if [ ! -f "$DOTFILE_SSHD_CONFIG_FILE" ]; then
    return
  fi

  local item=""
  for item in "${DOTFILE_SSH_CONFIG_CHECKS[@]}"; do
    local key="${item%% *}"
    local target_value="${item#* }"
    local current_setting
    current_setting=$(grep -E "^[[:space:]]*${key}" "$DOTFILE_SSHD_CONFIG_FILE" 2>/dev/null | head -n 1 || true)

    if [[ -n "$current_setting" ]]; then
      local current_value
      current_value=$(echo "$current_setting" | awk '{print $2}')
      if [[ "$current_value" != "$target_value" ]]; then
        DOTFILE_INSTALL_PLAN_SSH_CONFIG+=("修改配置: ${key} [${current_value}] -> [${target_value}]")
      fi
    else
      local default_value="${DOTFILE_DEFAULT_SSH_VALUES[$key]}"
      if [[ -z "$default_value" ]]; then
        DOTFILE_INSTALL_PLAN_SSH_CONFIG+=("新增配置: ${key} ${target_value} (未知默认值)")
      elif [[ "$default_value" != "$target_value" ]]; then
        DOTFILE_INSTALL_PLAN_SSH_CONFIG+=("新增配置: ${key} ${target_value} (默认为 ${default_value})")
      fi
    fi
  done
}

dotfile_plan_key_changes() {
  local key=""

  if [ ! -f "$DOTFILE_AUTHORIZED_KEYS_FILE" ]; then
    for key in "${DOTFILE_SSH_PUBLIC_KEYS[@]}"; do
      DOTFILE_INSTALL_PLAN_SSH_KEYS+=("新增公钥: ${key:0:50}...")
    done
    return
  fi

  for key in "${DOTFILE_SSH_PUBLIC_KEYS[@]}"; do
    local key_fingerprint
    key_fingerprint=$(echo "$key" | awk '{print $2}')
    if ! grep -qF "$key_fingerprint" "$DOTFILE_AUTHORIZED_KEYS_FILE"; then
      DOTFILE_INSTALL_PLAN_SSH_KEYS+=("新增公钥: ${key:0:50}...")
    fi
  done
}

dotfile_apply_sshd_changes() {
  local use_sudo="$1"
  local config_changed=false
  local sudo_cmd=()
  local item=""

  if [ "$use_sudo" = true ]; then
    sudo_cmd=(sudo)
  fi

  for item in "${DOTFILE_SSH_CONFIG_CHECKS[@]}"; do
    local key="${item%% *}"
    local target_value="${item#* }"
    local current_setting
    current_setting=$(grep -E "^[[:space:]]*${key}" "$DOTFILE_SSHD_CONFIG_FILE" 2>/dev/null | head -n 1 || true)

    if [[ -n "$current_setting" ]]; then
      local current_value
      current_value=$(echo "$current_setting" | awk '{print $2}')
      if [[ "$current_value" != "$target_value" ]]; then
        "${sudo_cmd[@]}" sed -i "s|^[[:space:]]*${key}.*|${key} ${target_value}|g" "$DOTFILE_SSHD_CONFIG_FILE"
        config_changed=true
      fi
    else
      local default_value="${DOTFILE_DEFAULT_SSH_VALUES[$key]}"
      if [[ -z "$default_value" ]] || [[ "$default_value" != "$target_value" ]]; then
        printf '%s\n' "${key} ${target_value}" | "${sudo_cmd[@]}" tee -a "$DOTFILE_SSHD_CONFIG_FILE" > /dev/null
        config_changed=true
      fi
    fi
  done

  if [ "$config_changed" = true ]; then
    echo "[dotfile] 正在重启 SSH 服务..."
    if command -v systemctl >/dev/null 2>&1; then
      "${sudo_cmd[@]}" systemctl restart sshd || "${sudo_cmd[@]}" systemctl restart ssh
    elif command -v service >/dev/null 2>&1; then
      "${sudo_cmd[@]}" service sshd restart || "${sudo_cmd[@]}" service ssh restart
    else
      echo "[dotfile] 警告: 无法自动重启 SSH 服务，请手动重启以应用更改。"
    fi
  fi
}

dotfile_apply_key_changes() {
  local ssh_dir
  ssh_dir=$(dirname "$DOTFILE_AUTHORIZED_KEYS_FILE")

  if [ ! -d "$ssh_dir" ]; then
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
  fi

  if [ ! -f "$DOTFILE_AUTHORIZED_KEYS_FILE" ]; then
    touch "$DOTFILE_AUTHORIZED_KEYS_FILE"
    chmod 600 "$DOTFILE_AUTHORIZED_KEYS_FILE"
  fi

  local key=""
  for key in "${DOTFILE_SSH_PUBLIC_KEYS[@]}"; do
    local key_fingerprint
    key_fingerprint=$(echo "$key" | awk '{print $2}')
    if ! grep -qF "$key_fingerprint" "$DOTFILE_AUTHORIZED_KEYS_FILE"; then
      printf '%s\n' "$key" >> "$DOTFILE_AUTHORIZED_KEYS_FILE"
    fi
  done
}

dotfile_install() {
  echo "[dotfile] 检查 dotfile 仓库..."

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

dotfile_cli_usage() {
  cat <<'EOF'
Usage:
  bashrc_common.sh install
  bashrc_common.sh refresh-region
  bashrc_common.sh detect-region
  bashrc_common.sh help
EOF
}

dotfile_cli() {
  local command="${1:-help}"
  shift || true

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
  local source0="${BASH_SOURCE[0]-}"

  if [ -n "$source0" ] && [ "$source0" != "$0" ] && [ "$source0" != "main" ]; then
    return 0
  fi

  dotfile_cli "$@"
  exit $?
}

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
