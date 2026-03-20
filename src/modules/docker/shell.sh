# Run an interactive shell or one-off command inside a container.
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
