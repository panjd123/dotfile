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
alias vllm-bench='vllm_bench'

alias ollamad='docker exec -it ollama ollama'
alias vllamad='docker exec -it vllama vllama'

dotfile_apply_region_network_settings
# export HF_HUB_ENABLE_HF_TRANSFER=1

proxy() {
  export http_proxy="http://10.77.110.128:20172"
  export https_proxy=$http_proxy
  export no_proxy="localhost,127.0.0.1,::1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
  export HTTP_PROXY=$http_proxy
  export HTTPS_PROXY=$http_proxy
  export NO_PROXY=$no_proxy
}

alias aptp='sudo apt -o Acquire::http::Proxy="$http_proxy" -o Acquire::https::Proxy="$http_proxy"'

pstat() {
    if [ -z "$1" ]; then
        echo "Usage: pstat <keyword>"
        return 1
    fi

    keyword="$1"

    echo "Processes matching: $keyword"
    echo "-----------------------------------------------------------------------"
    printf "%-8s %-8s %-8s %-10s %s\n" "PID" "CPU%" "MEM%" "RSS(MB)" "CMD"

    ps ax -o pid,pcpu,pmem,rss,cmd | grep -F "$keyword" | grep -v grep | while read pid cpu mem rss cmd; do
        rss_mb=$(awk -v r="$rss" 'BEGIN{printf "%.1f", r/1024}')
        printf "%-8s %-8s %-8s %-10s %s\n" "$pid" "$cpu" "$mem" "$rss_mb" "$cmd"
    done

    cpu_sum=$(ps ax -o pcpu,cmd | grep -F "$keyword" | grep -v grep | awk '{sum+=$1} END{print sum}')
    mem_sum=$(ps ax -o pmem,cmd | grep -F "$keyword" | grep -v grep | awk '{sum+=$1} END{print sum}')
    rss_sum=$(ps ax -o rss,cmd | grep -F "$keyword" | grep -v grep | awk '{sum+=$1} END{printf "%.1f", sum/1024}')

    echo "-----------------------------------------------------------------------"
    echo "Total CPU%: $cpu_sum"
    echo "Total MEM%: $mem_sum"
    echo "Total RSS : $rss_sum MB"
}

backup_dir () {
    local dir="${1%/}"
    local level="${2:-6}"   # 默认压缩等级 6
    local out="${dir##*/}.tar.zst"  # 自动生成压缩包名

    tar --xattrs --acls --selinux --numeric-owner -cf - "$dir" \
        | zstd -T0 -$level --progress -o "$out"
}

restore_dir () {
    local file="$1"
    tar --xattrs --acls --selinux -I "zstd --progress" -xf "$file"
}
alias backup-dir='backup_dir'
alias restore-dir='restore_dir'

# ========== Docker 镜像传输函数 ==========
# 使用方法: docker_push <ssh_target> [ssh_opts...] <image_name> [--force]
#           docker_pull <ssh_target> [ssh_opts...] <image_name> [--force]
# 示例: docker_push user@host hello-world:latest
#       docker_push user@host -p 2222 nginx:alpine --force

_docker_image_sync() {
    local func_name="${FUNCNAME[1]}"
    local force=false
    local args=()

    # 解析参数，提取 --force
    for arg in "$@"; do
        if [[ "$arg" == "--force" ]]; then
            force=true
        else
            args+=("$arg")
        fi
    done

    if [ ${#args[@]} -lt 2 ]; then
        echo "Usage: $func_name <ssh_target> [ssh_opts...] <image_name> [--force]"
        echo "Example: $func_name user@host hello-world:latest"
        echo "         $func_name user@host -p 2222 nginx:alpine --force"
        return 1
    fi

    local image="${args[-1]}"
    local remote_args=("${args[@]:0:${#args[@]}-1}")
    local ssh_target="${remote_args[0]}"

    # 构建 SSH 命令
    local ssh_cmd="ssh"
    local ssh_opts=""
    if [ ${#remote_args[@]} -gt 1 ]; then
        ssh_opts="${remote_args[@]:1}"
        ssh_cmd="ssh $ssh_opts"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🐳 Docker Image Sync: $image"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 1. 检查本地 docker
    if ! command -v docker &>/dev/null; then
        echo "❌ 错误: 本地未安装 docker"
        return 1
    fi

    # 2. 检查本地 zstd
    if ! command -v zstd &>/dev/null; then
        echo "❌ 错误: 本地未安装 zstd"
        return 1
    fi

    # 3. 检查远程 docker
    echo "📡 检查远程环境..."
    if ! $ssh_cmd "$ssh_target" 'command -v docker' &>/dev/null; then
        echo "❌ 错误: 远程主机 $ssh_target 未安装 docker"
        return 1
    fi

    # 4. 检查远程 zstd
    if ! $ssh_cmd "$ssh_target" 'command -v zstd' &>/dev/null; then
        echo "❌ 错误: 远程主机 $ssh_target 未安装 zstd"
        return 1
    fi
    echo "✅ 远程环境检查通过"

    if [[ "$func_name" == "docker_push" ]]; then
        _docker_image_sync_impl "push" "$ssh_target" "$ssh_opts" "$image" "$force"
    elif [[ "$func_name" == "docker_pull" ]]; then
        _docker_image_sync_impl "pull" "$ssh_target" "$ssh_opts" "$image" "$force"
    else
        echo "❌ 未知函数: $func_name"
        return 1
    fi
}

_docker_image_sync_impl() {
    local sync_direction="$1"
    local ssh_target="$2"
    local ssh_opts="$3"
    local image="$4"
    local force="$5"
    local ssh_cmd="ssh"
    [[ -n "$ssh_opts" ]] && ssh_cmd="ssh $ssh_opts"

    if [[ "$sync_direction" == "push" ]]; then
        echo ""
        echo "📤 推送镜像: $image"
        echo "   本地 → $ssh_target"
        echo ""

        # 检查本地镜像是否存在
        if ! docker image inspect "$image" &>/dev/null; then
            echo "❌ 错误: 本地不存在镜像 '$image'"
            echo "   可用镜像:"
            docker images --format "   - {{.Repository}}:{{.Tag}}" | head -10
            return 1
        fi

        # 检查远程镜像是否存在
        if $ssh_cmd "$ssh_target" "docker image inspect '$image'" &>/dev/null; then
            if [[ "$force" != "true" ]]; then
                echo "⚠️  警告: 远程已存在镜像 '$image'"
                echo "   使用 --force 参数覆盖，或先在远程删除镜像"
                return 1
            else
                echo "⚠️  远程已存在镜像，将覆盖 (--force)"
            fi
        fi

        local image_size
        image_size=$(docker image inspect "$image" --format '{{.Size}}' 2>/dev/null)
    elif [[ "$sync_direction" == "pull" ]]; then
        echo ""
        echo "📥 拉取镜像: $image"
        echo "   $ssh_target → 本地"
        echo ""

        # 检查远程镜像是否存在
        if ! $ssh_cmd "$ssh_target" "docker image inspect '$image'" &>/dev/null; then
            echo "❌ 错误: 远程不存在镜像 '$image'"
            echo "   远程可用镜像:"
            $ssh_cmd "$ssh_target" "docker images --format '   - {{.Repository}}:{{.Tag}}'" | head -10
            return 1
        fi

        # 检查本地镜像是否存在
        if docker image inspect "$image" &>/dev/null; then
            if [[ "$force" != "true" ]]; then
                echo "⚠️  警告: 本地已存在镜像 '$image'"
                echo "   使用 --force 参数覆盖，或先删除本地镜像"
                return 1
            else
                echo "⚠️  本地已存在镜像，将覆盖 (--force)"
            fi
        fi

        local image_size
        image_size=$($ssh_cmd "$ssh_target" "docker image inspect '$image' --format '{{.Size}}'" 2>/dev/null)
    else
        echo "❌ 未知方向: $sync_direction"
        return 1
    fi

    local image_size_human
    image_size_human=$(numfmt --to=iec-i --suffix=B "$image_size" 2>/dev/null || echo "unknown")
    echo "📦 镜像大小: $image_size_human"
    echo ""

    # 传输: docker save | zstd | pv | ssh | zstd -d | docker load
    echo "🚀 开始传输..."
    local start_time
    start_time=$(date +%s)

    _docker_image_transfer_data "$sync_direction" "$ssh_target" "$ssh_opts" "$image"
    local ret=$?
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo ""
    if [ $ret -eq 0 ]; then
        if [[ "$sync_direction" == "push" ]]; then
            echo "✅ 推送完成! 耗时: ${duration}s"
            if $ssh_cmd "$ssh_target" "docker image inspect '$image'" &>/dev/null; then
                echo "✅ 远程镜像验证成功"
            fi
        else
            echo "✅ 拉取完成! 耗时: ${duration}s"
            if docker image inspect "$image" &>/dev/null; then
                echo "✅ 本地镜像验证成功"
            fi
        fi
    else
        if [[ "$sync_direction" == "push" ]]; then
            echo "❌ 推送失败"
        else
            echo "❌ 拉取失败"
        fi
        return 1
    fi
}

_docker_image_transfer_data() {
    local sync_direction="$1"
    local ssh_target="$2"
    local ssh_opts="$3"
    local image="$4"

    local ssh_cmd="ssh"
    [[ -n "$ssh_opts" ]] && ssh_cmd="ssh $ssh_opts"

    if command -v pv &>/dev/null; then
        if [[ "$sync_direction" == "push" ]]; then
            docker save "$image" | zstd -T0 -3 | pv -N "传输中" -f | \
                $ssh_cmd "$ssh_target" 'zstd -d -T0 | docker load'
        else
            $ssh_cmd "$ssh_target" "docker save '$image' | zstd -T0 -3" | \
                pv -N "传输中" -f | zstd -d -T0 | docker load
        fi
    elif command -v dd &>/dev/null && dd --help 2>&1 | grep -q "status"; then
        echo "   (提示: 安装 pv 可显示更完整的进度条/ETA)"
        if [[ "$sync_direction" == "push" ]]; then
            docker save "$image" | zstd -T0 -3 | dd status=progress | \
                $ssh_cmd "$ssh_target" 'zstd -d -T0 | docker load'
        else
            $ssh_cmd "$ssh_target" "docker save '$image' | zstd -T0 -3" | \
                dd status=progress | zstd -d -T0 | docker load
        fi
    else
        echo "   (提示: 安装 pv 可显示进度条)"
        if [[ "$sync_direction" == "push" ]]; then
            docker save "$image" | zstd -T0 -3 --progress | \
                $ssh_cmd "$ssh_target" 'zstd -d -T0 | docker load'
        else
            $ssh_cmd "$ssh_target" "docker save '$image' | zstd -T0 -3 --progress" | \
                zstd -d -T0 | docker load
        fi
    fi
}

# 对外接口
docker_push() { _docker_image_sync "$@"; }
docker_pull() { _docker_image_sync "$@"; }
alias docker-push='docker_push'
alias docker-pull='docker_pull'

function check_proxy() {
    # 1. 解析输入
    local INPUT=${1:-"10.77.110.128:20172"}
    local TARGET_URL="${2:-"https://www.google.com"}"
    if [[ -z "$INPUT" ]]; then
        echo "❌ 用法: check_proxy IP:PORT [TARGET_URL]"
        echo "   示例: check_proxy 10.77.110.128:20172 https://www.google.com"
        return 1
    fi
    
    local IP=${INPUT%:*}
    local PORT=${INPUT#*:}
    # 定义颜色
    local GREEN='\033[0;32m'
    local RED='\033[0;31m'
    local YELLOW='\033[1;33m'
    local NC='\033[0m' # No Color

    echo "------------------------------------------------"
    echo -e "🔍 开始测试代理: ${YELLOW}${INPUT}${NC}"
    echo -e "🎯 目标 URL: ${YELLOW}${TARGET_URL}${NC}"
    echo "------------------------------------------------"

    # --- 阶段 1: IP 连通性测试 (Ping) ---
    echo -n "1. [网络层] Ping IP ($IP)... "
    # 检测系统是 Linux 还是 Mac (Darwin) 来调整 ping 参数
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ping -c 2 -W 1000 "$IP" > /dev/null 2>&1
    else
        ping -c 2 -W 1 "$IP" > /dev/null 2>&1
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}通 (Pass)${NC}"
    else
        echo -e "${RED}不通 (Fail)${NC} -> 可能被禁 Ping 或 IP 不存在"
        # 注意：Ping 不通不代表代理不能用，继续往下测
    fi

    # --- 阶段 2: 端口开放性测试 (自动回退) ---
    echo -n "2. [传输层] 端口连通性 ($PORT)... "
    local PORT_OPEN=0
    
    # 策略 A: 使用 netcat (nc)
    if command -v nc >/dev/null 2>&1; then
        if nc -z -w 2 "$IP" "$PORT" >/dev/null 2>&1; then
            PORT_OPEN=1
        fi
    # 策略 B: 使用 bash 原生 /dev/tcp (如果 nc 不存在)
    else
        # timeout 命令防止卡死，如果没有 timeout 命令，风险较高但也能跑
        if timeout 2 bash -c "</dev/tcp/$IP/$PORT" >/dev/null 2>&1; then
             PORT_OPEN=1
        fi
    fi

    if [ $PORT_OPEN -eq 1 ]; then
        echo -e "${GREEN}打开 (Open)${NC}"
    else
        echo -e "${RED}关闭或拦截 (Closed/Blocked)${NC}"
        echo "   ⛔ 端口不通，停止后续代理测试。"
        return 1
    fi

    # --- 阶段 3: 代理功能与延迟测试 (自动回退) ---
    echo -n "3. [应用层] 代理握手与延迟... "
    
    # 策略 A: 优先使用 curl (能提供精确的时间分析)
    if command -v curl >/dev/null 2>&1; then
        echo -e "\n   👉 使用 Curl 引擎测试..."
        # 结果捕获
        RESULT=$(curl -o /dev/null -s -w "%{http_code}:%{time_connect}:%{time_total}" --connect-timeout 5 -x "http://$IP:$PORT" "$TARGET_URL")
        
        local HTTP_CODE=$(echo "$RESULT" | cut -d':' -f1)
        local TIME_CONN=$(echo "$RESULT" | cut -d':' -f2)
        local TIME_TOTAL=$(echo "$RESULT" | cut -d':' -f3)

        if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "301" ] || [ "$HTTP_CODE" == "302" ]; then
             echo -e "   状态: ${GREEN}正常 (HTTP $HTTP_CODE)${NC}"
             echo -e "   连接耗时: ${GREEN}${TIME_CONN}s${NC}"
             echo -e "   总延迟:   ${GREEN}${TIME_TOTAL}s${NC}"
        else
             echo -e "   状态: ${RED}失败 (HTTP $HTTP_CODE)${NC} - 代理可能无法连接外网"
        fi

    # 策略 B: 回退使用 wget (如果没有 curl)
    elif command -v wget >/dev/null 2>&1; then
        echo -e "\n   👉 (Curl缺失) 回退使用 Wget + Time 测试..."
        export http_proxy="http://$IP:$PORT"
        export https_proxy="http://$IP:$PORT"
        
        # 使用 time 指令来计算耗时
        # time 的输出格式在不同 shell 下不同，这里直接显示 time 的输出给用户看
        if wget --spider --timeout=5 --tries=1 "$TARGET_URL" >/dev/null 2>&1; then
             echo -e "   状态: ${GREEN}正常 (连接成功)${NC}"
             echo "   (由于没有curl，无法精确分层耗时，请参考下方 time 输出)"
        else
             echo -e "   状态: ${RED}失败${NC}"
        fi
        
        # 清理环境变量
        unset http_proxy https_proxy

    else
        echo -e "${RED}失败${NC}"
        echo "   ❌ 系统既没有 curl 也没有 wget，无法测试 HTTP 代理。"
    fi
    echo "------------------------------------------------"
}
alias check-proxy='check_proxy'
alias proxy-test='check_proxy'
alias proxy_test='check_proxy'
