#!/bin/bash

# 定义目标目录
TARGET_DIR="/home/www/"

# 切换到目标目录
echo "切换到目标目录: $TARGET_DIR"
cd $TARGET_DIR || { echo "切换目录失败"; exit 1; }

# 检查目标目录是否为空
if [ "$(ls -A $TARGET_DIR)" ]; then
    # 如果目录不为空，自动删除目标目录中的所有文件
    echo "目标目录 $TARGET_DIR 不为空，删除其中的所有文件..."
    rm -rf ${TARGET_DIR}*
fi

# 再次确认我们在正确的目录中
echo "当前目录: $(pwd)"

# 安装 wget 和 unzip 工具（如果尚未安装）
echo "安装 wget 和 unzip 工具..."
sudo yum install -y wget unzip

# 下载 GitHub 仓库的 ZIP 文件
echo "下载 GitHub 仓库的 ZIP 文件..."
wget https://github.com/feeday/WebPage/archive/refs/heads/main.zip -O WebPage-main.zip

# 检查下载是否成功
if [ ! -f "WebPage-main.zip" ]; then
    echo "下载失败"
    exit 1
fi

# 解压下载的 ZIP 文件
echo "解压 ZIP 文件..."
unzip WebPage-main.zip

# 检查解压是否成功
if [ ! -d "WebPage-main" ]; then
    echo "解压失败"
    exit 1
fi

# 移动解压后的子文件夹内容到当前目录
mv WebPage-main/* .
rm -rf WebPage-main.zip WebPage-main

echo "项目解压完成"

