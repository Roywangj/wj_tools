# 开发机反向连接：从云端开发机回连本地 Mac 及其可达服务器

> 目标：人在**云端开发机（VM）**上时，能反向 `ssh` 回到**本地 Mac**，进而借 Mac 的网络访问那些**只有 Mac 能到的私网实验室服务器**。
>
> 适用机器：本地 `roywangjdeMacBook-Air.local`（用户 `roywangj`）；云端 `noban-vm-211862-417f08`。
> 最后更新：2026-07-07。

---

## 一、场景与两个目标

平时是 **Mac → VM** 单向连接（`ssh noban-vm-211862-417f08`）。现在想反过来：

1. **在 VM 上访问 Mac**——拿到 Mac 的 shell。
2. **在 VM 上访问「Mac 能访问的服务器」**——实验室那批 `10.106.x` / `172.25.x` / `192.168.x` 私网机器。

这两个目标用**同一条反向隧道**就能一起满足：只要回到 Mac 的 shell，你就「等同于在 Mac 上操作」，Mac 现成的 `~/.ssh/config`、各服务器密钥、私网路由全部继承，直接 `ssh 3090server2` 之类即可。

---

## 二、网络拓扑与关键约束

```
   Mac (roywangj)                relay-ctrl.claude-noban.online:10041          VM (noban-vm-211862-417f08, root)
   本地/私网可达                        （中继，仅传输层）                         公有云，无私网路由
        │                                                                              │
        │ ──────── ssh 正向连接（日常）────────────────────────────────────────────▶ │
        │                                                                              │
   实验室私网服务器
   10.106.x / 172.25.x / 192.168.x
   （只有 Mac 能路由到）
```

**两个必须知道的约束：**

1. **连 VM 走中继，不是直连。** Mac 上别名 `noban-vm-211862-417f08` 实际指向 `relay-ctrl.claude-noban.online:10041`（root，密钥 `~/.ssh/noban-vm-211862-417f08.pem`），定义在 `~/.ssh/config.d/noban-vm-211862-417f08`。中继只是传输层，不影响隧道。
2. **VM 到不了实验室私网。** VM 是公有云机器，没有到 `10.106.x` 等私网的路由。所以"在 VM 上直接 `ssh` 实验室服务器"（哪怕转发了 ssh-agent）也连不通——**唯一可行路径是先回到 Mac，借 Mac 的网络出去**。

---

## 三、原理：为什么用反向隧道（`RemoteForward`）

SSH 的安全边界是：**服务端默认无法反向钻进客户端**，除非客户端在连接时主动开一个反向端口。

`RemoteForward 2222 127.0.0.1:22` 的含义：Mac 在连上 VM 的这条 SSH 会话里，请求 VM 侧监听 `127.0.0.1:2222`，并把到达该端口的流量**回送到 Mac 自己的 `127.0.0.1:22`（即 Mac 的 sshd）**。于是在 VM 上 `ssh -p 2222 roywangj@localhost` 就等于连回了 Mac。

前提：**Mac 的「远程登录 (sshd)」要开着**（`系统设置 → 通用 → 共享 → 远程登录`）。本机已开启。

---

## 四、已落地配置（Mac 侧）

Mac 的 `~/.ssh/config` 顶部已包含：

```sshconfig
Include config.d/noban-*
```

在 `~/.ssh/config.d/noban-vm-211862-417f08` 中，除日常连接别名外，已新增一个**独立的隧道专用别名** `noban-vm-rtun`：

```sshconfig
Host noban-vm-rtun
    HostName relay-ctrl.claude-noban.online
    Port 10041
    User root
    IdentityFile ~/.ssh/noban-vm-211862-417f08.pem
    IdentitiesOnly yes
    ServerAliveInterval 30
    ServerAliveCountMax 3
    TCPKeepAlive yes
    StrictHostKeyChecking accept-new
    RemoteForward 2222 127.0.0.1:22
    ExitOnForwardFailure yes
```

权限要求：

```bash
chmod 700 ~/.ssh ~/.ssh/config.d
chmod 600 ~/.ssh/config ~/.ssh/config.d/noban-vm-211862-417f08
chmod 400 ~/.ssh/noban-vm-211862-417f08.pem
```

> **为什么单独建别名，不直接改 `noban-vm-211862-417f08`？**
> 日常连接、以及 atimes 目录挂载可能都复用主别名；若把 `RemoteForward 2222` 加在主别名上，多条并发连接会抢同一个 2222 端口。独立别名只负责反向隧道，日常 SSH 与挂载互不干扰。

---

## 五、已落地配置（VM 侧）

VM 上已生成一把**只用于从 VM 通过反向隧道登录 Mac** 的专用 key：

```bash
/root/.ssh/id_ed25519_mac_rtun
/root/.ssh/id_ed25519_mac_rtun.pub
```

VM 上已新增别名 `/root/.ssh/config.d/mac-via-rtun`：

```sshconfig
Host mac-via-rtun
    HostName 127.0.0.1
    Port 2222
    User roywangj
    IdentityFile /root/.ssh/id_ed25519_mac_rtun
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    ServerAliveInterval 30
    ServerAliveCountMax 3
```

VM 的 `/root/.ssh/config` 已包含：

```sshconfig
Include config.d/*
```

因此隧道存在时，VM 上可以直接：

```bash
ssh mac-via-rtun
```

---

## 六、已落地授权（Mac 侧）

Mac 的 `~/.ssh/authorized_keys` 已加入 VM 专用公钥，并限制来源只能是本机 loopback：

```authorized_keys
from="127.0.0.1,::1",restrict,pty ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINV14IwHek/hkTDjG6GN2VVqvqRWal1cteszVZjvY0lm noban-vm-rtun-to-roywangj-mac
```

含义：

- `from="127.0.0.1,::1"`：这把 key 只能从 Mac 看见的本地回环地址登录。经 `RemoteForward` 回来的连接正好会表现为 `127.0.0.1` / `::1`。
- `restrict,pty`：默认禁用额外能力，只重新允许交互 shell 所需的 pty。
- 这把 key 不适合拿去别处直接登录 Mac；离开反向隧道路径会被 `from=` 拒绝。

权限要求：

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

---

## 七、启动、使用与验证

当前已启动后台隧道：

```bash
ssh -fN -o BatchMode=yes -o ConnectTimeout=12 noban-vm-rtun
```

检查 Mac 侧隧道进程：

```bash
pgrep -lf 'ssh.*noban-vm-rtun|autossh.*noban-vm-rtun'
```

检查 VM 侧 2222 是否已监听：

```bash
ssh noban-vm-211862-417f08 'ss -tlnp | grep -E ":2222\b"'
```

在 VM 上回到 Mac：

```bash
ssh mac-via-rtun
```

在 VM 上借 Mac 跳到下游机器：

```bash
ssh -t mac-via-rtun ssh 3090server2
ssh -t mac-via-rtun ssh 10.106.15.178wangjie01
```

已验证链路：

```text
VM -> Mac:
roywangjdeMacBook-Air.local / roywangj

VM -> Mac -> 3090server2:
user-Super-Server / user

VM -> Mac -> 10.106.15.178wangjie01:
ubuntu / wangjie01
```

注意：`10.106.15.178` 这个主别名自带 `RemoteForward 15140`，嵌套测试时可能与已有转发冲突；需要纯登录时优先用无该转发的 `10.106.15.178wangjie01`。

---

## 八、本地如何查看哪些隧道开着

在 Mac 本地可以从三层看：SSH 进程、展开后的 SSH 配置、以及本地/远端监听端口。

### 8.1 看当前所有 SSH / autossh 进程

```bash
ps -axo pid,ppid,etime,command | grep -E 'ssh|autossh' | grep -v grep
```

当前这类输出里，重点看命令名：

```text
ssh -fN ... noban-vm-rtun          # 反向隧道，开着
ssh noban-vm-211862-417f08         # 普通 SSH 会话
```

更精确地只看这条反向隧道：

```bash
pgrep -lf 'ssh.*noban-vm-rtun|autossh.*noban-vm-rtun'
```

有输出表示 Mac 侧隧道进程还活着；无输出表示这条隧道已关闭。

### 8.2 看这个别名配置了哪些转发

```bash
ssh -G noban-vm-rtun | grep -E '^(hostname|port|user|remoteforward|localforward|dynamicforward)'
```

当前应能看到：

```text
remoteforward 2222 [127.0.0.1]:22
```

意思是：VM 侧 `127.0.0.1:2222` 会通过这条 SSH 会话回连到 Mac 侧 `127.0.0.1:22`。

### 8.3 看本机监听型隧道

本地 `ssh -L` / `ssh -D` 会在 Mac 上打开监听端口，可以这样看：

```bash
lsof -nP -iTCP -sTCP:LISTEN | grep -E 'ssh|autossh'
```

注意：`noban-vm-rtun` 是 `RemoteForward`，监听端口开在 VM 上，不在 Mac 上。因此 Mac 本地 `LISTEN` 里通常看不到 `2222`。

### 8.4 看当前 SSH 连接

```bash
lsof -nP -iTCP -sTCP:ESTABLISHED | grep -E 'ssh|autossh|relay-ctrl|157\.230\.46\.220|:10041|:22'
```

如果走 Clash/TUN，远端可能显示为 `198.18.x.x:10041`；这表示流量被本地代理层接管，不一定会显示真实 relay IP。

### 8.5 反向隧道必须到 VM 上看监听端口

```bash
ssh noban-vm-211862-417f08 'ss -tlnp | grep -E ":2222\b"'
```

如果看到：

```text
127.0.0.1:2222
[::1]:2222
```

说明 VM 侧回连 Mac 的入口正在监听。

一条命令做快速检查：

```bash
pgrep -lf 'ssh.*noban-vm-rtun|autossh.*noban-vm-rtun' \
  && ssh noban-vm-211862-417f08 'ss -tlnp | grep -E ":2222\b"'
```

也可以直接运行已封装脚本：

```bash
/Users/roywangj/Desktop/wj_tools/proxy-setup-guide/check-ssh-rtun.sh
```

---

## 九、Mac 如何感知谁连进来了

Mac 可以感知“有 SSH 登录到本机”，但经反向隧道进来的连接，Mac 看到的来源通常是 `127.0.0.1` / `::1`，不是 VM 上具体哪个人。

常用检查：

```bash
# 当前登录会话
who

# sshd 相关进程
ps aux | grep 'sshd:' | grep -v grep

# 当前直连到 Mac sshd(22) 的 TCP 连接
lsof -nP -iTCP:22 -sTCP:ESTABLISHED

# macOS 统一日志中的 sshd 记录
log show --last 1h --predicate 'process == "sshd"' --style compact
```

边界：

- Mac 能看到登录用户是 `roywangj`，也能看到来源是 loopback。
- Mac 默认**不能可靠区分 VM 上是谁发起的**，因为所有人若能用 VM 的专用私钥或 Mac 登录密码通过 `127.0.0.1:2222` 进入，在 Mac 看起来都是同一条反向隧道路由。
- 若需要可审计到个人，需要为 VM 上不同使用者分配不同 key，或不要把登录 Mac 的私钥放在 VM 的 root 可读位置。

---

## 十、安全边界与关停

关键结论：

- **隧道活着时**：VM 的 root、以及任何能在 VM 上读取 `/root/.ssh/id_ed25519_mac_rtun` 的人，都可以在 VM 上执行 `ssh mac-via-rtun` 进入 Mac。
- **隧道活着时，VM 上其它本地用户也能连接到 `127.0.0.1:2222` 这个端口**；他们没有 `/root` 私钥通常无法免密登录，但如果知道 Mac 账户密码且 Mac sshd 允许密码登录，也可能通过密码进入。
- **隧道不活着时**：VM 上没有 `127.0.0.1:2222` 这条入口，这把 key 又被 Mac 限制为只能从 `127.0.0.1/::1` 使用，因此这条路径不能进 Mac。
- 普通日常 `ssh noban-vm-211862-417f08` 不会自动开启回连能力；只有 `ssh -N noban-vm-rtun` / `autossh ... noban-vm-rtun` 这类带 `RemoteForward` 的会话会开启。

临时关闭：

```bash
pkill -f 'ssh.*noban-vm-rtun'
```

确认已关闭：

```bash
pgrep -lf 'ssh.*noban-vm-rtun|autossh.*noban-vm-rtun' || echo closed
ssh noban-vm-211862-417f08 'ss -tlnp | grep -E ":2222\b" || echo no-2222'
```

彻底移除：

1. 删除 Mac `~/.ssh/config.d/noban-vm-211862-417f08` 中的 `Host noban-vm-rtun` 段。
2. 删除 Mac `~/.ssh/authorized_keys` 中 `noban-vm-rtun-to-roywangj-mac` 那一行。
3. 删除 VM 上 `/root/.ssh/id_ed25519_mac_rtun*` 和 `/root/.ssh/config.d/mac-via-rtun`。

---

## 十一、故障排查

| 现象 | 原因 / 排查 |
|---|---|
| Mac 上启动隧道时报 `remote port forwarding failed for listen port 2222` | VM 的 2222 已被另一条连接占用。确认没有第二个隧道在抢；或换一个端口，同时改 `RemoteForward` 与 VM 的 `mac-via-rtun` 端口。 |
| VM 上 `ssh mac-via-rtun` 报 `Connection refused` | 隧道没起来，或 VM 侧 2222 没监听。先查 Mac 隧道进程，再查 VM 上 `ss -tlnp | grep 2222`。 |
| VM 上 `ssh mac-via-rtun` 报 `Permission denied` | Mac 的 `authorized_keys` 未写入 VM 公钥、权限不对，或不是从 loopback 进入导致 `from=` 拒绝。 |
| VM 上能进 Mac，但 `ssh 3090server2` 连不上 | 说明不是反向隧道问题，是 Mac 到该服务器本身的路由、VPN 或密钥问题。在 Mac 本地直接测同一命令。 |
| 隧道频繁掉线 | 用 `autossh -M 0 -f -N noban-vm-rtun` 自动重连；当前 SSH 配置已有 `ServerAliveInterval 30`。 |

更强收敛入口：如果不希望 VM 上任何人尝试 Mac 密码登录，需要在 Mac 的 sshd 配置中禁用密码登录或做更细的 `Match` 限制；这会影响其它 SSH 登录方式，改之前要先确认已有 key 登录可用。

---

## 十二、一句话速查

```bash
# Mac：后台启动隧道
ssh -fN noban-vm-rtun

# VM：回 Mac
ssh mac-via-rtun

# VM：借 Mac 去下游
ssh -t mac-via-rtun ssh 3090server2
```
