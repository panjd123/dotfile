# Stream Docker images over SSH without writing intermediate tarballs to disk.
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
