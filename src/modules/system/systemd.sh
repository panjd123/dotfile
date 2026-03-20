# Systemd shortcuts plus completion remapping for the custom aliases.
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
