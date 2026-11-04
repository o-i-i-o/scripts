#!/bin/bash
# build-ibus.sh
# 用法：把本脚本放在 ibus-1.5.35-rc1 的父目录，然后执行 ./build-ibus.sh
# 如需调整目录，修改 IBUS_DIR 变量即可。

set -e

IBUS_DIR="ibus-1.5.35-rc1"

# 进入源码目录
cd "$IBUS_DIR"

# 安装编译依赖
sudo apt install -y \
    libgtk2.0-dev \
    pkg-config \
    gtk-doc-tools \
    libdconf-dev \
    systemd-dev \
    libdbusmenu-gtk3-dev \
    libnotify-dev \
    unicode-cldr-core \
    valac \
    libgirepository1.0-dev

# 准备 Unicode 数据文件
sudo mkdir -p /usr/share/unicode/emoji
sudo mkdir -p /usr/share/unicode/ucd

sudo wget -O /usr/share/unicode/emoji/emoji-test.txt \
    http://www.unicode.org/Public/emoji/4.0/emoji-test.txt

sudo wget -O /usr/share/unicode/ucd/NamesList.txt \
    https://www.unicode.org/Public/UNIDATA/NamesList.txt

sudo wget -O /usr/share/unicode/ucd/Blocks.txt \
    https://www.unicode.org/Public/UNIDATA/Blocks.txt

# 生成并编译
./autogen.sh
make
sudo make install

# 验证
ibus version
