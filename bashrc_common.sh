#!/usr/bin/env bash

# ===========================================
# 仓库: git@github.com:panjd123/dotfile.git
# ===========================================

DOTFILES_DIR="$HOME/.dotfile"

# -------- 手动更新命令 --------
update-dotfile() {
  echo "[dotfile] 正在更新..."
  if [ -d "$DOTFILES_DIR/.git" ]; then
    git -C "$DOTFILES_DIR" pull --rebase --autostash
    echo "[dotfile] 更新完成 ✅"
    if [ -f "$HOME/.bashrc_common" ]; then
      echo "[dotfile] 重新加载配置..."
      source "$HOME/.bashrc_common"
      echo "[dotfile] 已重新加载 ✅"
    fi
  else
    echo "[dotfile] 未检测到 git 仓库，使用直接下载方式获取 bashrc_common.sh ..."
    curl -sSfL https://github.com/panjd123/dotfile/raw/master/bashrc_common.sh -o "$COMMON_FILE"
    echo "[dotfile] 下载完成 ✅"
    echo "[dotfile] 重新加载配置..."
    source "$HOME/.bashrc_common"
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
}

# GPU 监控
alias wnv='watch -n 1 nvidia-smi'
alias nvidia-htop='nvidia-htop.py -l -c -m'

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
  if [ -f "$1" ]; then
    case "$1" in
      *.tar) tar -xvf "$1" ;;
      *.tar.bz2) tar -xjvf "$1" ;;
      *.tar.gz) tar -xzvf "$1" ;;
      *.zip) unzip "$1" ;;
      *.tar.xz) tar -xJvf "$1" ;;
      *.rar) unrar x "$1" ;;
      *) echo "'$1' 无法识别的压缩格式" ;;
    esac
  else
    echo "'$1' 文件不存在"
  fi
}

# python 相关
alias a='. .venv/bin/activate'
alias va='. .venv/bin/activate'
hf_download() {
  HF_ENDPOINT=https://hf-mirror.com python3 -c "from huggingface_hub import snapshot_download; snapshot_download('$1')"
}

# export UV_DEFAULT_INDEX="https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
# export HF_ENDPOINT=https://hf-mirror.com
# export HF_HUB_ENABLE_HF_TRANSFER=1

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
