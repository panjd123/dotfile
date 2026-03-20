# Shared dotfile paths, URLs, and install-time defaults.
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
