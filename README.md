# dotfile

自用 .bashrc，集成了一些有趣/便捷的快捷指令

## How to install

```bash
git clone git@github.com:panjd123/dotfile.git $HOME/.dotfile
~/.dotfile/install_dotfile.sh
```

```bash
curl https://raw.githubusercontent.com/panjd123/dotfile/refs/heads/master/install_dotfile.sh | bash
```

## Useful Software Install Scripts

```bash
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
