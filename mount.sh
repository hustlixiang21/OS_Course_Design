#!/bin/bash

# 检查是否有输入参数
if [ -z "$1" ]; then
    echo "请提供一个完整路径的.asm文件名作为参数。"
    exit 1
fi

# 获取完整路径的文件名
full_filename=$1

# 获取文件所在目录
filedir=$(dirname "$full_filename")

# 从完整路径的文件名中提取基本文件名（不包含路径）
filename=$(basename "$full_filename" .asm)

# 创建挂载点
if [ ! -d /mnt/floppy ]; then
    sudo mkdir /mnt/floppy
fi

# 编译汇编文件，输出文件到原始文件所在目录
nasm "$full_filename" -o "${filedir}/${filename}.com"

# 挂载软盘映像
sudo mount -o loop pm.img /mnt/floppy

# 将编译后的文件复制到软盘
sudo cp "${filedir}/${filename}.com" /mnt/floppy

# 卸载软盘映像
sudo umount /mnt/floppy

echo "操作完成"

