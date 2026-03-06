# 统一代理配置方案

一个简单高效的方案，让终端、VSCode 和 Cursor 都使用相同的代理配置，修改一处即可全局生效。

## 📋 目录

- [概述](#概述)
- [配置文件](#配置文件)
- [使用方法](#使用方法)
- [工作原理](#工作原理)
- [故障排除](#故障排除)

---

## 概述

### 🎯 目标

实现统一的代理配置管理：
- ✅ 所有工具共享同一个代理配置源
- ✅ 只需修改一处即可全局生效
- ✅ 支持终端、VSCode、Cursor 等工具

### 📦 包含的配置

1. **终端代理**：通过环境变量控制
2. **VSCode 代理**：插件下载和更新
3. **Cursor 代理**：插件下载和更新

---

## 配置文件

### 1. Shell 配置文件 (`~/.zshrc`)

在 `~/.zshrc` 文件末尾添加以下内容：

```bash
# ==================== 代理配置 ====================
# 第一步：设置代理主机和端口（修改这两行即可更换代理地址）
PROXY_HOST="10.106.1.36"
PROXY_PORT="7897"

# 第二步：应用代理设置（以下四行无需修改）
export http_proxy=http://${PROXY_HOST}:${PROXY_PORT}
export https_proxy=http://${PROXY_HOST}:${PROXY_PORT}
export all_proxy=socks5://${PROXY_HOST}:${PROXY_PORT}
# export no_proxy=localhost,127.0.0.1,localaddress,.localdomain.com,10.0.0.0/8

# 同步代理配置到 VSCode/Cursor
alias sync-proxy='~/sync-proxy-config.sh'
```

**说明：**
- `PROXY_HOST`：代理服务器的 IP 地址（**可自定义**）
- `PROXY_PORT`：代理服务器的端口号（**可自定义**）
- `http_proxy` 等：终端环境变量，影响 curl、wget、Python 等工具
- `no_proxy`：不走代理的地址列表（目前已注释，如需启用请去掉 `#`）
- `sync-proxy`：快捷命令，用于同步配置到编辑器

### 2. 同步脚本 (`~/sync-proxy-config.sh`)

创建文件 `~/sync-proxy-config.sh`，内容如下：

```bash
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
```

**设置执行权限：**

```bash
chmod +x ~/sync-proxy-config.sh
```

---

## 使用方法

### 🚀 初次设置

1. **编辑 `~/.zshrc`**，添加上述配置内容
2. **创建同步脚本** `~/sync-proxy-config.sh`，设置执行权限
3. **重新加载配置**：
   ```bash
   source ~/.zshrc
   ```
4. **同步到编辑器**：
   ```bash
   sync-proxy
   ```

### 🔄 日常使用

#### 更换代理地址或端口

当需要更换代理服务器或端口时：

**步骤 1：修改配置**

编辑 `~/.zshrc`，修改 `PROXY_HOST` 和/或 `PROXY_PORT` 行：

```bash
PROXY_HOST="新的IP地址"
PROXY_PORT="新的端口号"  # 可选，如不修改则保持原端口
```

**步骤 2：重新加载**

```bash
source ~/.zshrc
```

**步骤 3：同步配置**

```bash
sync-proxy
```

输出示例：
```
📡 检测到代理配置: 10.106.1.36:7897

✅ Cursor 代理配置已更新: http://10.106.1.36:7897
✅ VSCode 代理配置已更新: http://10.106.1.36:7897

💡 提示: 请在编辑器中执行 'Developer: Reload Window' 使配置生效
```

**步骤 4：重新加载编辑器窗口**

在 VSCode/Cursor 中：
1. 按 `Cmd+Shift+P` (macOS) 或 `Ctrl+Shift+P` (Linux/Windows)
2. 输入 `Reload Window`
3. 选择 `Developer: Reload Window`

#### 临时禁用代理

如果需要临时禁用代理（当前终端会话）：

```bash
unset http_proxy https_proxy all_proxy
```

重新开启（重新加载配置）：

```bash
source ~/.zshrc
```

#### 永久禁用代理

注释掉 `~/.zshrc` 中的相关行：

```bash
# PROXY_HOST="10.106.1.36"

# export http_proxy=http://${PROXY_HOST}:7897
# export https_proxy=http://${PROXY_HOST}:7897
# export all_proxy=socks5://${PROXY_HOST}:7897
```

---

## 工作原理

### 架构图

```
┌─────────────────────────────────────────────┐
│              ~/.zshrc                        │
│   PROXY_HOST="10.106.1.36"  ← 唯一配置源    │
│   PROXY_PORT="7897"         ← 端口配置      │
└─────────────────┬───────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
┌───────────────┐   ┌──────────────────┐
│  终端环境变量  │   │  sync-proxy-config.sh│
│               │   │   (同步脚本)       │
│ http_proxy=...│   └──────────┬────────┘
│ https_proxy=..│              │
│ all_proxy=... │         ┌────┴────┐
└───────────────┘         │         │
                          ▼         ▼
                  ┌──────────┐  ┌──────────┐
                  │ Cursor   │  │ VSCode   │
                  │ settings │  │ settings │
                  └──────────┘  └──────────┘
```

### 配置层级

1. **配置源**：`~/.zshrc` 中的 `PROXY_HOST` 和 `PROXY_PORT` 变量
2. **终端代理**：通过环境变量自动生效
3. **编辑器代理**：通过 `sync-proxy` 命令手动同步

### 生效范围

| 工具/场景 | 配置方式 | 生效时机 |
|----------|---------|---------|
| 终端命令 (curl, wget, git) | 环境变量 | 自动（开启新终端或 source） |
| Python requests | 环境变量 | 自动 |
| VSCode 插件 | settings.json | 手动（运行 sync-proxy 后） |
| Cursor 插件 | settings.json | 手动（运行 sync-proxy 后） |
| npm/yarn | 环境变量 | 自动 |

---

## 故障排除

### 问题 1：连接被拒绝 (Connection Refused)

**现象：**
```
ConnectionRefusedError: [Errno 111] Connection refused
```

**可能原因：**
- 代理服务器未运行
- 代理地址或端口错误
- 内网地址不应走代理

**解决方案：**

1. 检查代理服务器是否运行
2. 验证 `PROXY_HOST` 和端口是否正确
3. 启用 `no_proxy` 排除内网地址：
   ```bash
   # 在 ~/.zshrc 中取消这一行的注释
   export no_proxy=localhost,127.0.0.1,localaddress,.localdomain.com,10.0.0.0/8
   ```

### 问题 2：sync-proxy 命令不存在

**现象：**
```
command not found: sync-proxy
```

**解决方案：**

1. 确认脚本已创建：
   ```bash
   ls -la ~/sync-proxy-config.sh
   ```

2. 重新加载配置：
   ```bash
   source ~/.zshrc
   ```

3. 直接运行脚本：
   ```bash
   bash ~/sync-proxy-config.sh
   ```

### 问题 3：VSCode/Cursor 插件下载失败

**可能原因：**
- 编辑器配置未同步
- 编辑器未重新加载

**解决方案：**

1. 运行同步命令：
   ```bash
   sync-proxy
   ```

2. 重新加载编辑器窗口：
   - `Cmd+Shift+P` → `Reload Window`

3. 检查配置文件：
   ```bash
   cat ~/.cursor-server/data/Machine/settings.json
   cat ~/.vscode-server/data/Machine/settings.json
   ```

### 问题 4：部分内网地址无法访问

**现象：**
校园网认证、内网服务等无法访问

**解决方案：**

启用 `no_proxy` 配置，排除内网地址段：

```bash
export no_proxy=localhost,127.0.0.1,localaddress,.localdomain.com,10.0.0.0/8
```

并在编辑器配置中同样添加（脚本已自动处理）。

---

## 配置文件位置

### 终端配置

- **Zsh**: `~/.zshrc`
- **Bash**: `~/.bashrc`

### 编辑器配置

- **Cursor**: `~/.cursor-server/data/Machine/settings.json`
- **VSCode**: `~/.vscode-server/data/Machine/settings.json`

### 同步脚本

- **位置**: `~/sync-proxy-config.sh`
- **别名**: `sync-proxy`

---

## 最佳实践

### ✅ 推荐做法

1. **统一管理**：只修改 `~/.zshrc` 中的 `PROXY_HOST`
2. **及时同步**：修改后立即运行 `sync-proxy`
3. **版本控制**：将配置文件纳入版本控制（注意敏感信息）
4. **文档记录**：记录常用的代理地址

### ❌ 避免的做法

1. **不要直接修改编辑器配置文件**（会被 sync-proxy 覆盖）
2. **不要在多处维护代理配置**（容易不同步）
3. **不要忘记重新加载**（配置不会自动生效）

---

## 附录

### A. 完整设置示例

```bash
# 1. 编辑 ~/.zshrc
vim ~/.zshrc
# 添加本文档中的配置内容

# 2. 创建同步脚本
cat > ~/sync-proxy-config.sh << 'EOF'
# [脚本内容见上文]
EOF
chmod +x ~/sync-proxy-config.sh

# 3. 重新加载配置
source ~/.zshrc

# 4. 同步到编辑器
sync-proxy

# 5. 验证配置
echo "终端代理: $http_proxy"
cat ~/.cursor-server/data/Machine/settings.json
```

### B. 常用代理端口

| 协议 | 默认端口 | 说明 |
|-----|---------|-----|
| HTTP | 7890 | HTTP 代理 |
| HTTPS | 7890 | HTTPS 代理 |
| SOCKS5 | 7891 | SOCKS5 代理 |
| HTTP (本配置) | 7897 | 自定义端口 |

### C. 环境变量说明

| 变量名 | 作用 | 示例 |
|-------|------|------|
| `PROXY_HOST` | 代理服务器地址 | `10.106.1.36` |
| `PROXY_PORT` | 代理服务器端口 | `7897` |
| `http_proxy` | HTTP 请求代理 | `http://${PROXY_HOST}:${PROXY_PORT}` |
| `https_proxy` | HTTPS 请求代理 | `http://${PROXY_HOST}:${PROXY_PORT}` |
| `all_proxy` | SOCKS5 代理 | `socks5://${PROXY_HOST}:${PROXY_PORT}` |
| `no_proxy` | 不走代理的地址 | `localhost,127.0.0.1,10.0.0.0/8` |

---

## 更新日志

- **2025-11-13**: 初始版本
  - 创建统一代理配置方案
  - 支持终端、VSCode、Cursor
  - 实现一键同步功能

---

## 许可证

此配置方案可自由使用和修改。

---

**最后更新**: 2025-11-13
**适用系统**: Ubuntu 22.04 LTS (其他 Linux 发行版也适用)
**Shell**: Zsh / Bash

