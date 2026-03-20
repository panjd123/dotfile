# Directory backup and restore helpers based on tar + zstd.
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
