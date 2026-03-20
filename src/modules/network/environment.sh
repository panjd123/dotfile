# Apply region-gated mirrors and define opt-in proxy environment helpers.
dotfile_apply_region_network_settings
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
