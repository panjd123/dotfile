#!/bin/sh
set -e
. /etc/os-release
c=$VERSION_CODENAME
v=$(printf "%d%02d" $(echo "$VERSION_ID" | awk -F. '{m=$1+0; n=(NF>1)?$2+0:0; print m, n}'))
if [ "$v" -lt 2404 ]; then
cat >/etc/apt/sources.list <<EOF
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $c main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ ${c}-updates main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ ${c}-backports main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ ${c}-security main restricted universe multiverse
EOF
else
mkdir -p /etc/apt/sources.list.d
cat >/etc/apt/sources.list.d/ubuntu.sources <<EOF
Types: deb
URIs: http://mirrors.tuna.tsinghua.edu.cn/ubuntu/
Suites: $c ${c}-updates ${c}-backports ${c}-security
Components: main restricted universe multiverse
EOF
fi
