# Probe an HTTP proxy from ICMP reachability down to application-layer latency.
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
