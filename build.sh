#!/bin/bash

# 本地构建脚本 - 适用于 macOS/Linux

set -e

echo "开始构建 DDZHelper..."

# 检查 Theos 是否安装
if [ ! -d "$THEOS" ]; then
    echo "错误: 未找到 Theos"
    echo "请先安装 Theos: https://theos.dev/docs/installation"
    exit 1
fi

# 清理旧构建
make clean

# 构建
make package FINALPACKAGE=1

# 查找生成的 deb 文件
DEB_FILE=$(ls -t packages/*.deb | head -1)

if [ -f "$DEB_FILE" ]; then
    echo "✅ 构建成功: $DEB_FILE"

    # 转换为 IPA (可选)
    echo "正在生成 IPA..."
    mkdir -p Payload
    dpkg-deb -x "$DEB_FILE" Payload/
    cd Payload && zip -r ../DDZHelper.ipa . && cd ..
    rm -rf Payload

    echo "✅ IPA 已生成: DDZHelper.ipa"
else
    echo "❌ 构建失败"
    exit 1
fi
