# 代理配置快速参考

## 🎯 修改代理配置

### 1. 编辑 ~/.zshrc

```bash
vim ~/.zshrc
```

修改这两行：
```bash
PROXY_HOST="你的代理IP"
PROXY_PORT="你的代理端口"
```

### 2. 重新加载配置

```bash
source ~/.zshrc
```

### 3. 同步到编辑器

```bash
sync-proxy
```

### 4. 重新加载编辑器窗口

在 VSCode/Cursor 中：
- 按 `Cmd+Shift+P` 或 `Ctrl+Shift+P`
- 输入 `Reload Window`

---

## 📊 当前配置

```bash
# 查看当前代理配置
echo "代理: $http_proxy"
echo "主机: $PROXY_HOST"
echo "端口: $PROXY_PORT"

# 查看编辑器配置
cat ~/.cursor-server/data/Machine/settings.json
cat ~/.vscode-server/data/Machine/settings.json
```

---

## 🔧 常用端口

- `7890` - Clash 默认 HTTP 端口
- `7891` - Clash 默认 SOCKS5 端口  
- `7897` - 当前配置端口（可修改）

---

## ⚡ 快捷命令

```bash
# 查看代理状态
echo $http_proxy

# 同步代理配置
sync-proxy

# 临时禁用代理
unset http_proxy https_proxy all_proxy

# 重新启用代理
source ~/.zshrc
```

---

**完整文档**: `~/proxy-setup-guide.md`

