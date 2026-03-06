# 统一代理配置方案

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash%2FZsh-green.svg)](https://www.gnu.org/software/bash/)

一个简单高效的方案，让终端、VSCode 和 Cursor 都使用相同的代理配置，**修改一处即可全局生效**。

除了默认的统一代理配置外，本文档也补充了一个适用于远程服务器场景的 `laprf` 方案：通过 SSH `RemoteForward` 让服务器复用本地电脑上的代理。

## ✨ 特性

- 🎯 **统一管理**：所有代理配置集中在一处
- 🔄 **一键同步**：自动同步到 VSCode 和 Cursor
- ⚡ **灵活配置**：支持自定义代理地址和端口
- 🛠️ **易于使用**：简单的命令行操作
- 📦 **无依赖**：纯 Shell 脚本实现

## 🚀 快速开始

### 1. 克隆仓库

```bash
git clone <your-repo-url>
cd sync_proxy
```

### 2. 安装配置

将以下内容添加到您的 `~/.zshrc` 或 `~/.bashrc` 文件末尾：

```bash
# ==================== 代理配置 ====================
# 第一步：设置代理主机和端口
PROXY_HOST="10.106.1.36"  # 修改为您的代理地址
PROXY_PORT="7897"         # 修改为您的代理端口

# 第二步：应用代理设置（以下行无需修改）
export http_proxy=http://${PROXY_HOST}:${PROXY_PORT}
export https_proxy=http://${PROXY_HOST}:${PROXY_PORT}
export all_proxy=socks5://${PROXY_HOST}:${PROXY_PORT}
# export no_proxy=localhost,127.0.0.1,localaddress,.localdomain.com,10.0.0.0/8

# 同步代理配置到 VSCode/Cursor
alias sync-proxy='~/sync_proxy/sync-proxy-config.sh'
```

### 3. 设置脚本权限

```bash
chmod +x ~/sync_proxy/sync-proxy-config.sh
```

### 4. 重新加载配置

```bash
source ~/.zshrc  # 或 source ~/.bashrc
```

### 5. 同步到编辑器

```bash
sync-proxy
```

## 📖 使用方法

### 修改代理配置

1. **编辑配置文件**
   ```bash
   vim ~/.zshrc
   ```

2. **修改代理地址/端口**
   ```bash
   PROXY_HOST="新的IP地址"
   PROXY_PORT="新的端口号"
   ```

3. **重新加载配置**
   ```bash
   source ~/.zshrc
   ```

4. **同步到编辑器**
   ```bash
   sync-proxy
   ```

5. **重新加载编辑器窗口**
   - 在 VSCode/Cursor 中按 `Cmd+Shift+P` 或 `Ctrl+Shift+P`
   - 输入 `Reload Window` 并选择

### 临时禁用代理

```bash
# 禁用代理
unset http_proxy https_proxy all_proxy

# 重新启用
source ~/.zshrc
```

## 🧩 补充方案：LAPRF（服务器复用本地代理）

当你使用 VSCode Remote SSH 连接远程服务器，且代理只在本地电脑可用时，可以使用这个补充方案。

它的核心思路是：

1. 在本地 SSH 配置中添加 `RemoteForward`，把服务器的 `7897` 端口转发到本地 `127.0.0.1:7897`
2. 在服务器上把 `PROXY_HOST` 改为 `127.0.0.1`
3. 通过 `proxy_on` / `proxy_off` 控制终端和 Git 是否走代理

示例 SSH 配置：

```sshconfig
Host my-server
    RemoteForward 7897 127.0.0.1:7897
```

服务器上的核心代理配置：

```bash
export PROXY_HOST="127.0.0.1"
export PROXY_PORT="7897"
export PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
```

这个方案是对原有统一代理配置的补充，适合“服务器本身无法直接访问代理，但本地电脑可以”的情况。

完整说明见：[服务器使用本地代理（LAPRF）](./服务器使用本地代理_laprf.md)

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| `sync-proxy-config.sh` | 代理同步脚本 |
| `proxy-setup-guide.md` | [完整配置指南](./proxy-setup-guide.md) |
| `proxy-quick-reference.md` | [快速参考文档](./proxy-quick-reference.md) |
| `服务器使用本地代理_laprf.md` | [服务器复用本地代理的补充方案](./服务器使用本地代理_laprf.md) |
| `.zshrc` | Zsh 配置示例文件 |

## 🎯 工作原理

```
┌─────────────────────────────────────┐
│         ~/.zshrc                    │
│   PROXY_HOST + PROXY_PORT           │
│         (唯一配置源)                 │
└─────────────┬───────────────────────┘
              │
     ┌────────┴────────┐
     ▼                 ▼
┌──────────┐   ┌──────────────┐
│  终端     │   │  sync-proxy   │
│  环境变量 │   │  (同步脚本)    │
└──────────┘   └────────┬──────┘
                        │
                   ┌────┴────┐
                   ▼         ▼
              ┌────────┐ ┌────────┐
              │ Cursor │ │ VSCode │
              └────────┘ └────────┘
```

## 🔧 支持的工具

- ✅ 终端命令（curl, wget, git 等）
- ✅ Python requests
- ✅ VSCode 插件
- ✅ Cursor 插件
- ✅ npm/yarn
- ✅ 其他支持 http_proxy 的工具

## 📚 文档

- [完整配置指南](./proxy-setup-guide.md) - 详细的配置说明和故障排除
- [快速参考](./proxy-quick-reference.md) - 常用命令速查
- [服务器使用本地代理（LAPRF）](./服务器使用本地代理_laprf.md) - 通过 SSH `RemoteForward` 让远程服务器复用本地代理


## ⚠️ 注意事项

1. **端口冲突**：确保代理端口未被占用
2. **内网地址**：如需访问内网服务，启用 `no_proxy` 配置
3. **编辑器重载**：修改配置后需要重新加载编辑器窗口

## 🐛 故障排除

### 校园网认证失败（脚本卡死）

**问题**：运行校园网登录脚本时程序卡住，无法连接认证网关（如 `10.0.0.55`）

**原因**：系统代理拦截了对内网认证服务器的请求

**快速解决**：
```bash
export NO_PROXY="10.0.0.55,10.0.0.0/8,localhost,127.0.0.1"
export no_proxy="$NO_PROXY"
```

详见：[校园网认证失败排查与解决](./校园网认证失败.md)

---

### 连接被拒绝

**问题**：`Connection Refused` 错误

**解决**：
- 检查代理服务器是否运行
- 验证 IP 地址和端口是否正确
- 启用 `no_proxy` 排除内网地址

### sync-proxy 命令不存在

**问题**：`command not found: sync-proxy`

**解决**：
```bash
source ~/.zshrc
# 或直接运行
bash ~/sync_proxy/sync-proxy-config.sh
```



## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

[MIT License](LICENSE)

## 🙏 致谢

感谢所有贡献者的支持！

---

**系统要求**
- Linux / macOS
- Bash / Zsh
- VSCode / Cursor (可选)

**最后更新**: 2026-03-06
