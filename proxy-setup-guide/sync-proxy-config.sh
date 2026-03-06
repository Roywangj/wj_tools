#!/bin/bash
# 自动同步代理配置到 VSCode/Cursor

# 从 .zshrc 中读取 PROXY_HOST 和 PROXY_PORT
PROXY_HOST=$(grep -E '^PROXY_HOST=' ~/.zshrc | cut -d'"' -f2)
PROXY_PORT=$(grep -E '^PROXY_PORT=' ~/.zshrc | cut -d'"' -f2)

if [ -z "$PROXY_HOST" ]; then
    echo "❌ 无法从 .zshrc 中读取 PROXY_HOST"
    exit 1
fi

if [ -z "$PROXY_PORT" ]; then
    echo "⚠️  未找到 PROXY_PORT，使用默认端口 7897"
    PROXY_PORT="7897"
fi

echo "📡 检测到代理配置: ${PROXY_HOST}:${PROXY_PORT}"
echo ""

# 配置文件路径
CURSOR_SETTINGS="$HOME/.cursor-server/data/Machine/settings.json"
VSCODE_SETTINGS="$HOME/.vscode-server/data/Machine/settings.json"

# 生成配置内容
generate_config() {
    cat <<EOF
{
    "http.proxy": "http://${PROXY_HOST}:${PROXY_PORT}",
    "http.proxySupport": "on",
    "http.proxyStrictSSL": false,
    "http.noProxy": [
        "localhost",
        "127.0.0.1",
        "10.0.0.0/8"
    ]
}
EOF
}

# 更新 Cursor 配置
if [ -d "$HOME/.cursor-server" ]; then
    mkdir -p "$(dirname "$CURSOR_SETTINGS")"
    generate_config > "$CURSOR_SETTINGS"
    echo "✅ Cursor 代理配置已更新: http://${PROXY_HOST}:${PROXY_PORT}"
else
    echo "⚠️  Cursor Server 未安装，跳过"
fi

# 更新 VSCode 配置
if [ -d "$HOME/.vscode-server" ]; then
    mkdir -p "$(dirname "$VSCODE_SETTINGS")"
    generate_config > "$VSCODE_SETTINGS"
    echo "✅ VSCode 代理配置已更新: http://${PROXY_HOST}:${PROXY_PORT}"
else
    echo "⚠️  VSCode Server 未安装，跳过"
fi

echo ""
echo "💡 提示: 请在编辑器中执行 'Developer: Reload Window' 使配置生效"

