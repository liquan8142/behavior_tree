#!/bin/bash
# GitBook本地开发脚本

set -e  # 遇到错误时退出

echo "========================================"
echo "GitBook本地开发环境"
echo "========================================"

# 检查是否安装了gitbook-cli
if ! command -v gitbook &> /dev/null; then
    echo "❌ GitBook CLI未安装"
    echo "正在安装gitbook-cli..."
    npm install -g gitbook-cli
    echo "✅ GitBook CLI安装完成"
fi

# 检查当前目录是否有GitBook配置
if [ ! -f "package.json" ]; then
    echo "❌ 未找到package.json"
    exit 1
fi

# 安装本地依赖
echo "📦 安装本地依赖..."
npm install

# 安装GitBook插件
echo "🔌 安装GitBook插件..."
gitbook install

# 显示配置信息
echo ""
echo "📊 配置信息:"
echo "  - 文档目录: $(pwd)"
echo "  - 首页: intro.md"
echo "  - 目录: SUMMARY.md"
echo "  - 主题: theme-default"
echo "  - 插件: search, sharing, fontsettings, livereload"

# 启动本地服务器
echo ""
echo "🚀 启动本地GitBook服务器..."
echo "  访问地址: http://localhost:4000"
echo "  按 Ctrl+C 停止服务器"
echo ""

gitbook serve