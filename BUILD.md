# 斗地主助手 - 构建说明

由于CI/CD构建不稳定，推荐本地构建。

## 本地构建步骤

### 前提条件
- 安装 Theos
- 安装 iOS SDK

### 构建命令
```bash
cd DDZHelper
make package FINALPACKAGE=1
```

### 生成IPA
```bash
mkdir -p Payload/DDZHelper.app
cp -r .theos/obj/arm64/DDZHelper.app/* Payload/DDZHelper.app/
cd Payload && zip -r ../DDZHelper.ipa . && cd ..
```

## 功能说明
- AI智能分析叫地主、加倍、出牌三个阶段
- 全局悬浮窗显示建议
- 后台保活运行
- 百度OCR识别游戏画面

## 注意
仅用于单机斗地主学习研究。
