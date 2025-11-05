#!/usr/bin/env bash
set -e

REPO_URL="git@github.com:panjd123/dotfile.git"
DOTFILES_DIR="$HOME/.dotfile"
COMMON_FILE="$DOTFILES_DIR/bashrc_common.sh"
INSTALL_METHOD_FILE="$DOTFILES_DIR/.install_method"

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

source "$COMMON_FILE"
echo "[dotfile] 安装完成，并加载配置 ✅"
