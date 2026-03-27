#!/bin/bash
# GitBook构建脚本

set -e  # 遇到错误时退出

echo "========================================"
echo "GitBook构建工具"
echo "========================================"

# 检查是否安装了gitbook-cli
if ! command -v gitbook &> /dev/null; then
    echo "❌ GitBook CLI未安装"
    echo "请先运行: npm install -g gitbook-cli"
    exit 1
fi

# 安装GitBook插件
echo "🔌 安装/更新GitBook插件..."
gitbook install

# 构建选项
echo ""
echo "请选择构建选项:"
echo "  1) 构建网站 (默认)"
echo "  2) 构建PDF"
echo "  3) 构建ePub"
echo "  4) 构建Mobi"
echo "  5) 构建所有格式"
echo "  6) 清理构建目录"
echo -n "请输入选项 [1-6]: "
read option

case $option in
    1|"")
        echo "🌐 构建网站..."
        gitbook build
        echo "✅ 网站构建完成，输出到: _book/"
        echo "   可以使用以下命令预览:"
        echo "   cd _book && python3 -m http.server 8000"
        ;;
    2)
        echo "📄 构建PDF..."
        gitbook pdf
        echo "✅ PDF构建完成: book.pdf"
        ;;
    3)
        echo "📱 构建ePub..."
        gitbook epub
        echo "✅ ePub构建完成: book.epub"
        ;;
    4)
        echo "📲 构建Mobi..."
        gitbook mobi
        echo "✅ Mobi构建完成: book.mobi"
        ;;
    5)
        echo "📚 构建所有格式..."
        gitbook build
        gitbook pdf
        gitbook epub
        gitbook mobi
        echo "✅ 所有格式构建完成！"
        echo "  - 网站: _book/"
        echo "  - PDF: book.pdf"
        echo "  - ePub: book.epub"
        echo "  - Mobi: book.mobi"
        ;;
    6)
        echo "🧹 清理构建目录..."
        rm -rf _book book.pdf book.epub book.mobi
        echo "✅ 清理完成"
        ;;
    *)
        echo "❌ 无效选项"
        exit 1
        ;;
esac