#!/usr/bin/env bash

# ===========================================
# 仓库: git@github.com:panjd123/dotfile.git
# ===========================================

DOTFILES_DIR="$HOME/.dotfile"
COMMON_FILE="$DOTFILES_DIR/bashrc_common.sh"

# -------- 手动更新命令 --------
update-dotfile() {
  echo "[dotfile] 正在更新..."
  if [ -d "$DOTFILES_DIR/.git" ]; then
    git -C "$DOTFILES_DIR" pull --rebase --autostash
    echo "[dotfile] 更新完成 ✅"
    if [ -f "$COMMON_FILE" ]; then
      echo "[dotfile] 重新加载配置..."
      source "$COMMON_FILE"
      echo "[dotfile] 已重新加载 ✅"
    fi
  else
    echo "[dotfile] 未检测到 git 仓库，使用直接下载方式获取 bashrc_common.sh ..."
    curl -sSfL https://github.com/panjd123/dotfile/raw/master/bashrc_common.sh -o "$COMMON_FILE"
    echo "[dotfile] 下载完成 ✅"
    echo "[dotfile] 重新加载配置..."
    source "$COMMON_FILE"
    echo "[dotfile] 已重新加载 ✅"
  fi
}
alias update_dotfile='update-dotfile'

# 目录相关
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
mkcd() { mkdir -p "$1" && cd "$1"; }
alias mcd='mkcd'
alias bd='cd "$OLDPWD"'

# 网络相关
alias ports='netstat -tulnp | grep LISTEN'

ssh_info() {
  if [ -z "$SSH_CONNECTION" ]; then
    echo "Not an SSH session"
    return 1
  fi

  set -- $SSH_CONNECTION
  client_ip=$1
  client_port=$2
  server_ip=$3
  server_port=$4

  echo "Client IP:      $client_ip"
  echo "Client Port:    $client_port"
  echo "Server IP:      $server_ip"
  echo "Server Port:    $server_port"
}

port() {
  # 1. 检查参数
  if [ -z "$1" ]; then
    echo "错误：请输入一个端口号作为参数。"
    echo "用法: $0 <端口号>"
    return 1
  fi

  PORT=$1

  # 2. 使用 lsof -t 精准地只获取 PID
  # -t: Terse output, 只输出 PID，便于脚本处理
  # -sTCP:LISTEN: 只查找状态为 LISTEN 的 TCP 连接，比 grep 更可靠
  PIDS=$(sudo lsof -t -i :${PORT} -sTCP:LISTEN)

  # 3. 检查是否找到了进程
  if [ -z "$PIDS" ]; then
    echo "没有找到在端口 ${PORT} 上监听的进程。"
    return 0
  fi

  echo "在端口 ${PORT} 上找到以下进程的详细信息:"
  echo "====================================================================================================="

  # 4. 使用 ps 命令为每一个找到的 PID 输出详细信息
  #    -p 指定 PID
  #    -o 指定输出格式，这是实现 "htop-like" 的关键
  #
  #    格式说明:
  #    pid      - 进程 ID
  #    user     - 运行该进程的用户名
  #    %cpu     - CPU 使用率
  #    %mem     - 内存使用率
  #    etime    - 进程启动后经过的时间
  #    command  - 完整的命令，包含所有参数 (这是最重要的部分)
  #
  ps ww -p ${PIDS} -o pid,user,%cpu,%mem,etime,command

  echo "====================================================================================================="
}
getip() {
  echo "实际出口IP及网卡信息:"
  ip route get 8.8.8.8 2>/dev/null | 
  awk '{for(i=1;i<=NF;i++){if($i=="dev"){d=$(i+1)}; if($i=="src"){s=$(i+1)}}} END{print d, s}'
  echo "--------------------------------"
  echo "本机所有IP地址:"
  hostname -I
  echo "--------------------------------"
  echo "SSH连接信息（如果适用）:"
  ssh_info || echo "非SSH连接"
}
alias myip='getip'

# GPU 监控
alias wnv='watch -n 1 nvidia-smi'
alias wnvidia='watch -n 1 nvidia-smi'
alias nvidia-htop='nvidia-htop.py -l -c -m'
alias wnvidia-htop='watch -n 1 nvidia-htop.py -l -c -m'

# 文件相关
bak() {
  if [ -z "$1" ]; then
    echo "用法: bak <文件名>"
    return 1
  fi
  cp "$1" "$1.bak_$(date +%Y%m%d_%H%M%S)"
  cp "$1" "$1.bak"
  echo "已创建备份: $1.bak_$(date +%Y%m%d_%H%M%S) 和 $1.bak"
}
f() { find / -iname "*$1*" 2>/dev/null; }
alias untar='tar -xvf'
alias gz='tar -czvf'
alias ungz='tar -xzvf'
extract() {
  if [ -z "$1" ]; then
    echo "用法: extract <压缩文件>"
    return 1
  fi

  if [ ! -f "$1" ]; then
    echo "'$1' 文件不存在"
    return 1
  fi

  case "$1" in
    *.tar) 
      tar -xvf "$1" ;;
    *.tar.gz|*.tgz) 
      tar -xzvf "$1" ;;
    *.tar.bz2|*.tbz|*.tbz2) 
      tar -xjvf "$1" ;;
    *.tar.xz|*.txz) 
      tar -xJvf "$1" ;;
    *.zip) 
      if command -v unzip >/dev/null 2>&1; then
        unzip "$1"
      else
        echo "unzip 未安装"
        return 1
      fi ;;
    *.rar) 
      if command -v unrar >/dev/null 2>&1; then
        unrar x "$1"
      else
        echo "unrar 未安装"
        return 1
      fi ;;
    *.7z) 
      if command -v 7z >/dev/null 2>&1; then
        7z x "$1"
      else
        echo "7z 未安装"
        return 1
      fi ;;
    *.gz) 
      gunzip "$1" ;;
    *.bz2) 
      bunzip2 "$1" ;;
    *.xz) 
      unxz "$1" ;;
    *) 
      echo "'$1' 无法识别的压缩格式" 
      return 1 ;;
  esac
}


a() {
    local target=".venv/bin/activate"

    # 如果传入参数，则使用参数路径
    if [ $# -gt 0 ]; then
        target="$1/.venv/bin/activate"
    fi

    # 检查文件是否存在
    if [ -f "$target" ]; then
        # 使用 source 或 . 激活虚拟环境
        source "$target"
    else
        echo "❌ 未找到虚拟环境：$target"
        return 1
    fi
}
alias va=a

alias da=deactivate

hf_download() {
  HF_ENDPOINT=https://hf-mirror.com python3 -c "from huggingface_hub import snapshot_download; snapshot_download('$1')"
}

alias claude='claude --dangerously-skip-permissions'
alias codex='codex --dangerously-bypass-approvals-and-sandbox'
claude-switch() {
    # if exist ~/.claude/settings.json.$1, copy to ~/.claude/settings.json
    if [ -f ~/.claude/settings.json.$1 ]; then
        cp ~/.claude/settings.json.$1 ~/.claude/settings.json
        echo "Switched to Claude profile: $1"
    else
        echo "Profile $1 does not exist."
    fi
    cat ~/.claude/settings.json
}
alias cls='claude-switch'

# systemctl 相关
alias sup='systemctl start'
alias sdown='systemctl stop'
alias sstatus='systemctl status'
alias ssta='systemctl status'

alias su='systemctl --user'
alias suup='systemctl --user start'
alias sudown='systemctl --user stop'
alias sustatus='systemctl --user status'
alias susta='systemctl --user status'

_systemctl_alias_completion() {
    # COMP_WORDS 是包含当前命令行所有单词的数组
    # COMP_CWORD 是光标所在单词的索引
    local alias_cmd="${COMP_WORDS[0]}"
    local words_after_alias=("${COMP_WORDS[@]:1}")
    
    # 使用 case 语句根据不同的别名，构建出实际的命令
    case "$alias_cmd" in
        sup)
            COMP_WORDS=(systemctl start "${words_after_alias[@]}")
            COMP_CWORD=$((COMP_CWORD + 1))
            ;;
        sdown)
            COMP_WORDS=(systemctl stop "${words_after_alias[@]}")
            COMP_CWORD=$((COMP_CWORD + 1))
            ;;
        sstatus|ssta) # 使用 | 将多个别名映射到同一个命令
            COMP_WORDS=(systemctl status "${words_after_alias[@]}")
            COMP_CWORD=$((COMP_CWORD + 1))
            ;;
        su)
            COMP_WORDS=(systemctl --user "${words_after_alias[@]}")
            COMP_CWORD=$((COMP_CWORD + 1))
            ;;
        suup)
            COMP_WORDS=(systemctl --user start "${words_after_alias[@]}")
            # 这里增加了2个单词 (--user, start)，所以索引要加2
            COMP_CWORD=$((COMP_CWORD + 2))
            ;;
        sudown)
            COMP_WORDS=(systemctl --user stop "${words_after_alias[@]}")
            COMP_CWORD=$((COMP_CWORD + 2))
            ;;
        sustatus|susta)
            COMP_WORDS=(systemctl --user status "${words_after_alias[@]}")
            COMP_CWORD=$((COMP_CWORD + 2))
            ;;
    esac

    # 调用 systemctl 原本的补全函数来处理我们伪造的命令行
    _systemctl
}
complete -F _systemctl_alias_completion \
    sup sdown sstatus ssta \
    su suup sudown sustatus susta

alias path='echo -e ${PATH//:/\\n}'

# docker 相关
dockerbash() {
  # 检查是否提供了至少一个参数（容器名）
  if [ -z "$1" ]; then
    echo "用法: dockerbash <容器ID或名称> [要在容器中执行的命令...]"
    return 1
  fi

  # 将第一个参数（容器名）保存到一个变量中，以便后续使用
  local container_id="$1"

  # 检查参数总数是否大于1。
  # 如果参数总数大于1，意味着除了容器名，还提供了要执行的命令。
  if [ "$#" -gt 1 ]; then
    # “shift”命令会移除第一个参数（$1），
    # 剩下的所有参数（$@）就正好是我们要执行的命令。
    shift
    docker exec "$container_id" /bin/bash -c "$@"
  else
    # 如果参数总数只有1，就执行默认行为：启动一个交互式的bash shell。
    docker exec -it "$container_id" /bin/bash
  fi
}

alias aria2c-fast='aria2c --max-connection-per-server=16 --split=16 --min-split-size=1M --continue=true'
alias aria2c-large='aria2c --max-connection-per-server=16 --split=16 --min-split-size=20M --continue=true'

_hf_sync() {
    if [ $# -lt 2 ]; then
        echo "Usage: ${FUNCNAME[1]} <ssh_target> [ssh_opts...] <model_name>"
        echo "Example: ${FUNCNAME[1]} user@host -p 2022 Qwen/Qwen3-8B"
        return 1
    fi

    local model="${@: -1}"
    local remote_args=("${@:1:$#-1}")

    local local_base="$HOME/.cache/huggingface/hub"
    local model_dir="models--${model//\//--}"
    local local_dir="$local_base/$model_dir/"
    local remote_dir="~/.cache/huggingface/hub/$model_dir/"

    local ssh_cmd="ssh"
    if [ ${#remote_args[@]} -gt 1 ]; then
        ssh_cmd+=" ${remote_args[@]:1}"
    fi

    echo "🔄 Syncing HuggingFace model cache: $model"

    if [[ "${FUNCNAME[1]}" == "hf_push" ]]; then
        echo "Pushing local -> remote"
        echo "From: $local_dir"
        echo "To:   ${remote_args[0]}:$remote_dir"
        rsync -avzP --mkpath --links -e "$ssh_cmd" "$local_dir" "${remote_args[0]}:$remote_dir"
    elif [[ "${FUNCNAME[1]}" == "hf_pull" ]]; then
        echo "Pulling remote -> local"
        echo "From: ${remote_args[0]}:$remote_dir"
        echo "To:   $local_dir"
        rsync -avzP --mkpath --links -e "$ssh_cmd" "${remote_args[0]}:$remote_dir" "$local_dir"
    else
        echo "❌ Unknown function name"
        return 1
    fi

    if [ $? -eq 0 ]; then
        echo "✅ Sync complete: $model"
    else
        echo "❌ Sync failed: $model"
    fi
}

hf_push() { _hf_sync "$@"; }
hf_pull() { _hf_sync "$@"; }

_data_sync() {
    if [ $# -lt 2 ]; then
        echo "Usage: ${FUNCNAME[1]} <ssh_target> [ssh_opts...] <dir_name>"
        echo "Example: ${FUNCNAME[1]} user@host -p 2022 data"
        return 1
    fi

    local dir="${@: -1}"
    local remote_args=("${@:1:$#-1}")

    local local_dir="$HOME/$dir"
    local remote_dir="~/$dir"

    local ssh_cmd="ssh"
    if [ ${#remote_args[@]} -gt 1 ]; then
        ssh_cmd+=" ${remote_args[@]:1}"
    fi

    echo "🔄 Syncing directory: $dir"

    if [[ "${FUNCNAME[1]}" == "data_push" ]]; then
        echo "Pushing local -> remote"
        echo "From: $local_dir/"
        echo "To:   ${remote_args[0]}:$remote_dir/"
        rsync -avzP --mkpath --links -e "$ssh_cmd" "$local_dir/" "${remote_args[0]}:$remote_dir/"
    elif [[ "${FUNCNAME[1]}" == "data_pull" ]]; then
        echo "Pulling remote -> local"
        echo "From: ${remote_args[0]}:$remote_dir/"
        echo "To:   $local_dir/"
        rsync -avzP --mkpath --links -e "$ssh_cmd" "${remote_args[0]}:$remote_dir/" "$local_dir/"
    else
        echo "❌ Unknown function name"
        return 1
    fi

    if [ $? -eq 0 ]; then
        echo "✅ Sync complete"
    else
        echo "❌ Sync failed"
    fi
}

# 对外接口
data_push() { _data_sync "$@"; }
data_pull() { _data_sync "$@"; }

hf_list() {
    local CACHE_DIR="${HF_HOME:-$HOME/.cache}/huggingface/hub"

    if [ ! -d "$CACHE_DIR" ]; then
        echo "Cache directory does not exist: $CACHE_DIR"
        return 1
    fi

    declare -A grouped_models

    # 遍历所有模型目录
    for dir in "$CACHE_DIR"/models--*/; do
        local model_dir
        model_dir=$(basename "$dir")
        # 去掉 models-- 前缀
        local model_name="${model_dir//models--/}"
        # 将 -- 替换为 /，得到 user/model-name
        model_name="${model_name//--//}"
        # 取前缀作为分组 key
        local prefix="${model_name%%/*}"
        grouped_models["$prefix"]+="$model_name"$'\n'
    done

    echo "Models in Hugging Face cache (grouped by prefix):"
    echo "-------------------------------------------------"

    # 输出分组，前缀排序
    for prefix in $(printf "%s\n" "${!grouped_models[@]}" | sort); do
        echo "$prefix:"
        while IFS= read -r model; do
            [ -z "$model" ] && continue
            echo "  - $model"
        done <<< "$(printf "%s" "${grouped_models[$prefix]}" | sort)"
    done
}

vllm_bench() {
  model=${1:-"Qwen/Qwen3-4B-Instruct-2507"}
  input_len=${2:-4096}
  output_len=${3:-256}
  num_prompts=${4:-100}

  # default max_model_len = input_len + output_len
  if [ -n "$5" ]; then
    max_model_len=$5
  else
    max_model_len=$((input_len + output_len))
  fi

  vllm bench throughput \
    --gpu-memory-utilization 0.9 \
    --model "$model" \
    --dataset-name random \
    --num-prompts "$num_prompts" \
    --input-len "$input_len" \
    --output-len "$output_len" \
    --max-model-len "$max_model_len" \
    --async-engine
}

alias hf_bench='vllm_bench'

alias ollamad='docker exec -it ollama ollama'

export UV_DEFAULT_INDEX="https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
export PIP_INDEX_URL="https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
export PIP_TRUSTED_HOST="mirrors.tuna.tsinghua.edu.cn"
export HF_ENDPOINT=https://hf-mirror.com
# export HF_HUB_ENABLE_HF_TRANSFER=1
