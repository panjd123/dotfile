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
alias ssh-info='ssh_info'

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
    local base="."
    if [ $# -gt 0 ]; then
        base="$1"
    fi

    # 去掉末尾的斜杠
    base="${base%/}"

    local cand1="$base/.venv/bin/activate"
    local cand2="$base/bin/activate"

    if [ -f "$cand1" ]; then
        source "$cand1"
        return
    fi

    if [ -f "$cand2" ]; then
        source "$cand2"
        return
    fi

    echo "❌ 未找到虚拟环境：$cand1 或 $cand2"
    return 1
}
alias va=a

alias da=deactivate

hf_mirror_download() {
  HF_ENDPOINT=https://hf-mirror.com python3 -c "from huggingface_hub import snapshot_download; snapshot_download('$1')"
}
alias hf-mirror-download='hf_mirror_download'
hf_download() {
 python3 -c "from huggingface_hub import snapshot_download; snapshot_download('$1')"
}
alias hf-download='hf_download'
