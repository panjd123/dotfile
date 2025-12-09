# dotfile

自用 .bashrc，集成了一些有趣/便捷的快捷指令

## How to install

```bash
# git clone git@github.com:panjd123/dotfile.git $HOME/.dotfile
git clone https://github.com/panjd123/dotfile.git $HOME/.dotfile
~/.dotfile/install_dotfile.sh
```

```bash
curl https://raw.githubusercontent.com/panjd123/dotfile/refs/heads/master/install_dotfile.sh | bash
```

## Useful Software Install Scripts

```bash
# nvidia
sudo apt remove --purge 'nvidia-*' 'libnvidia-*'
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt install -y nvidia-driver-580

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.18.0-1
sudo apt update
sudo apt install -y \
  nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
  nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
  libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
  libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION}
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# docker
sudo groupadd docker
sudo usermod -aG docker panjunda
newgrp docker

# uv
curl -LsSf https://astral.sh/uv/install.sh | sh
# wget -qO- https://astral.sh/uv/install.sh | sh

# vllm
mkdir -p opt/vllm
cd opt/vllm
uv venv --python 3.12 --seed
source .venv/bin/activate
uv pip install vllm --torch-backend=auto

# miniconda
cd /tmp
wget -O miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash miniconda.sh -b -p "$HOME/miniconda3"
eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
conda init bash
conda config --set auto_activate_base false

# nvm
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
node -v
npm -v

# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# zellij
cargo install --locked zellij

# nvidia-htop
uv tool install nvidia-htop

# claude
npm install -g @anthropic-ai/claude-code
# ~/.claude/settings.json
# {"env": {"ANTHROPIC_BASE_URL": "xxx", "ANTHROPIC_API_KEY": "xxx"}}

# codex
npm install -g @openai/codex
```

## Ubuntu24.04 Chromium Lib

```bash
apt install -y libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2t64 libcairo2 fonts-noto-cjk
```
