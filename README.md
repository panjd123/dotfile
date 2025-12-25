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
# {"env": {"ANTHROPIC_BASE_URL": "xxx", "ANTHROPIC_AUTH_TOKEN": "xxx"}}

# codex
npm install -g @openai/codex
```

## Ubuntu24.04 Chromium Lib

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
     **大于 100 的、`num_payloads` 的最小倍数**
   * 正式测试阶段通过 **graph replay** 重复执行
   * **程序应接受一个输入参数：总调用次数（--iters）**，并根据该值决定 replay 次数，你可以稍微超过 --iters，比如取最小的倍数
   * 计时范围仅包含 **graph replay**

5. **统计方式：**

   * 记录 **总耗时** 与 **总调用次数**
   * 输出：**平均单次 kernel 时间 = 总耗时 ÷ 总调用次数**

6. 约束：

   * graph 捕获与 replay 阶段 **数据指针与内存布局保持不变**
   * replay 期间不得重新分配或替换 payload
   * 不允许仅使用单一小规模输入
```
