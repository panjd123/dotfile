#!/usr/bin/env bash
set -e

REPO_URL="git@github.com:panjd123/dotfile.git"
DOTFILES_DIR="$HOME/.dotfile"
COMMON_FILE="$DOTFILES_DIR/bashrc_common"
LINK_TARGET="$HOME/.bashrc_common"

echo "→ 检查 dotfile 仓库..."

# 克隆或更新
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  echo "→ 正在克隆 $REPO_URL ..."
  git clone "$REPO_URL" "$DOTFILES_DIR"
else
  echo "→ 更新已有仓库..."
  git -C "$DOTFILES_DIR" pull --quiet
fi

# 创建软链接
ln -sf "$COMMON_FILE" "$LINK_TARGET"

# 确保 bashrc 中加载
if ! grep -q "source ~/.bashrc_common" "$HOME/.bashrc"; then
  echo "source ~/.bashrc_common" >> "$HOME/.bashrc"
  echo "→ 已自动将 ~/.bashrc_common 加入 ~/.bashrc"
fi

echo "✅ 安装完成。重新打开终端或执行 'source ~/.bashrc_common' 生效。"
