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
