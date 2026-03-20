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

claude-push user@host
claude-pull user@host
codex-push user@host
codex-pull user@host
```

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

# nvm
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
node -v
npm -v

# npm mirror
npm config set registry https://registry.npmmirror.com/
npm config set registry https://registry.npmjs.org/

# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# zellij
cargo install --locked zellij

# nvidia-htop
uv tool install nvidia-htop

# claude
curl -fsSL https://claude.ai/install.sh | bash
irm https://claude.ai/install.ps1 | iex
# npm install -g @anthropic-ai/claude-code
# ~/.claude/settings.json
# {"env": {"ANTHROPIC_BASE_URL": "xxx", "ANTHROPIC_AUTH_TOKEN": "xxx"}}

# codex
npm install -g @openai/codex
npm install -g @openai/codex-linux-x64@npm:@openai/codex@0.111.0-linux-x64
```

## Ubuntu 24.04 Chromium Lib

```bash
apt install -y libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2t64 libcairo2 fonts-noto-cjk
```

## Kernel Timing Prompt

```md
CUDA kernel 计时时的要求如下：

1. 使用 **CUDA C++** 或 **Python** 编写，并输出稳定、可复现的平均 kernel 执行时间。

2. 程序需要生成 **多个 payload（输入输出数组 / 张量）**，并保证：

   * **所有 payload 的总数据量 > GPU 的 L2 cache 容量 × 2**
   * 通过轮询访问不同 payload，减少 cache 命中影响
   * `num_payloads` 可自动确定或可配置

3. 程序应当自动：

   * 查询当前设备的 **L2 cache 大小**
   * 根据该值确定 payload 总规模（≥ L2 × 2）
   * 将数据拆分为若干 payload

4. **执行与计时规则：**

   * 仅在最开始执行 **一轮 warmup（不计时）**
   * 使用 **CUDA Graph 捕获 kernel 执行**
   * 在 graph 中，一轮执行的 kernel 次数应为
     8 * num_payloads
   * 正式测试阶段通过 **graph replay** 重复执行，重复执行次数为 replay 8 次
   * 计时范围仅包含 **graph replay**

5. **统计方式：**

   * 记录 **总耗时** 与 **总调用次数**
   * 输出：**平均单次 kernel 时间 = 总耗时 ÷ 总调用次数**

6. 约束：

   * graph 捕获与 replay 阶段 **数据指针与内存布局保持不变**
   * replay 期间不得重新分配或替换 payload
   * 不允许仅使用单一小规模输入
```
