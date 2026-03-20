# File backup, search, and archive extraction helpers.
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
