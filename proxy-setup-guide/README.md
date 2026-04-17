# 统一代理配置方案

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash%2FZsh-green.svg)](https://www.gnu.org/software/bash/)

一个简单高效的方案，让终端、VSCode 和 Cursor 都使用相同的代理配置，**修改一处即可全局生效**。

除了默认的**局域网固定代理机**方案外，本文档也补充了一个适用于远程服务器场景的**本地转发**方案：通过 SSH `RemoteForward` 让服务器复用本地电脑上的代理。

## ✨ 特性

- 🎯 **统一管理**：所有代理配置集中在一处
- 🔄 **一键同步**：自动同步到 VSCode 和 Cursor
- ⚡ **灵活配置**：支持自定义代理地址和端口
- 🛠️ **易于使用**：简单的命令行操作
- 📦 **无依赖**：纯 Shell 脚本实现

## 🚀 快速开始

### 1. 安装配置

将以下内容添加到您的 `~/.zshrc` 或 `~/.bashrc` 文件末尾：

```bash
# ==================== 代理配置 ====================
# 第一步：两种切换入口（端口各自指定，避免与其他同学冲突）
function proxy_lab() {    # 走实验室代理机（LAN 固定网关）
    export PROXY_HOST="10.106.1.36"                  # 修改为您的 LAN 代理地址
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

    # 内网/本地地址直连（避免校园网认证等被代理拦截）
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
#   2) 服务器能否直连 127.0.0.1:$PROXY_PORT 的本地 Clash
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
alias sync-proxy='~/wj_tools/proxy-setup-guide/sync-proxy-config.sh'
# 一键体检：打印当前终端代理变量 + 编辑器 settings.json 内容
alias echo-proxy='~/wj_tools/proxy-setup-guide/echo_proxy.sh'

# ---------------------------------------------------------------
# 第四步：默认登录时走哪条线路？（二选一，取消对应行前的 # 即可）
#
#   - proxy_lab   ：走实验室代理机（LAN 固定网关，断线不影响后台任务）
#   - proxy_local ：走本机代理（需本地 ~/.ssh/config 配 RemoteForward）
# ---------------------------------------------------------------
proxy_lab
# proxy_local

# 第五步：登录时自动同步代理到编辑器，并打印一次体检信息（不想要就注释掉）
sync-proxy >/dev/null
echo-proxy
```

> **说明**
> - `proxy_lab` / `proxy_local` / `proxy_off` 三个入口随时可调用，同一时间只有一套生效，切换即刻覆盖。
>   - `proxy_lab`：走实验室/LAN 上固定的代理机（默认方案）。
>   - `proxy_local`：走本机代理（本地转发方案），需先在**本地电脑**配置 SSH 隧道（见下方）。
>   - `proxy_off`：关闭代理并清除 Git 全局代理。
> - 默认启用 `proxy_lab` + 自动 `sync-proxy`，每次新开 shell 会把当前代理地址同步到 VSCode/Cursor 的 `settings.json`，切换成 `proxy_local` 后也能自动同步。
> - `no_proxy` 默认包含 `10.0.0.0/8`，校园网认证（如访问 `10.0.0.55`）不会被代理拦截。

#### 启用 `proxy_local` 需要的本地 SSH 配置

`proxy_local` 的原理是把服务器上的一个端口反向转发到你**本地电脑**的 Clash 端口，让服务器通过 SSH 隧道复用本机代理。本仓库默认约定：

| 位置 | 端口 | 含义 |
|---|---|---|
| 本地电脑 Clash 监听 | `7897` | 你本机代理软件原本的端口，**保持不动** |
| 服务器端隧道监听 | `5140` | SSH 在服务器开出的端口，避开公共 `7897`（可能被同学占用） |

`RemoteForward` 语法是 `RemoteForward <服务器端口> <本地地址>:<本地端口>`，两个端口**相互独立**，不必一致。

启用步骤（一次性）：

1. 确认本地代理软件（Clash / V2Ray 等）正在监听 `127.0.0.1:7897`。

2. 在**本地电脑**打开 `~/.ssh/config`，在对应主机条目下加一行 `RemoteForward`：

   ```sshconfig
   Host my-server              # 替换为你的 Host 别名
       HostName 10.106.x.x     # 原有字段保持不变
       User your-user
       RemoteForward 5140 127.0.0.1:7897
       #             ↑           ↑
       #      服务器端口(5140)  本机 Clash 端口(7897)
       ExitOnForwardFailure yes     # 隧道建不起来就直接报错，不让你以为连上了其实没代理
       ServerAliveInterval 60       # 每 60s 发心跳，断线能及时发现
       ServerAliveCountMax 3        # 连续 3 次心跳丢失判定断开
   ```

   三项附加选项的作用：`ExitOnForwardFailure yes` 让 `RemoteForward` 失败时立刻退出，避免「SSH 连上了但隧道没建起来」的静默陷阱；`ServerAliveInterval 60` + `ServerAliveCountMax 3` 每 60s 发心跳，连续丢 3 次（≈3 分钟）判定断开，防止半死连接继续占着服务器端口。

3. 断开并**重新 SSH 登录**服务器（VSCode Remote SSH 也要 Reload Window / 重连），让隧道生效。登录时若看到 `Warning: remote port forwarding failed for listen port 5140`，说明 5140 也被占了，换一个高端口（如 `15140`、`25140`）并同步改 `.zshrc` 里 `proxy_local` 的 `PROXY_PORT`。

4. 登录后在服务器执行 `proxy_local`，或把 `.zshrc` 第四步切换成 `proxy_local` 作为默认线路。

> 检查隧道是否建立（服务器端）：`ss -tlnp | grep 5140` 应能看到 5140 端口被监听。若看不到，回本地 `~/.ssh/config` 确认那行 `RemoteForward` 已加且已重新登录。

完整说明见：[服务器使用本地代理](./服务器使用本地代理.md)

### 2. 设置脚本权限

```bash
chmod +x ~/wj_tools/proxy-setup-guide/sync-proxy-config.sh
chmod +x ~/wj_tools/proxy-setup-guide/echo_proxy.sh
```

### 3. 重新加载配置

```bash
source ~/.zshrc  # 或 source ~/.bashrc
```

### 4. 同步到编辑器

```bash
sync-proxy
```

## 📖 切换 / 禁用代理

```bash
# 切换线路
proxy_lab      # 走实验室代理机（10.106.1.36:7897）
proxy_local    # 走本机代理（需先配好 SSH RemoteForward）

# 关闭代理（同时清掉 Git 全局代理）
proxy_off

# 或：手动 unset（只清环境变量，不影响 Git 配置）
unset http_proxy https_proxy all_proxy

# 体检：一眼看全终端代理变量 + 编辑器 settings.json
echo-proxy
```

> 切换线路后习惯性跑一下 `echo-proxy`，能立刻确认 `proxy_*` 函数是否生效、`sync-proxy` 是否把新地址同步到了 VSCode/Cursor。

## 🧪 代理链路自检（`proxy_test`）

上面 `.zshrc` 片段里内置了一个三段式自检函数 `proxy_test`，用于在「代理不通」时快速定位问题出在哪一层：

```bash
proxy_test
```

它会依次检查：

1. **隧道监听**：`proxy_local` 模式下看服务器 `$PROXY_PORT` 是否确实被 SSH `RemoteForward` 打开（否则多半是本地 `~/.ssh/config` 没生效或重连前的会话没断开）。
2. **代理点对点可达**：用 `curl -x http://$PROXY_HOST:$PROXY_PORT` 直连代理访问 Google，跳过 shell 变量干扰——这一步失败说明**代理本身**有问题。
3. **当前 shell 环境变量**：用 `http_proxy` 打一次请求并打印出口 IP（`ipinfo.io/ip`），验证 `proxy_lab` / `proxy_local` 是否已经注入环境变量。

> 推荐测试节奏：新登录服务器 → `proxy_lab`（或 `proxy_local`） → `proxy_test` 一次过三关 → 再安心跑训练 / `apt` / `pip`。
> 如果你对应的 `Host` 里加了 `ExitOnForwardFailure yes`，第 1 步失败通常会直接让 SSH 登录失败，不再出现「连上了但没代理」的假象。

#### 不用 `proxy_test` 的手动三步

在没有 `proxy_test` 函数的环境（比如刚 clone 下来还没 `source ~/.zshrc`），可以直接敲下面三条命令，效果等价：

```bash
# 1) 隧道是否在服务器端监听
ss -tlnp | grep 5140   # 看到 5140 说明 SSH RemoteForward 生效

# 2) 服务器能否打到本地 Clash
curl -x http://127.0.0.1:5140 -I https://www.google.com

# 3) 终端代理变量是否走通
proxy_on && curl -I https://www.google.com
```

## 🧩 补充方案：本地转发（服务器复用本地代理）

当你使用 VSCode Remote SSH 连接远程服务器，且代理只在本地电脑可用时，可以使用这个补充方案。

它的核心思路是：

1. 在本地 SSH 配置中添加 `RemoteForward`，把服务器的 `7897` 端口转发到本地 `127.0.0.1:7897`
2. 在服务器上把 `PROXY_HOST` 改为 `127.0.0.1`
3. 通过 `proxy_on` / `proxy_off` 控制终端和 Git 是否走代理

示例 SSH 配置：

```sshconfig
Host my-server
    RemoteForward 7897 127.0.0.1:7897
    ExitOnForwardFailure yes     # 隧道建不起来就直接报错，不让你以为连上了其实没代理
    ServerAliveInterval 60       # 每 60s 发心跳，断线能及时发现
    ServerAliveCountMax 3        # 连续 3 次心跳丢失判定断开
```

服务器上的核心代理配置：

```bash
export PROXY_HOST="127.0.0.1"
export PROXY_PORT="7897"
export PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
```

这个方案是对原有统一代理配置的补充，适合“服务器本身无法直接访问代理，但本地电脑可以”的情况。

完整说明见：[服务器使用本地代理](./服务器使用本地代理.md)

## 🆚 两种方案对比（局域网固定代理机 vs 本地转发）

局域网固定代理机方案已经引入了 `proxy_on` / `proxy_off` 开关函数、Git 全局代理联动、`no_proxy` 默认值等能力，和本地转发方案的差异已经收敛到**代理链路**和**适用场景**本身。

### 差异总表

| 维度 | 局域网固定代理机（`proxy-setup-guide.md`） | 本地转发（`服务器使用本地代理.md`） |
|---|---|---|
| **代理位置** | 局域网一台固定代理机（如 `10.106.1.36:7897`） | **你本地电脑** 的 `127.0.0.1:7897`，经 SSH 隧道反向转发 |
| **`PROXY_HOST`** | 远端 LAN IP | `127.0.0.1` |
| **前置要求** | 代理机与服务器同网段可达 | 本地 `~/.ssh/config` 必须配 `RemoteForward 7897 127.0.0.1:7897` |
| **默认是否开代理** | 开（`.zshrc` 末尾调用 `proxy_on`） | 关（末尾 `# proxy_on` 被注释） |
| **`all_proxy` 协议** | `socks5://...` | `http://...` |
| **VSCode/Cursor 插件同步** | ✅ 有 `sync-proxy` 脚本写 `settings.json` | ❌ 只管终端 |
| **脱离 SSH 会话后代理是否可用** | ✅ 可用，代理机独立运行 | ❌ 不可用，隧道随 SSH 断开失效 |
| **典型适用场景** | 实验室/公司内网有常驻代理网关；多人共用；需要跑后台长任务 | 出差/异地连服务器；服务器网段无代理，但本地有 |

### 已经拉平的能力

- `proxy_on` / `proxy_off` 开关函数结构
- Git 全局代理在 `proxy_on/off` 里自动写入/清除
- `no_proxy` 默认含 `localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,*.local`（校园网认证等内网请求不会被拦）
- `PROXY_HOST` / `PROXY_PORT` / `PROXY_URL` 三层变量定义

### 最本质的取舍：代理在哪里

- 代理在**局域网一台独立机器**上 → 局域网固定代理机方案。优点是不依赖你 SSH 会话活着，服务器上的后台任务（训练、`wandb` 上传、`apt` 更新）在你合盖断线后仍可走代理。
- 代理**只在你本地笔记本**上 → 本地转发方案。优点是零额外部署，换任何服务器、任何网络都能立即用，代理凭据也不离开本机。

### 场景决策

| 场景 | 选哪个 |
|---|---|
| 实验室有共享代理网关 + 多人共用服务器 | 局域网固定代理机 |
| 服务器跑长任务，需要合盖后继续联网 | 局域网固定代理机 |
| 服务器在云上/外网，附近没代理机 | 本地转发 |
| 出差/临时异地连服务器 | 本地转发 |
| 两种场景都有 | **两套并存**：在 `.zshrc` 里多写一对函数（例如 `proxy_lab` 和 `proxy_local`），按需切换 |

### 两种方案共存的最小改造

如果你两种场景都有，可以把 `.zshrc` 改成下面这样——同一时间只有一套生效，切换即刻覆盖，互不冲突：

```bash
export PROXY_PORT="7897"

function proxy_lab() {    # 走实验室代理机
    export PROXY_HOST="10.106.1.36"
    export PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
    _proxy_apply
}

function proxy_local() {  # 走本机代理（经 SSH 隧道）
    export PROXY_HOST="127.0.0.1"
    export PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
    _proxy_apply
}

function _proxy_apply() {
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    export all_proxy="socks5://${PROXY_HOST}:${PROXY_PORT}"
    git config --global http.proxy  "$PROXY_URL"
    git config --global https.proxy "$PROXY_URL"
    export no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,*.local"
    echo "代理已切换到 $PROXY_URL"
}

function proxy_off() {
    unset http_proxy https_proxy all_proxy
    git config --global --unset http.proxy  2>/dev/null
    git config --global --unset https.proxy 2>/dev/null
    echo "代理已关闭"
}

proxy_lab   # 默认登录时走实验室代理
```

## 🔗 补充方案：Chain Proxy（机场 + 静态住宅代理）

如果你需要先通过机场节点出站，再把特定流量切到静态住宅代理，可以使用这个补充方案。

它适用于 Clash 场景，核心思路是：

1. 保留现有机场节点作为基础出口
2. 新增一个静态住宅代理节点
3. 在 `proxy-groups` 和 `rules` 中把目标流量切到住宅代理

不同版本的 Clash 配置方式略有区别：旧版通常需要 `dialer-proxy`，新版 Clash `2.4.7` 的记录配置不需要 `dialer-proxy`，但需要显式设置 `udp: true`。

完整说明见：[Chain Proxy 配置说明](./chainproxy.md)

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| `sync-proxy-config.sh` | 代理同步脚本（终端代理 → VSCode/Cursor `settings.json`） |
| `echo_proxy.sh` | 代理状态体检脚本（`echo-proxy` 别名调用）|
| `proxy-setup-guide.md` | [完整配置指南](./proxy-setup-guide.md) |
| `服务器使用本地代理.md` | [服务器复用本地代理的补充方案](./服务器使用本地代理.md) |
| `chainproxy.md` | [机场节点串联静态住宅代理的补充说明](./chainproxy.md) |
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
- [服务器使用本地代理](./服务器使用本地代理.md) - 通过 SSH `RemoteForward` 让远程服务器复用本地代理


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
bash ~/wj_tools/proxy-setup-guide/sync-proxy-config.sh
```



## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

[MIT License](LICENSE)

## 🙏 致谢

感谢所有贡献者的支持！

- 本地转发部分思路感谢 [@laprf](https://github.com/laprf)。

---

**系统要求**
- Linux / macOS
- Bash / Zsh
- VSCode / Cursor (可选)

**最后更新**: 2026-03-06
