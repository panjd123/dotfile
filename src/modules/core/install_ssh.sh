# SSH config/key planning and application used by the install flow.
dotfile_install_reset_plan() {
  DOTFILE_INSTALL_PLAN_SSH_CONFIG=()
  DOTFILE_INSTALL_PLAN_SSH_KEYS=()
}

dotfile_plan_sshd_changes() {
  if [ ! -f "$DOTFILE_SSHD_CONFIG_FILE" ]; then
    return
  fi

  local item=""
  for item in "${DOTFILE_SSH_CONFIG_CHECKS[@]}"; do
    local key="${item%% *}"
    local target_value="${item#* }"
    local current_setting
    current_setting=$(grep -E "^[[:space:]]*${key}" "$DOTFILE_SSHD_CONFIG_FILE" 2>/dev/null | head -n 1 || true)

    if [[ -n "$current_setting" ]]; then
      local current_value
      current_value=$(echo "$current_setting" | awk '{print $2}')
      if [[ "$current_value" != "$target_value" ]]; then
        DOTFILE_INSTALL_PLAN_SSH_CONFIG+=("修改配置: ${key} [${current_value}] -> [${target_value}]")
      fi
    else
      local default_value="${DOTFILE_DEFAULT_SSH_VALUES[$key]}"
      if [[ -z "$default_value" ]]; then
        DOTFILE_INSTALL_PLAN_SSH_CONFIG+=("新增配置: ${key} ${target_value} (未知默认值)")
      elif [[ "$default_value" != "$target_value" ]]; then
        DOTFILE_INSTALL_PLAN_SSH_CONFIG+=("新增配置: ${key} ${target_value} (默认为 ${default_value})")
      fi
    fi
  done
}

dotfile_plan_key_changes() {
  local key=""

  if [ ! -f "$DOTFILE_AUTHORIZED_KEYS_FILE" ]; then
    for key in "${DOTFILE_SSH_PUBLIC_KEYS[@]}"; do
      DOTFILE_INSTALL_PLAN_SSH_KEYS+=("新增公钥: ${key:0:50}...")
    done
    return
  fi

  for key in "${DOTFILE_SSH_PUBLIC_KEYS[@]}"; do
    local key_fingerprint
    key_fingerprint=$(echo "$key" | awk '{print $2}')
    if ! grep -qF "$key_fingerprint" "$DOTFILE_AUTHORIZED_KEYS_FILE"; then
      DOTFILE_INSTALL_PLAN_SSH_KEYS+=("新增公钥: ${key:0:50}...")
    fi
  done
}

dotfile_apply_sshd_changes() {
  local sudo_mode="$1"
  local config_changed=false
  local sudo_cmd=()
  local item=""

  if [ "$sudo_mode" = "interactive" ]; then
    sudo_cmd=(sudo)
  elif [ "$sudo_mode" = "noninteractive" ]; then
    sudo_cmd=(sudo -n)
  fi

  for item in "${DOTFILE_SSH_CONFIG_CHECKS[@]}"; do
    local key="${item%% *}"
    local target_value="${item#* }"
    local current_setting
    current_setting=$(grep -E "^[[:space:]]*${key}" "$DOTFILE_SSHD_CONFIG_FILE" 2>/dev/null | head -n 1 || true)

    if [[ -n "$current_setting" ]]; then
      local current_value
      current_value=$(echo "$current_setting" | awk '{print $2}')
      if [[ "$current_value" != "$target_value" ]]; then
        "${sudo_cmd[@]}" sed -i "s|^[[:space:]]*${key}.*|${key} ${target_value}|g" "$DOTFILE_SSHD_CONFIG_FILE" || return 1
        config_changed=true
      fi
    else
      local default_value="${DOTFILE_DEFAULT_SSH_VALUES[$key]}"
      if [[ -z "$default_value" ]] || [[ "$default_value" != "$target_value" ]]; then
        printf '%s\n' "${key} ${target_value}" | "${sudo_cmd[@]}" tee -a "$DOTFILE_SSHD_CONFIG_FILE" > /dev/null || return 1
        config_changed=true
      fi
    fi
  done

  if [ "$config_changed" = true ]; then
    echo "[dotfile] 正在重启 SSH 服务..."
    if command -v systemctl >/dev/null 2>&1; then
      "${sudo_cmd[@]}" systemctl restart sshd || "${sudo_cmd[@]}" systemctl restart ssh || return 1
    elif command -v service >/dev/null 2>&1; then
      "${sudo_cmd[@]}" service sshd restart || "${sudo_cmd[@]}" service ssh restart || return 1
    else
      echo "[dotfile] 警告: 无法自动重启 SSH 服务，请手动重启以应用更改。"
    fi
  fi
}

dotfile_apply_key_changes() {
  local ssh_dir
  ssh_dir=$(dirname "$DOTFILE_AUTHORIZED_KEYS_FILE")

  if [ ! -d "$ssh_dir" ]; then
    mkdir -p "$ssh_dir" || return 1
    chmod 700 "$ssh_dir" || return 1
  fi

  if [ ! -f "$DOTFILE_AUTHORIZED_KEYS_FILE" ]; then
    touch "$DOTFILE_AUTHORIZED_KEYS_FILE" || return 1
    chmod 600 "$DOTFILE_AUTHORIZED_KEYS_FILE" || return 1
  fi

  local key=""
  for key in "${DOTFILE_SSH_PUBLIC_KEYS[@]}"; do
    local key_fingerprint
    key_fingerprint=$(echo "$key" | awk '{print $2}')
    if ! grep -qF "$key_fingerprint" "$DOTFILE_AUTHORIZED_KEYS_FILE"; then
      printf '%s\n' "$key" >> "$DOTFILE_AUTHORIZED_KEYS_FILE" || return 1
    fi
  done
}
