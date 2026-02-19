#!/usr/bin/env bash
set -e

REPO_URL="git@github.com:panjd123/dotfile.git"
DOTFILES_DIR="$HOME/.dotfile"
COMMON_FILE="$DOTFILES_DIR/bashrc_common.sh"
INSTALL_METHOD_FILE="$DOTFILES_DIR/.install_method"
AUTHORIZED_KEYS_FILE="$HOME/.ssh/authorized_keys"

# 预定义的公钥列表
SSH_PUBLIC_KEYS=(
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3Mt/bijvkMa15XthVwRu1BHH/WE66IaiYXyQonN6RX 1747366367@qq.com"
  # 可以在这里添加更多公钥
  # "ssh-ed25519 AAAA... user@example.com"
)

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

# 确保 bashrc 中加载
if ! grep -q "source $COMMON_FILE" "$HOME/.bashrc"; then
  echo "source $COMMON_FILE" >> "$HOME/.bashrc"
  echo "[dotfile] 已自动将 $COMMON_FILE 加入 ~/.bashrc"
else
  echo "[dotfile] ~/.bashrc 已包含对 $COMMON_FILE 的引用，跳过此步骤。"
fi

# 函数：安装 SSH 公钥
install_ssh_keys() {
  local auth_keys_file="$AUTHORIZED_KEYS_FILE"
  local ssh_dir
  ssh_dir=$(dirname "$auth_keys_file")
  
  # 确保 .ssh 目录存在并设置正确权限
  if [ ! -d "$ssh_dir" ]; then
    echo "[dotfile] 创建 .ssh 目录..."
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
  fi
  
  # 确保 authorized_keys 文件存在
  if [ ! -f "$auth_keys_file" ]; then
    echo "[dotfile] 创建 authorized_keys 文件..."
    touch "$auth_keys_file"
    chmod 600 "$auth_keys_file"
  fi
  
  local added_count=0
  local skipped_count=0
  
  echo "[dotfile] 开始安装 SSH 公钥..."
  
  for key in "${SSH_PUBLIC_KEYS[@]}"; do
    # 提取公钥的指纹部分（去掉末尾的注释）
    local key_fingerprint
    key_fingerprint=$(echo "$key" | awk '{print $2}')
    
    # 检查是否已存在
    if grep -qF "$key_fingerprint" "$auth_keys_file"; then
      echo "[dotfile] 公钥已存在，跳过: ${key:0:50}..."
      ((skipped_count++))
    else
      echo "$key" >> "$auth_keys_file"
      echo "[dotfile] 已添加公钥: ${key:0:50}..."
      ((added_count++))
    fi
  done
  
  echo "[dotfile] SSH 公钥安装完成。新增: $added_count, 跳过: $skipped_count"
}

# 询问是否安装 SSH 公钥
echo ""
read -p "[dotfile] 是否要安装预定义的 SSH 公钥到本机？(y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  install_ssh_keys
else
  echo "[dotfile] 跳过 SSH 公钥安装。"
fi

echo "[dotfile] 安装完成。重新打开终端或执行 'source $COMMON_FILE' 生效。"
