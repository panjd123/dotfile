#!/usr/bin/env bash

# ===========================================
# 仓库: git@github.com:panjd123/dotfile.git
# ===========================================

DOTFILES_DIR="$HOME/.dotfile"
COMMON_FILE="$DOTFILES_DIR/bashrc_common.sh"

# -------- 手动更新命令 --------
update_dotfile() {
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
alias update_dotfile='update_dotfile'
alias update-dotfile='update_dotfile'

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

alias claude='CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000 IS_SANDBOX=1 claude --dangerously-skip-permissions'
alias codex='codex --dangerously-bypass-approvals-and-sandbox'
claude_switch() {
    # if exist ~/.claude/settings.json.$1, copy to ~/.claude/settings.json
    if [ -f ~/.claude/settings.json.$1 ]; then
        cp ~/.claude/settings.json.$1 ~/.claude/settings.json
        echo "Switched to Claude profile: $1"
    else
        echo "Profile $1 does not exist."
        ls -1 ~/.claude/settings.json.*
    fi
    cat ~/.claude/settings.json
}
alias cls='claude_switch'
alias claude-switch='claude_switch'
codex_switch() {
    # if exist ~/.codex/auth.json.$1, copy auth.json.
    # if exist ~/.codex/config.toml.$1, merge protected fields into ~/.codex/config.toml as well.
    local profile="${1}"
    local src_config="${HOME}/.codex/config.toml.${profile}"
    local src_auth="${HOME}/.codex/auth.json.${profile}"
    local dst_config="${HOME}/.codex/config.toml"
    local dst_auth="${HOME}/.codex/auth.json"

    local has_src_config="0"
    if [ -f "$src_config" ]; then
        has_src_config="1"
    fi

    if [ -f "$src_auth" ]; then
        cp "$src_auth" "$dst_auth"

        if [ "$has_src_config" = "1" ]; then
            if [ -f "$dst_config" ]; then
                local backup_root="${HOME}/.codex/backups"
                local backup_day_dir="${backup_root}/$(date +%F)"
                local backup_file="${backup_day_dir}/config.toml.$(date +%F_%H%M%S)"
                local merged_file
                local tmp_projects
                local tmp_model
                local tmp_model_reasoning
                merged_file="$(mktemp "${dst_config}.merged.XXXXXX")"
                tmp_projects="$(mktemp "${dst_config}.projects.XXXXXX")"
                tmp_model="$(mktemp "${dst_config}.model.XXXXXX")"
                tmp_model_reasoning="$(mktemp "${dst_config}.reasoning.XXXXXX")"

                mkdir -p "$backup_day_dir"
                cp "$dst_config" "$backup_file"

                awk '
                    /^\[projects(\..*)?\][[:space:]]*$/ { in_projects=1; print; next }
                    in_projects && /^\[[^]]+\][[:space:]]*$/ { in_projects=0 }
                    in_projects { print }
                ' "$dst_config" > "$tmp_projects"

                awk 'BEGIN { found=0 }
                    /^[[:space:]]*model[[:space:]]*=/ && found==0 {
                        print
                        found=1
                        exit
                    }
                ' "$dst_config" > "$tmp_model"

                awk 'BEGIN { found=0 }
                    /^[[:space:]]*model_reasoning_effort[[:space:]]*=/ && found==0 {
                        print
                        found=1
                        exit
                    }
                ' "$dst_config" > "$tmp_model_reasoning"
            python3 - "$src_config" "$merged_file" "$tmp_projects" "$tmp_model" "$tmp_model_reasoning" <<'PY'
import sys
from pathlib import Path

src_config_path = Path(sys.argv[1])
out_path = Path(sys.argv[2])
projects_path = Path(sys.argv[3])
model_path = Path(sys.argv[4])
reasoning_path = Path(sys.argv[5])

source_text = src_config_path.read_text()

projects_block = projects_path.read_text().rstrip("\n")
model_line = model_path.read_text().rstrip("\n")
reasoning_line = reasoning_path.read_text().rstrip("\n")

if projects_block:
    import re
    source_text = re.sub(
        r'(?ms)^\[projects(?:\.[^]]+)?\][ \t]*\n.*?(?=^\[[^]]+\]|\Z)',
        '',
        source_text
    )
    source_text = f"{source_text.rstrip(chr(10))}\n\n{projects_block}\n"

if model_line:
    import re
    source_text, count = re.subn(r'(?m)^\s*model\s*=.*$', model_line, source_text, count=1)
    if count == 0:
        if not source_text.endswith('\n'):
            source_text += '\n'
        source_text += f"{model_line}\n"

if reasoning_line:
    import re
    source_text, count = re.subn(
        r'(?m)^\s*model_reasoning_effort\s*=.*$',
        reasoning_line,
        source_text,
        count=1
    )
    if count == 0:
        if not source_text.endswith('\n'):
            source_text += '\n'
        source_text += f"{reasoning_line}\n"

out_path.write_text(source_text)
PY

                mv "$merged_file" "$dst_config"
                rm -f "$tmp_projects" "$tmp_model" "$tmp_model_reasoning"
            fi
            if [ -f "$dst_config" ]; then
                echo "Switched to Codex profile: $1"
            else
                cp "$src_config" "$dst_config"
                echo "No local ~/.codex/config.toml was found, copied from profile: $1"
            fi
        else
            echo "⚠️  No config.toml for profile $1, only auth.json has been switched."
            if [ -f "$dst_config" ]; then
                echo "Kept current ~/.codex/config.toml"
            else
                echo "No ~/.codex/config.toml exists locally yet."
            fi
        fi
    else
        echo "Profile $1 does not exist."
        ls -1 ~/.codex/config.toml.*
        ls -1 ~/.codex/auth.json.*
    fi

    if [ -f "$dst_config" ]; then
        cat "$dst_config"
    else
        echo "~/.codex/config.toml does not exist."
    fi
}
alias cxs='codex_switch'
alias codex-switch='codex_switch'

# systemctl 相关
alias sup='systemctl start'
alias sdown='systemctl stop'
alias sstatus='systemctl status'
alias ssta='systemctl status'

# alias su='systemctl --user'
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

_remote_sync_scp_fallback() {
    local mode="$1"
    local local_dir="$2"
    local remote_dir="$3"
    local remote_target="$4"
    local patterns_csv="$5"
    shift 5
    local remote_opts=("$@")

    local local_dir_clean="${local_dir%/}"
    local remote_dir_clean="${remote_dir%/}"

    local -a scp_cmd=(scp -r)
    if [ ${#remote_opts[@]} -gt 0 ]; then
        scp_cmd+=("${remote_opts[@]}")
    fi

    local -a ssh_cmd=(ssh)
    if [ ${#remote_opts[@]} -gt 0 ]; then
        ssh_cmd+=("${remote_opts[@]}")
    fi

    case "$mode" in
        push)
            "${ssh_cmd[@]}" "$remote_target" "mkdir -p $remote_dir_clean"
            if [ $? -ne 0 ]; then
                return 1
            fi
            if [ -z "$patterns_csv" ]; then
                "${scp_cmd[@]}" "$local_dir_clean/." "${remote_target}:${remote_dir_clean}/"
                return $?
            fi

            local IFS='|'
            local -a patterns=()
            local pattern
            local local_file
            local has_source=0
            read -r -a patterns <<< "$patterns_csv"
            IFS=$' \t\n'

            for pattern in "${patterns[@]}"; do
                local matched=0
                local -a matched_files=()
                while IFS= read -r -d '' local_file; do
                    matched_files+=("$local_file")
                done < <(find "$local_dir_clean" -maxdepth 1 -type f -name "$pattern" -print0)

                if [ ${#matched_files[@]} -eq 0 ]; then
                    echo "⚠️  跳过不存在的文件: $local_dir_clean/$pattern"
                    continue
                fi

                for local_file in "${matched_files[@]}"; do
                    "${scp_cmd[@]}" "$local_file" "${remote_target}:${remote_dir_clean}/"
                    if [ $? -ne 0 ]; then
                        return 1
                    fi
                    has_source=1
                    matched=1
                done
                if [ "$matched" -eq 0 ]; then
                    echo "⚠️  未匹配到文件: $local_dir_clean/$pattern"
                fi
            done
            if [ "$has_source" -eq 0 ]; then
                echo "⚠️  未发现可同步文件，已按无变更处理"
            fi
            ;;
        pull)
            mkdir -p "$local_dir_clean"
            if [ -z "$patterns_csv" ]; then
                "${scp_cmd[@]}" "${remote_target}:${remote_dir_clean}/." "$local_dir_clean/"
                return $?
            fi

            local IFS='|'
            local -a patterns=()
            local pattern
            local remote_files
            local found_any=0
            read -r -a patterns <<< "$patterns_csv"
            IFS=$' \t\n'

            for pattern in "${patterns[@]}"; do
                remote_files=$("${ssh_cmd[@]}" "$remote_target" \
                    "for f in ${remote_dir_clean}/${pattern}; do
                        [ -e \"$f\" ] && printf '%s\n' \"$f\";
                    done")
                if [ -z "$remote_files" ]; then
                    echo "⚠️  未找到远程文件: ${remote_dir_clean}/${pattern}"
                    continue
                fi

                while IFS= read -r remote_file; do
                    [ -z "$remote_file" ] && continue
                    "${scp_cmd[@]}" "${remote_target}:${remote_file}" "$local_dir_clean/"
                    if [ $? -ne 0 ]; then
                        return 1
                    fi
                    found_any=1
                done <<< "$remote_files"
            done
            if [ "$found_any" -eq 0 ]; then
                echo "⚠️  未找到可同步文件，已按无变更处理"
            fi
            ;;
        *)
            echo "Unknown sync mode: $mode"
            return 1
            ;;
    esac
    return 0
}

_remote_sync() {
    local mode="$1"
    local local_dir="$2"
    local remote_dir="$3"
    local patterns_csv="$4"
    local sync_label="$5"
    local extra_opts="$6"
    shift 6

    if [ "$mode" != "push" ] && [ "$mode" != "pull" ]; then
        echo "Unknown sync mode: $mode"
        return 1
    fi

    if [ $# -lt 1 ]; then
        echo "Usage: ${sync_label}_${mode} <ssh_target> [ssh_opts...]"
        echo "Example: ${sync_label}_${mode} user@host -p 2022"
        return 1
    fi

    local -a remote_args=("$@")
    local remote_target="${remote_args[0]}"

    local -a remote_opts=()
    if [ ${#remote_args[@]} -gt 1 ]; then
        remote_opts=("${remote_args[@]:1}")
    fi

    local ssh_cmd="ssh"
    if [ ${#remote_opts[@]} -gt 0 ]; then
        ssh_cmd+=" ${remote_opts[*]}"
    fi

    local rsync_opts=(--mkpath)
    if [ -n "$extra_opts" ]; then
        rsync_opts+=("$extra_opts")
    fi

    if [ "$mode" = "push" ]; then
        echo "Pushing local -> remote"
        echo "From: $local_dir"
        echo "To:   ${remote_target}:$remote_dir"
    else
        echo "Pulling remote -> local"
        echo "From: ${remote_target}:$remote_dir"
        echo "To:   $local_dir"
    fi

    local rsync_exit=1
    if [ -z "$patterns_csv" ]; then
        rsync -avzP "${rsync_opts[@]}" -e "$ssh_cmd" \
            "$local_dir" "${remote_target}:$remote_dir"
        rsync_exit=$?
    else
        local -a patterns=()
        local IFS='|'
        read -r -a patterns <<< "$patterns_csv"
        IFS=$' \t\n'

        local -a rsync_includes=()
        local pattern
        for pattern in "${patterns[@]}"; do
            rsync_includes+=(--include="$pattern")
        done

        if [ "$mode" = "push" ]; then
            rsync -avzP "${rsync_opts[@]}" -e "$ssh_cmd" \
                "${rsync_includes[@]}" \
                --exclude='*' \
                "$local_dir" "${remote_target}:$remote_dir"
            rsync_exit=$?
        else
            rsync -avzP "${rsync_opts[@]}" -e "$ssh_cmd" \
                "${rsync_includes[@]}" \
                --exclude='*' \
                "${remote_target}:$remote_dir" "$local_dir"
            rsync_exit=$?
        fi
    fi

    if [ $rsync_exit -eq 0 ]; then
        echo "Sync complete"
        return 0
    fi

    echo "⚠️  rsync 同步失败，自动回退到 scp ..."
    _remote_sync_scp_fallback "$mode" "$local_dir" "$remote_dir" "$remote_target" "$patterns_csv" "${remote_opts[@]}"
    if [ $? -eq 0 ]; then
        echo "✅ scp 回退同步完成"
        return 0
    fi
    echo "❌ scp 回退同步失败"
    return 1
}

_hf_sync() {
    if [ $# -lt 2 ]; then
        local func_name="${FUNCNAME[1]}"
        echo "Usage: $func_name <ssh_target> [ssh_opts...] <model_name>"
        echo "Example: $func_name user@host -p 2022 Qwen/Qwen3-8B"
        return 1
    fi

    local model="${@: -1}"
    local remote_args=("${@:1:$#-1}")
    local mode
    case "${FUNCNAME[1]}" in
        hf_push) mode="push" ;;
        hf_pull) mode="pull" ;;
        *) echo "❌ Unknown function name"; return 1 ;;
    esac

    local local_base="$HOME/.cache/huggingface/hub"
    local model_dir="models--${model//\//--}"
    local local_dir="$local_base/$model_dir/"
    local remote_dir="~/.cache/huggingface/hub/$model_dir/"

    echo "🔄 Syncing HuggingFace model cache: $model"
    _remote_sync "$mode" "$local_dir" "$remote_dir" "" "hf" "--links" "${remote_args[@]}"
}

hf_push() { _hf_sync "$@"; }
hf_pull() { _hf_sync "$@"; }
alias hf-push='hf_push'
alias hf-pull='hf_pull'

_data_sync() {
    if [ $# -lt 2 ]; then
        local func_name="${FUNCNAME[1]}"
        echo "Usage: $func_name <ssh_target> [ssh_opts...] <dir_name>"
        echo "Example: $func_name user@host -p 2022 data"
        return 1
    fi

    local dir="${@: -1}"
    local remote_args=("${@:1:$#-1}")
    local mode
    case "${FUNCNAME[1]}" in
        data_push) mode="push" ;;
        data_pull) mode="pull" ;;
        *) echo "❌ Unknown function name"; return 1 ;;
    esac

    local local_dir="$HOME/$dir"
    local remote_dir="~/$dir"

    echo "🔄 Syncing directory: $dir"
    _remote_sync "$mode" "$local_dir/" "$remote_dir/" "" "data" "--links" "${remote_args[@]}"
}

# 对外接口
data_push() { _data_sync "$@"; }
data_pull() { _data_sync "$@"; }
alias data-push='data_push'
alias data-pull='data_pull'

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
alias hf-list='hf_list'

_claude_sync() {
    local sync_mode="$1"
    shift
    _remote_sync "$sync_mode" "$HOME/.claude/" "~/.claude/" "settings.json|settings.json.*" "claude" "" "$@"
}

claude_push() { _claude_sync "push" "$@"; }
claude_pull() { _claude_sync "pull" "$@"; }
alias claude-push='claude_push'
alias claude-pull='claude_pull'

_codex_sync() {
    local sync_mode="$1"
    shift
    local patterns="auth.json|auth.json.*|config.toml.*"
    _remote_sync "$sync_mode" "$HOME/.codex/" "~/.codex/" "$patterns" "codex" "" "$@"
}

codex_push() { _codex_sync "push" "$@"; }
codex_pull() { _codex_sync "pull" "$@"; }
alias codex-push='codex_push'
alias codex-pull='codex_pull'

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

export UV_DEFAULT_INDEX="https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
export PIP_INDEX_URL="https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
export PIP_TRUSTED_HOST="mirrors.tuna.tsinghua.edu.cn"
export HF_ENDPOINT=https://hf-mirror.com
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
