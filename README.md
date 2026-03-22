# dotfile

自用 `bashrc` 速查笔记，包含常用 alias、函数和一些安装备忘。

## Install

```bash
# git clone git@github.com:panjd123/dotfile.git $HOME/.dotfile
git clone https://github.com/panjd123/dotfile.git $HOME/.dotfile
bash ~/.dotfile/bashrc_common.sh install
```

也可以直接使用单文件安装：

```bash
curl -fsSL https://raw.githubusercontent.com/panjd123/dotfile/master/bashrc_common.sh | bash -s -- install
```

安装流程会：

- 刷新或下载 `bashrc_common.sh`
- 自动把 `source ~/.dotfile/bashrc_common.sh` 写入 `~/.bashrc`
- 自动探测当前网络区域并写入 `~/.dotfile/.network_region`
- 仅在中国大陆网络下启用相关镜像配置
- 按需提示更新 SSH 配置和 `authorized_keys`

## Update

安装完成后，日常更新直接执行：

```bash
update_dotfile
# 或
update-dotfile
```

## CLI

`bashrc_common.sh` 本身也可以作为命令执行：

```bash
bash ~/.dotfile/bashrc_common.sh help
bash ~/.dotfile/bashrc_common.sh install
bash ~/.dotfile/bashrc_common.sh detect-region
bash ~/.dotfile/bashrc_common.sh refresh-region
```


## Useful Software Install Notes

```bash
# nvidia
sudo apt remove --purge 'nvidia-*' 'libnvidia-*'
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt install -y nvidia-driver-590-open

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
# export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.18.0-1
sudo apt update
sudo apt install -y \
  nvidia-container-toolkit \
  nvidia-container-toolkit-base \
  libnvidia-container-tools \
  libnvidia-container1
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

# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# zellij
cargo install --locked zellij

# nvidia-htop
uv tool install nvidia-htop
```

## Vibe coding setup

```bash
# nvm
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
node -v
npm -v

# npm mirror
# npm config set registry https://registry.npmmirror.com/
# npm config set registry https://registry.npmjs.org/

# claude
curl -fsSL https://claude.ai/install.sh | bash
# irm https://claude.ai/install.ps1 | iex # Windows PowerShell

# codex
npm install -g @openai/codex
# npm install -g @openai/codex-linux-x64@npm:@openai/codex@0.116.0-linux-x64

# opencode
curl -fsSL https://opencode.ai/install | bash
# Install and configure oh-my-opencode by following the instructions here:
# https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/refs/heads/dev/docs/guide/installation.md

# others
apt install -y gh curl wget htop tmux unzip aria2 zstd ca-certificates build-essential rsync

# setup personal config
git -C ~/.config/opencode/plugins init -b main && git -C ~/.config/opencode/plugins remote add origin https://github.com/panjd123/opencode-plugins.git && git -C ~/.config/opencode/plugins pull origin main

git -C ~/.codex/skills init -b main && git -C ~/.codex/skills remote add origin https://github.com/panjd123/codex-skills-monorepo.git && git -C ~/.codex/skills pull origin main

```

## Cheatsheet

### Directory

```bash
..        # cd ..
...       # cd ../..
....      # cd ../../..
mkcd foo  # mkdir -p foo && cd foo
mcd foo   # mkcd 的别名
bd        # 回到上一个目录
```

### Network

```bash
ports          # 查看监听端口
ssh_info       # 查看 SSH 四元组
ssh-info
myip           # 查看出口 IP / 本机 IP / SSH 信息
port 8080      # 查看某个端口对应进程
proxy          # 设置内置 HTTP/HTTPS 代理环境变量
check_proxy 10.77.110.128:20172 https://www.google.com
proxy-test 10.77.110.128:20172
```

### Files

```bash
bak file.txt        # 生成 file.txt.bak 和带时间戳备份
f keyword           # 全盘模糊 find
extract a.tar.gz    # 自动识别压缩格式并解压
untar a.tar
gz dir
ungz a.tar.gz
backup-dir data
restore-dir data.tar.zst
```

### Python / Models

```bash
a              # 激活当前目录下 .venv/bin/activate 或 bin/activate
a path/to/dir
va path/to/dir
hf-download Qwen/Qwen3-8B
hf-mirror-download Qwen/Qwen3-8B
hf-list
hf_bench Qwen/Qwen3-4B-Instruct-2507 4096 256 100
vllm-bench Qwen/Qwen3-4B-Instruct-2507
```

### GPU

```bash
wnv
wnvidia
nvidia-htop
wnvidia-htop
```

### Claude / Codex Profiles

```bash
claude profile_name
cls profile_name
claude-switch profile_name

codex_switch profile_name
cxs profile_name
codex-switch profile_name
```

### Sync

```bash
hf_push user@host Qwen/Qwen3-8B
hf_pull user@host Qwen/Qwen3-8B

data_push user@host data
data_pull user@host data
data_push user@host '~'
data_pull user@host '~/.cache/huggingface'
data_push user@host /mnt/shared

claude-push user@host
claude-pull user@host
codex-push user@host
codex-pull user@host
opencode-push user@host
opencode-pull user@host
vibe-push user@host
vibe-pull user@host
```

`codex-push` / `codex-pull` only copy `auth.json`, `auth.json.*`, `config.toml`, and `config.toml.*` when the receiver does not already have that file. Both always overwrite `auth.json.openai`.
`claude-push` / `claude-pull` only copy `settings.json` and `settings.json.*` when the receiver does not already have that file.
`data-push` / `data-pull` remap the last argument to each machine's own home directory only when it points under the current user's home, such as `data`, `~`, `~/foo`, or an already-expanded local path like `/home/alice/foo`. Other absolute paths like `/mnt/shared` are synced as the same absolute path on both sides. Quote `~` if you want to keep it literal in shell history examples.
When in doubt: relative paths are treated as under `~`, current-user home paths are re-rooted to each side's own `~`, and non-home absolute paths are left untouched.
`opencode-push` / `opencode-pull` fully sync `oh-my-opencode.json` and `gen_oh_my_opencode.py`. For `opencode.json`, they copy the whole file when the receiver has no file yet, otherwise only merge the `provider` field; `~/.config/opencode/plugins` stays out of sync.
`vibe-push` / `vibe-pull` run `claude`, `codex`, and `opencode` sync in order with the same SSH target and options.

### Docker

```bash
dockerbash container_name
dockerbash container_name "ls -la"

docker_push user@host nginx:alpine
docker_pull user@host nginx:alpine
docker-push user@host nginx:alpine --force
docker-pull user@host nginx:alpine --force

ollamad list
vllamad list
```

### Systemd

```bash
sup ssh
sdown ssh
sstatus ssh
susta my-service
suup my-service
sudown my-service
```

### Misc

```bash
path
pstat python
aria2c-fast URL
aria2c-large URL
aptp install package_name
```

## Network-Dependent Behavior

以下环境变量只会在探测结果为中国大陆网络时自动设置：

```bash
UV_DEFAULT_INDEX
PIP_INDEX_URL
PIP_TRUSTED_HOST
HF_ENDPOINT
```

当前探测状态保存在：

```bash
~/.dotfile/.network_region
```

## Ubuntu 24.04 Chromium Lib

```bash
apt install -y libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2t64 libcairo2 fonts-noto-cjk
```
