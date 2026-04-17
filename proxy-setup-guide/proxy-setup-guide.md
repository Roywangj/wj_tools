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
# 第一步：两种切换入口（端口各自指定，避免与其他同学冲突）
function proxy_lab() {    # 走实验室代理机（LAN 固定网关）
    export PROXY_HOST="10.106.1.36"
    export PROXY_PORT="7897"                         # 实验室代理机监听端口
    export PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
    _proxy_apply
}

function proxy_local() {  # 走本机代理（经 SSH RemoteForward 隧道）
    export PROXY_HOST="127.0.0.1"
    export PROXY_PORT="5140"                         # 服务器端隧道监听端口，避让公共 7897
    export PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
    _proxy_apply
}

# 第三步：内部函数，实际下发环境变量 / Git 配置 / no_proxy
function _proxy_apply() {
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    export all_proxy="socks5://${PROXY_HOST}:${PROXY_PORT}"

    # Git 全局代理
    git config --global http.proxy  "$PROXY_URL"
    git config --global https.proxy "$PROXY_URL"

    # 内网/本地地址直连，避免校园网认证等被拦
    export no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,*.local"

    echo "代理已切换到 $PROXY_URL"
}

function proxy_off() {
    unset http_proxy https_proxy all_proxy
    git config --global --unset http.proxy  2>/dev/null
    git config --global --unset https.proxy 2>/dev/null
    echo "代理已关闭"
}

# 第三步半：代理链路三段式自检
#   1) SSH RemoteForward 服务器端是否在监听
#   2) 服务器能否直连 $PROXY_HOST:$PROXY_PORT 的代理
#   3) 当前 shell 的 http_proxy 环境变量是否能打通外网
function proxy_test() {
    echo "==== [1/3] 隧道监听检测 ($PROXY_HOST:$PROXY_PORT) ===="
    if [[ "$PROXY_HOST" == "127.0.0.1" ]]; then
        ss -tln 2>/dev/null | grep -E "[:.]${PROXY_PORT}\b" \
            && echo "✅ 端口 $PROXY_PORT 正在监听" \
            || echo "❌ 端口 $PROXY_PORT 未监听（检查本地 ~/.ssh/config 的 RemoteForward 是否生效）"
    else
        echo "↪ 非本地转发模式，跳过隧道检测"
    fi

    echo "==== [2/3] 代理点对点可达 ===="
    curl -x "http://${PROXY_HOST}:${PROXY_PORT}" -sS -o /dev/null -m 8 \
         -w "HTTP %{http_code}  耗时 %{time_total}s\n" https://www.google.com \
         && echo "✅ 代理能打通 Google" || echo "❌ 代理无法访问外网"

    echo "==== [3/3] 当前 shell 环境变量 ===="
    if [[ -n "$http_proxy" ]]; then
        curl -sS -o /dev/null -m 8 \
             -w "HTTP %{http_code}  出口 IP 检测见下行\n" https://www.google.com \
             && curl -sS -m 8 https://ipinfo.io/ip && echo
    else
        echo "⚠ 当前 shell 未设置 http_proxy，可先执行 proxy_lab / proxy_local"
    fi
}

# 同步代理配置到 VSCode/Cursor 的别名（被下方自动同步以及手动调用复用）
alias sync-proxy='~/sync-proxy-config.sh'

# ---------------------------------------------------------------
# 第四步：默认登录时走哪条线路？（二选一，取消对应行前的 # 即可）
#
#   - proxy_lab   ：走实验室代理机（LAN 固定网关，断线不影响后台任务）
#   - proxy_local ：走本机代理（需本地 ~/.ssh/config 配 RemoteForward）
# ---------------------------------------------------------------
proxy_lab
# proxy_local

# 第五步：把当前代理同步到 VSCode/Cursor（不想每次启动都跑可注释掉）
sync-proxy >/dev/null
```

**说明：**
- `PROXY_PORT`：本地与实验室代理机复用的监听端口（**可自定义**）。
- `proxy_lab` / `proxy_local` / `proxy_off`：三个入口随时可调用，同一时间只有一套生效，切换即刻覆盖。
  - `proxy_lab`：走实验室/LAN 上固定的代理机（默认方案）。
  - `proxy_local`：走本机代理（本地转发方案），需配合本地 `~/.ssh/config` 的 `RemoteForward 7897 127.0.0.1:7897`。
  - `proxy_off`：关闭代理并清除 Git 全局代理。
- 默认启用 `proxy_lab` + 自动 `sync-proxy`，每次新开 shell 会把当前代理地址同步到 VSCode/Cursor 的 `settings.json`；切换到 `proxy_local` 后下次启动也会自动同步。
- `no_proxy` 默认包含 `10.0.0.0/8`，校园网认证（如 `10.0.0.55`）不会被代理拦截。
- `sync-proxy`：快捷命令，也可随时手动调用。
- `proxy_test`：三段式自检（隧道监听 / 代理点对点 / 当前 shell 变量），代理不通时一条命令定位问题层。

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

#### 代理链路自检（`proxy_test`）

上面 `.zshrc` 片段里内置了一个三段式自检函数 `proxy_test`，用于在「代理不通」时快速定位问题出在哪一层：

```bash
proxy_test
```

它依次检查：

1. **隧道监听**：`proxy_local` 模式下看服务器 `$PROXY_PORT` 是否确实被 SSH `RemoteForward` 打开。
2. **代理点对点可达**：用 `curl -x http://$PROXY_HOST:$PROXY_PORT` 直连代理访问 Google，跳过 shell 变量干扰——这一步失败说明**代理本身**有问题。
3. **当前 shell 环境变量**：用 `http_proxy` 打一次请求并打印出口 IP（`ipinfo.io/ip`），验证 `proxy_lab` / `proxy_local` 是否已经注入环境变量。

> 推荐节奏：新登录服务器 → `proxy_lab`（或 `proxy_local`）→ `proxy_test` 一次过三关 → 再跑训练 / `apt` / `pip`。

##### 不用 `proxy_test` 的手动三步

没加载 `proxy_test` 时（比如还没 `source ~/.zshrc`），直接敲下面三条命令等价：

```bash
# 1) 隧道是否在服务器端监听
ss -tlnp | grep 5140   # 看到 5140 说明 SSH RemoteForward 生效

# 2) 服务器能否打到本地 Clash
curl -x http://127.0.0.1:5140 -I https://www.google.com

# 3) 终端代理变量是否走通
proxy_on && curl -I https://www.google.com
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

