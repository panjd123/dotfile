#!/usr/bin/env bash
set -e

REPO_URL="git@github.com:panjd123/dotfile.git"
DOTFILES_DIR="$HOME/.dotfile"
COMMON_FILE="$DOTFILES_DIR/bashrc_common.sh"
INSTALL_METHOD_FILE="$DOTFILES_DIR/.install_method"
DOTFILE_NETWORK_REGION_FILE="$DOTFILES_DIR/.network_region"
AUTHORIZED_KEYS_FILE="$HOME/.ssh/authorized_keys"
SSHD_CONFIG_FILE="/etc/ssh/sshd_config"

# 预定义的公钥列表
SSH_PUBLIC_KEYS=(
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3Mt/bijvkMa15XthVwRu1BHH/WE66IaiYXyQonN6RX 1747366367@qq.com"
  # "ssh-ed25519 AAAA... user@example.com"
)

# SSH 配置检查列表 (格式: "Key Value")
SSH_CONFIG_CHECKS=(
  "PubkeyAuthentication yes"
  # "PasswordAuthentication no" # 如果需要强制密钥登录，可取消此行注释
  # "PermitRootLogin no"        # 如果需要禁止 root 登录，可取消此行注释
)

# SSH 默认值映射表 (用于处理配置文件中未显式定义的情况)
# 依据 man sshd_config 填写常见默认值
declare -A DEFAULT_SSH_VALUES
DEFAULT_SSH_VALUES["PubkeyAuthentication"]="yes"
DEFAULT_SSH_VALUES["PasswordAuthentication"]="yes"
DEFAULT_SSH_VALUES["PermitRootLogin"]="prohibit-password" # 或 "yes" 取决于发行版，这里按常见默认值
# 如果有其他需要监控的配置项，可在此添加

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

echo "[dotfile] 检查 dotfile 仓库..."

# 克隆或更新
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  mkdir -p "$DOTFILES_DIR"
  echo "[dotfile] 使用直接下载方式获取 bashrc_common.sh ..."
  curl -sSfL https://github.com/panjd123/dotfile/raw/master/bashrc_common.sh -o "$COMMON_FILE"
else
  echo "[dotfile] 更新已有仓库..."
  git -C "$DOTFILES_DIR" pull --quiet
fi

dotfile_refresh_network_region

# 确保 bashrc 中加载
if ! grep -q "source $COMMON_FILE" "$HOME/.bashrc"; then
  echo "source $COMMON_FILE" >> "$HOME/.bashrc"
  echo "[dotfile] 已自动将 $COMMON_FILE 加入 ~/.bashrc"
else
  echo "[dotfile] ~/.bashrc 已包含对 $COMMON_FILE 的引用，跳过此步骤。"
fi

# --- 检查与计划阶段 ---

declare -a PLAN_SSH_CONFIG=() # 存储计划修改的配置项
declare -a PLAN_SSH_KEYS=()   # 存储计划添加的公钥

# 函数：检查 SSH 配置变更
plan_sshd_changes() {
  if [ ! -f "$SSHD_CONFIG_FILE" ]; then return; fi

  for item in "${SSH_CONFIG_CHECKS[@]}"; do
    local key=${item%% *}
    local target_value=${item#* }
    
    # 获取当前生效的配置（忽略注释行，只取第一个匹配项）
    local current_setting
    current_setting=$(grep -E "^[[:space:]]*${key}" "$SSHD_CONFIG_FILE" 2>/dev/null | head -n 1 || true)

    if [[ -n "$current_setting" ]]; then
      # 1. 配置项存在：检查值是否一致
      local current_value
      current_value=$(echo "$current_setting" | awk '{print $2}')
      
      if [[ "$current_value" != "$target_value" ]]; then
        PLAN_SSH_CONFIG+=("修改配置: ${key} [${current_value}] -> [${target_value}]")
      fi
    else
      # 2. 配置项不存在：检查默认值
      local default_value="${DEFAULT_SSH_VALUES[$key]}"
      
      # 只有当默认值不存在，或者默认值与目标值不符时，才需要添加配置
      if [[ -z "$default_value" ]]; then
        # 未知默认值，为了安全起见，建议添加显式配置
        PLAN_SSH_CONFIG+=("新增配置: ${key} ${target_value} (未知默认值)")
      elif [[ "$default_value" != "$target_value" ]]; then
        # 默认值不符合预期，需要显式添加
        PLAN_SSH_CONFIG+=("新增配置: ${key} ${target_value} (默认为 ${default_value})")
      fi
      # 如果默认值 == 目标值，则无需操作，符合预期
    fi
  done
}

# 函数：检查 SSH 公钥变更
plan_key_changes() {
  # 如果文件不存在，所有密钥都需要添加
  if [ ! -f "$AUTHORIZED_KEYS_FILE" ]; then
    for key in "${SSH_PUBLIC_KEYS[@]}"; do
      PLAN_SSH_KEYS+=("新增公钥: ${key:0:50}...")
    done
    return
  fi

  # 检查每个密钥是否存在
  for key in "${SSH_PUBLIC_KEYS[@]}"; do
    local key_fingerprint
    key_fingerprint=$(echo "$key" | awk '{print $2}')
    
    if ! grep -qF "$key_fingerprint" "$AUTHORIZED_KEYS_FILE"; then
      PLAN_SSH_KEYS+=("新增公钥: ${key:0:50}...")
    fi
  done
}

# --- 执行阶段 ---

apply_sshd_changes() {
  local use_sudo="$1"
  local config_changed=false
  local sudo_cmd=""
  
  if [ "$use_sudo" = true ]; then
    sudo_cmd="sudo"
  fi

  for item in "${SSH_CONFIG_CHECKS[@]}"; do
    local key=${item%% *}
    local target_value=${item#* }
    
    # 再次检查当前状态（防止在计划期间文件被修改，或者数组顺序问题）
    local current_setting
    current_setting=$(grep -E "^[[:space:]]*${key}" "$SSHD_CONFIG_FILE" 2>/dev/null | head -n 1 || true)

    if [[ -n "$current_setting" ]]; then
      local current_value
      current_value=$(echo "$current_setting" | awk '{print $2}')
      if [[ "$current_value" != "$target_value" ]]; then
        # 替换配置
        $sudo_cmd sed -i "s|^[[:space:]]*${key}.*|${key} ${target_value}|g" "$SSHD_CONFIG_FILE"
        config_changed=true
      fi
    else
      # 配置项不存在，根据计划逻辑，这里只有当默认值不对或未知时才会执行到这里
      # 我们需要追加配置
      
      # 再次确认默认值逻辑（严谨起见，防止并发修改导致状态变化，虽然概率极低）
      local default_value="${DEFAULT_SSH_VALUES[$key]}"
      if [[ -z "$default_value" ]] || [[ "$default_value" != "$target_value" ]]; then
        echo "${key} ${target_value}" | $sudo_cmd tee -a "$SSHD_CONFIG_FILE" > /dev/null
        config_changed=true
      fi
    fi
  done

  if [ "$config_changed" = true ]; then
    echo "[dotfile] 正在重启 SSH 服务..."
    if command -v systemctl &> /dev/null; then
      $sudo_cmd systemctl restart sshd || $sudo_cmd systemctl restart ssh
    elif command -v service &> /dev/null; then
      $sudo_cmd service sshd restart || $sudo_cmd service ssh restart
    else
      echo "[dotfile] 警告: 无法自动重启 SSH 服务，请手动重启以应用更改。"
    fi
  fi
}

apply_key_changes() {
  local ssh_dir
  ssh_dir=$(dirname "$AUTHORIZED_KEYS_FILE")
  
  if [ ! -d "$ssh_dir" ]; then
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
  fi
  
  if [ ! -f "$AUTHORIZED_KEYS_FILE" ]; then
    touch "$AUTHORIZED_KEYS_FILE"
    chmod 600 "$AUTHORIZED_KEYS_FILE"
  fi

  # 实际写入逻辑
  for key in "${SSH_PUBLIC_KEYS[@]}"; do
    local key_fingerprint
    key_fingerprint=$(echo "$key" | awk '{print $2}')
    
    if ! grep -qF "$key_fingerprint" "$AUTHORIZED_KEYS_FILE"; then
      echo "$key" >> "$AUTHORIZED_KEYS_FILE"
    fi
  done
}

# --- 主逻辑 ---

echo "正在扫描系统变更..."
plan_sshd_changes
plan_key_changes

# 如果没有任何变更
if [ ${#PLAN_SSH_CONFIG[@]} -eq 0 ] && [ ${#PLAN_SSH_KEYS[@]} -eq 0 ]; then
  echo "[dotfile] SSH 配置与公钥均已是最新状态，无需操作。"
  echo "[dotfile] 安装完成。重新打开终端或执行 'source $COMMON_FILE' 生效。"
  exit 0
fi

# 展示计划
echo ""
echo "=========================================="
echo "         检测到以下待变更项"
echo "=========================================="

if [ ${#PLAN_SSH_CONFIG[@]} -eq 0 ]; then
  echo -e "\n[SSH 配置] 已是最新状态，无需修改。"
else
  echo -e "\n[SSH 配置变更] (将修改 $SSHD_CONFIG_FILE):"
  printf "  - %s\n" "${PLAN_SSH_CONFIG[@]}"
fi

if [ ${#PLAN_SSH_KEYS[@]} -gt 0 ]; then
  echo -e "\n[SSH 公钥变更] (将写入 $AUTHORIZED_KEYS_FILE):"
  printf "  - %s\n" "${PLAN_SSH_KEYS[@]}"
fi

echo ""
read -p "[dotfile] 是否执行上述变更？: " -n 1 -r < /dev/tty
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "[dotfile] 开始执行变更..."
  
  # 执行 SSH 配置变更
  if [ ${#PLAN_SSH_CONFIG[@]} -gt 0 ]; then
    # 检查是否有写权限
    if [ -w "$SSHD_CONFIG_FILE" ]; then
      echo "[dotfile] 检测到有写权限，直接修改配置..."
      apply_sshd_changes false
    else
      echo "[dotfile] SSH 配置文件需要管理员权限，正在请求 sudo..."
      # 验证 sudo 权限是否可用
      if sudo -v 2>/dev/null; then
        apply_sshd_changes true
      else
        echo "[dotfile] 错误: 无法获取 sudo 权限，跳过 SSH 配置修改。"
      fi
    fi
  fi
  
  # 执行公钥变更
  if [ ${#PLAN_SSH_KEYS[@]} -gt 0 ]; then
    apply_key_changes
  fi
  
  echo "[dotfile] 变更已完成。"
else
  echo "[dotfile] 已取消变更。"
fi

echo "[dotfile] 安装完成。重新打开终端或执行 'source $COMMON_FILE' 生效。"
