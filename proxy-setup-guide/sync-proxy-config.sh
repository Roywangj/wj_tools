#!/bin/bash
# 自动同步代理配置到 VSCode/Cursor
#
# 读取顺序：
#   1. 当前环境变量 PROXY_HOST / PROXY_PORT（由 proxy_lab / proxy_local 导出）
#   2. 若未设置，则从 ~/.zshrc 中兜底抓取（兼容旧的顶层 export 写法）

PROXY_HOST="${PROXY_HOST:-$(grep -E '^[[:space:]]*(export[[:space:]]+)?PROXY_HOST=' ~/.zshrc 2>/dev/null | head -n1 | cut -d'"' -f2)}"
PROXY_PORT="${PROXY_PORT:-$(grep -E '^[[:space:]]*(export[[:space:]]+)?PROXY_PORT=' ~/.zshrc 2>/dev/null | head -n1 | cut -d'"' -f2)}"

if [ -z "$PROXY_HOST" ]; then
    echo "❌ 未检测到 PROXY_HOST"
    echo "   请先在当前 shell 执行 proxy_lab 或 proxy_local，再运行 sync-proxy"
    exit 1
fi

if [ -z "$PROXY_PORT" ]; then
    echo "⚠️  未检测到 PROXY_PORT，使用默认端口 7897"
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

