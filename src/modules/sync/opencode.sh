# Merge only the user-selected provider into the destination JSON so machine-
# specific OpenCode settings stay local while the active provider follows sync.
_opencode_merge_provider_json() {
    local source_json="$1"
    local dest_json="$2"
    local output_json="$3"

    python3 - "$source_json" "$dest_json" "$output_json" <<'PY'
import json
import os
import sys

source_path, dest_path, output_path = sys.argv[1:4]


def load_json(path, allow_missing):
    if allow_missing and (not os.path.exists(path) or os.path.getsize(path) == 0):
        return {}

    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)

    if not isinstance(data, dict):
        print(f"JSON root must be an object: {path}", file=sys.stderr)
        raise SystemExit(1)

    return data


source_data = load_json(source_path, allow_missing=False)
if "provider" not in source_data:
    print(f"provider field not found in {source_path}", file=sys.stderr)
    raise SystemExit(3)

dest_data = load_json(dest_path, allow_missing=True)
dest_data["provider"] = source_data["provider"]

with open(output_path, "w", encoding="utf-8") as handle:
    json.dump(dest_data, handle, indent=2, ensure_ascii=False)
    handle.write("\n")
PY
}

# OpenCode's main config mixes one portable provider choice with machine-local
# settings, so opencode sync handles opencode.json separately from file-level rsync.
_opencode_sync_provider() {
    local sync_mode="$1"
    shift

    if [ $# -lt 1 ]; then
        echo "Usage: opencode_${sync_mode} <ssh_target> [ssh_opts...]"
        echo "Example: opencode_${sync_mode} user@host -p 2022"
        return 1
    fi

    local local_file="$HOME/.config/opencode/opencode.json"
    local remote_file="~/.config/opencode/opencode.json"
    local remote_target="$1"
    shift
    local -a remote_opts=("$@")

    local -a ssh_cmd=(ssh)
    local -a scp_cmd=(scp)
    if [ ${#remote_opts[@]} -gt 0 ]; then
        ssh_cmd+=("${remote_opts[@]}")
        scp_cmd+=("${remote_opts[@]}")
    fi

    local tmp_source
    local tmp_dest
    local tmp_merged
    tmp_source="$(mktemp)" || return 1
    tmp_dest="$(mktemp)" || {
        rm -f "$tmp_source"
        return 1
    }
    tmp_merged="$(mktemp)" || {
        rm -f "$tmp_source" "$tmp_dest"
        return 1
    }

    if [ "$sync_mode" = "push" ]; then
        if [ ! -f "$local_file" ]; then
            echo "ℹ️  本地缺少 $local_file，跳过 provider 同步"
            rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
            return 0
        fi

        if ! "${ssh_cmd[@]}" "$remote_target" "mkdir -p ~/.config/opencode"; then
            rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
            return 1
        fi

        if ! "${ssh_cmd[@]}" "$remote_target" "if [ -f ~/.config/opencode/opencode.json ]; then cat ~/.config/opencode/opencode.json; fi" > "$tmp_dest"; then
            rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
            return 1
        fi

        # Seed the whole file when the receiver has no config yet; field-level
        # merging only applies once both sides already have opencode.json.
        if [ ! -s "$tmp_dest" ]; then
            if ! "${scp_cmd[@]}" "$local_file" "${remote_target}:${remote_file}"; then
                rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
                return 1
            fi

            echo "Copied full config -> ${remote_target}:${remote_file}"
            rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
            return 0
        fi

        _opencode_merge_provider_json "$local_file" "$tmp_dest" "$tmp_merged"
        local merge_status=$?
        if [ $merge_status -eq 3 ]; then
            echo "ℹ️  本地 $local_file 不含 provider，跳过 provider 同步"
            rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
            return 0
        fi
        if [ $merge_status -ne 0 ]; then
            rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
            return $merge_status
        fi

        if ! "${scp_cmd[@]}" "$tmp_merged" "${remote_target}:${remote_file}"; then
            rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
            return 1
        fi

        echo "Synced provider field -> ${remote_target}:${remote_file}"
        rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
        return 0
    fi

    mkdir -p "$HOME/.config/opencode"

    if ! "${ssh_cmd[@]}" "$remote_target" "if [ -f ~/.config/opencode/opencode.json ]; then cat ~/.config/opencode/opencode.json; fi" > "$tmp_source"; then
        rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
        return 1
    fi

    if [ ! -s "$tmp_source" ]; then
        echo "ℹ️  远程缺少 ${remote_file}，跳过 provider 同步"
        rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
        return 0
    fi

    if [ ! -f "$local_file" ]; then
        if ! "${scp_cmd[@]}" "${remote_target}:${remote_file}" "$local_file"; then
            rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
            return 1
        fi
        echo "Copied full config -> $local_file"
        rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
        return 0
    fi

    if [ -f "$local_file" ]; then
        cp "$local_file" "$tmp_dest"
    fi

    _opencode_merge_provider_json "$tmp_source" "$tmp_dest" "$tmp_merged"
    local merge_status=$?
    if [ $merge_status -eq 3 ]; then
        echo "ℹ️  远程 ${remote_file} 不含 provider，跳过 provider 同步"
        rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
        return 0
    fi
    if [ $merge_status -ne 0 ]; then
        rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
        return $merge_status
    fi

    cp "$tmp_merged" "$local_file"
    echo "Synced provider field -> $local_file"
    rm -f "$tmp_source" "$tmp_dest" "$tmp_merged"
}

# Sync OpenCode local config files between machines.
_opencode_sync() {
    local sync_mode="$1"
    shift
    # Plugins are managed as their own git repo and are not part of opencode sync.
    _remote_sync "$sync_mode" "$HOME/.config/opencode/" "~/.config/opencode/" "oh-my-opencode.json" "opencode" "" "$@" || return 1
    _opencode_sync_provider "$sync_mode" "$@" || return 1
}

opencode_push() { _opencode_sync "push" "$@"; }
opencode_pull() { _opencode_sync "pull" "$@"; }
alias opencode-push='opencode_push'
alias opencode-pull='opencode_pull'
