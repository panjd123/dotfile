# Region detection and region-gated mirror environment variables.
dotfile_read_network_region() {
  if [ ! -f "$DOTFILE_NETWORK_REGION_FILE" ]; then
    echo "UNKNOWN"
    return 0
  fi

  head -n 1 "$DOTFILE_NETWORK_REGION_FILE" 2>/dev/null | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]'
}

dotfile_write_network_region() {
  local region="${1:-UNKNOWN}"
  mkdir -p "$DOTFILES_DIR"
  printf '%s\n' "$region" > "$DOTFILE_NETWORK_REGION_FILE"
}

dotfile_detect_network_region() {
  local country_code=""
  local response=""
  local url=""
  local -a country_code_urls=(
    "https://ipinfo.io/country"
    "https://ifconfig.co/country-iso"
    "https://ipapi.co/country/"
  )

  if ! command -v curl >/dev/null 2>&1; then
    echo "UNKNOWN"
    return 0
  fi

  # Try lightweight country-code endpoints first, then fall back to a page that
  # can still hint whether the machine is in mainland China.
  for url in "${country_code_urls[@]}"; do
    response=$(curl -fsSL --connect-timeout 2 --max-time 5 "$url" 2>/dev/null || true)
    country_code=$(printf '%s' "$response" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
    if [[ "$country_code" =~ ^[A-Z]{2}$ ]]; then
      break
    fi
  done

  if [[ ! "$country_code" =~ ^[A-Z]{2}$ ]]; then
    response=$(curl -fsSL --connect-timeout 2 --max-time 5 "https://cip.cc" 2>/dev/null || true)
    if printf '%s' "$response" | grep -Eiq '中国|china'; then
      country_code="CN"
    elif [ -n "$response" ]; then
      country_code="NON_CN"
    fi
  fi

  if [ "$country_code" = "CN" ]; then
    echo "CN"
  elif [[ "$country_code" =~ ^[A-Z]{2}$ ]] || [ "$country_code" = "NON_CN" ]; then
    echo "OVERSEAS"
  else
    echo "UNKNOWN"
  fi
}

dotfile_refresh_network_region() {
  local region="${1:-}"
  if [ -z "$region" ]; then
    region=$(dotfile_detect_network_region)
  fi
  dotfile_write_network_region "$region"
  echo "[dotfile] 当前网络区域: $region"
}

dotfile_apply_cn_network_settings() {
  export UV_DEFAULT_INDEX="$DOTFILE_CN_PYPI_INDEX"
  export PIP_INDEX_URL="$DOTFILE_CN_PYPI_INDEX"
  export PIP_TRUSTED_HOST="$DOTFILE_CN_PYPI_HOST"
  export HF_ENDPOINT="$DOTFILE_CN_HF_ENDPOINT"
}

dotfile_clear_cn_network_settings() {
  if [ "${UV_DEFAULT_INDEX:-}" = "$DOTFILE_CN_PYPI_INDEX" ]; then
    unset UV_DEFAULT_INDEX
  fi
  if [ "${PIP_INDEX_URL:-}" = "$DOTFILE_CN_PYPI_INDEX" ]; then
    unset PIP_INDEX_URL
  fi
  if [ "${PIP_TRUSTED_HOST:-}" = "$DOTFILE_CN_PYPI_HOST" ]; then
    unset PIP_TRUSTED_HOST
  fi
  if [ "${HF_ENDPOINT:-}" = "$DOTFILE_CN_HF_ENDPOINT" ]; then
    unset HF_ENDPOINT
  fi
}

dotfile_apply_region_network_settings() {
  local region
  region=$(dotfile_read_network_region)
  # Treat UNKNOWN as CN to avoid missing mirror settings when detection fails.
  if [ "$region" = "CN" ] || [ "$region" = "UNKNOWN" ]; then
    dotfile_apply_cn_network_settings
  else
    dotfile_clear_cn_network_settings
  fi
}
