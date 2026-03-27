#!/bin/bash
# 快速预览脚本

set -e  # 遇到错误时退出

echo "========================================"
echo "GitBook快速预览"
echo "========================================"

# 检查是否已构建
if [ ! -d "_book" ]; then
    echo "⚠️  未找到构建目录，正在构建..."
    ./build.sh <<< "1"
fi

# 选择端口
PORT=${1:-8000}

echo ""
echo "🌐 启动本地预览服务器..."
echo "  访问地址: http://localhost:$PORT"
echo "  按 Ctrl+C 停止服务器"
echo ""

# 检查Python版本
if command -v python3 &> /dev/null; then
    cd _book && python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    cd _book && python -m SimpleHTTPServer $PORT
else
    echo "❌ 未找到Python，请安装Python或使用其他HTTP服务器"
    echo "   可以使用: npx http-server _book -p $PORT"
    exit 1
fi