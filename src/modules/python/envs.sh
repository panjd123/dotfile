# Python virtual environment activation shortcuts.
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
