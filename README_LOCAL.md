# GitBook本地开发指南

本文档介绍如何在本地使用GitBook开发和预览文档。

## 前置要求

- Node.js (>= 10.0.0)
- npm 或 yarn

## 安装GitBook CLI

```bash
# 全局安装gitbook-cli
npm install -g gitbook-cli
```

## 本地开发脚本

### 1. 启动本地开发服务器（推荐）
```bash
./start-local.sh
```
这将：
- 检查并安装GitBook CLI（如果需要）
- 安装本地依赖
- 安装GitBook插件
- 启动本地服务器在 http://localhost:4000

### 2. 构建文档
```bash
./build.sh
```
交互式菜单，可以选择构建：
- 网站（HTML）
- PDF
- ePub
- Mobi
- 所有格式
- 清理构建目录

### 3. 快速预览已构建的文档
```bash
./preview.sh [端口号]
```
默认端口：8000
访问：http://localhost:8000

## 手动命令

### 安装插件
```bash
gitbook install
```

### 本地预览
```bash
gitbook serve
# 访问 http://localhost:4000
```

### 构建静态网站
```bash
gitbook build
# 输出到 _book/ 目录
```

### 生成电子书
```bash
gitbook pdf    # 生成PDF
gitbook epub   # 生成ePub
gitbook mobi   # 生成Mobi
```

## 目录结构

```
behavior_tree/
├── .gitbook.yaml          # GitBook配置
├── SUMMARY.md             # 目录导航
├── intro.md               # 首页
├── styles/                # 自定义样式
│   └── website.css
├── package.json           # 项目配置
├── start-local.sh         # 启动脚本
├── build.sh              # 构建脚本
├── preview.sh            # 预览脚本
└── README_LOCAL.md       # 本文件
```

## 常见问题

### 1. GitBook CLI安装失败
```bash
# 尝试使用管理员权限
sudo npm install -g gitbook-cli

# 或者使用nvm管理Node.js版本
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install --lts
nvm use --lts
npm install -g gitbook-cli
```

### 2. 插件安装失败
```bash
# 清理缓存
rm -rf node_modules
npm cache clean --force

# 重新安装
npm install
gitbook install
```

### 3. 构建时出现错误
```bash
# 更新GitBook
gitbook update

# 检查Node.js版本
node --version  # 需要 >= 10.0.0
```

### 4. 本地服务器无法访问
- 检查防火墙设置
- 尝试不同端口：`gitbook serve --port 4001`
- 检查是否有其他程序占用端口

## 开发工作流

1. **编辑文档**：修改Markdown文件
2. **本地预览**：运行 `./start-local.sh`
3. **实时查看**：浏览器访问 http://localhost:4000
4. **保存更改**：GitBook会自动重新加载
5. **构建发布**：运行 `./build.sh` 生成最终文件
6. **提交到GitHub**：推送到远程仓库

## 性能优化

### 加快构建速度
```bash
# 只构建必要的格式
./build.sh <<< "1"  # 只构建网站

# 使用缓存
gitbook build --log=debug --debug
```

### 减少内存使用
```bash
# 限制Node.js内存
NODE_OPTIONS="--max-old-space-size=4096" gitbook build
```

## 更多资源

- [GitBook官方文档](https://toolchain.gitbook.com/)
- [GitBook CLI命令参考](https://github.com/GitbookIO/gitbook-cli)
- [Markdown语法指南](https://www.markdownguide.org/)
- [GitBook插件市场](https://plugins.gitbook.com/)