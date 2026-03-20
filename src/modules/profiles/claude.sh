# Claude CLI aliases and profile switching.
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
