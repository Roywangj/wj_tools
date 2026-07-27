# GNU screen + Starship 乱码 / 空心 Powerline 修复

在 **teleai-gpu / 实验室 Linux 服务器** 上：外面（直接 SSH / tmux）的 Starship 花式 prompt 正常，一进 **GNU screen** 就变成：

```text
 root  /data_wj          # 多字节字符碎成 
```

或：

```text
 root /data_wj          # powerline 只剩空心箭头、没有彩色底
```

而 **tmux 往往正常**。本文记录最终可用方案（2026-07 在 teleai-gpu 验证通过）。

相关配置模板见：

| 文件 | 用途 |
|------|------|
| [configs/screenrc](./configs/screenrc) | `~/.screenrc` |
| [configs/starship-screen.toml](./configs/starship-screen.toml) | screen 内 256 色双胞胎主题 |
| [configs/teleai-gpu.zshrc](./configs/teleai-gpu.zshrc) | **完整** teleai `/data_wj/.zshrc` 参考实现（推荐整份对齐） |
| [configs/zshrc-screen-snippet.zsh](./configs/zshrc-screen-snippet.zsh) | 合并进已有 `.zshrc` 的片段（locale / Starship / 补全 / 历史） |
| [configs/00-locale-c-utf8.sh](./configs/00-locale-c-utf8.sh) | 可选：`/etc/profile.d/` 全局 locale |

---

## 1. 现象对照

| 场景 | `TERM` | 典型现象 |
|------|--------|----------|
| 外部 SSH / tmux | `xterm-256color` / `tmux-256color` | 粉/橙/紫实心 powerline，正常 |
| GNU screen（未修） | `screen-256color` | `` 乱码，或空心 `` |
| GNU screen（本方案） | `screen-256color` | 同布局实心色块（256 色近似 catppuccin） |

快速自检：

```bash
# 外部
echo $LANG $LC_ALL $STARSHIP_CONFIG $TERM
# 期望: C.UTF-8 C.UTF-8 .../starship.toml  xterm-256color（或类似）

# screen 内
echo $STY $LANG $STARSHIP_CONFIG $TERM
# 期望: <pid>.name  C.UTF-8  .../starship-screen.toml  screen-256color

starship prompt | od -c | head -3
# screen 内应看到 38;5; / 48;5; （256 色），而不是只有 38;2; 被 screen 吃掉后的残缺效果
```

---

## 2. 根因（两层，叠在一起）

### 2.1 系统 locale 名存在，但 locale **数据不存在**

很多容器 / 精简镜像只有：

```bash
locale -a
# C
# C.utf8
# POSIX
```

若 `.zshrc` 里写了：

```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

会出现：

```text
locale: Cannot set LC_CTYPE to default locale: No such file or directory
```

结果：多字节 UTF-8（Nerd Font / powerline 私用区字符）在 **screen** 里特别容易碎成 ``。  
tmux 对 UTF-8 默认处理更宽松，所以「只有 screen 坏」。

**修复**：统一用镜像里真实存在的：

```bash
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export LC_CTYPE=C.UTF-8
```

（`locale -a` 里可能显示为 `C.utf8`，`C.UTF-8` 一般可互认。）

### 2.2 GNU screen 会丢掉 24-bit truecolor

Starship catppuccin 配置里 palette 用 `#f38ba8` 这类 **hex**，会发出：

```text
\e[38;2;R;G;Bm   \e[48;2;R;G;Bm    # truecolor
```

**GNU screen 4.x**（如 4.09）中间处理属性时会丢掉 truecolor 背景，只剩 powerline 三角字符 → 视觉上变成空心 ``。

tmux 通常能透传 truecolor，所以外面 / tmux 正常。

**修复（二选一，本方案用 A）**：

| 方案 | 做法 | 观感 |
|------|------|------|
| **A. 推荐** | screen 内换 **256 色双胞胎** `starship-screen.toml`（`bg:211` 等），外面仍用 truecolor `starship.toml` | 布局一致，颜色略有 256 近似差 |
| B | 坚持 screen 内 truecolor | 需 screen 5+ / 特殊编译，多数集群镜像没有 |

验证是否在发 256 色：

```bash
starship prompt | python3 -c "import sys;d=sys.stdin.buffer.read();print('truecolor',b'38;2;'in d or b'48;2;'in d,'256',b'38;5;'in d or b'48;5;'in d)"
```

- 外部 fancy：`truecolor True`
- screen 双胞胎：`256 True` 且 `truecolor False`

### 2.3 改 Starship 时截断 `.zshrc` → screen 里 **Tab 无法补全**

修 screen 时若用脚本/正则只替换了 Starship 段，却把后面整段删掉，会丢失：

- `compinit`（菜单补全）
- `zsh-autosuggestions` / `zsh-syntax-highlighting`
- 历史 `SHARE_HISTORY` / `INC_APPEND_HISTORY`
- 代理等其它环境变量

表现：**外面旧 session 可能还能补全**（环境已加载），**screen 新窗口读残缺 `.zshrc` → Tab 失灵**。

**修复**：保证 `.zshrc` 在 Starship 之后仍有完整补全与插件块；teleai 以 [configs/teleai-gpu.zshrc](./configs/teleai-gpu.zshrc) 为准。

自检：

```bash
grep -n compinit /data_wj/.zshrc   # 或 ~/.zshrc
# screen 新窗口:
bindkey '^I'    # 应含 expand-or-complete
# 试: ls /da<Tab>
```

---

## 3. 最终方案架构

```text
┌─ 外部 / tmux ──────────────────────────────┐
│  STARSHIP_CONFIG=starship.toml             │
│  COLORTERM=truecolor                       │
│  → 24-bit catppuccin powerline             │
└────────────────────────────────────────────┘

┌─ GNU screen（STY 已设置 或 TERM=screen*）──┐
│  STARSHIP_CONFIG=starship-screen.toml      │
│  unset COLORTERM                           │
│  → 同布局 + 256 色近似（screen 能画背景）   │
│  ~/.screenrc: defutf8 + encoding utf8      │
│  alias screen='... screen -U'              │
└────────────────────────────────────────────┘

全局：
  LANG=LC_ALL=LC_CTYPE=C.UTF-8
```

自动切换靠 zsh：

```bash
if [[ -n "${STY:-}" || "${TERM:-}" == screen* ]]; then
  export STARSHIP_CONFIG=.../starship-screen.toml
  unset COLORTERM
else
  export STARSHIP_CONFIG=.../starship.toml
  export COLORTERM=truecolor
fi
```

---

## 4. 落地步骤（服务器）

以下路径以 **teleai-gpu 持久盘 `/data_wj`** 为例；换成自己的 `$HOME` 即可。

### 4.1 写入 `~/.screenrc`

```bash
cp /path/to/macos-setup-guide/configs/screenrc ~/.screenrc
# teleai-gpu 上还备了一份：
# cp configs/screenrc /data_wj/.screenrc
```

要点：`defutf8 on`、`encoding utf8 utf8`、`term screen-256color`、`screen -U`。

### 4.2 写入 Starship 双胞胎

```bash
mkdir -p ~/.config   # 或 /data_wj/.config
cp configs/starship-screen.toml ~/.config/starship-screen.toml
# 外面的 fancy 主题仍用你原来的 starship.toml（truecolor hex palette）
```

色号近似 catppuccin mocha：

| 语义 | 256 | 约等于 |
|------|-----|--------|
| red / pink | 211 | `#f38ba8` |
| peach | 216 | `#fab387` |
| yellow | 229 | `#f9e2af` |
| green | 151 | `#a6e3a1` |
| sapphire | 117 | `#74c7ec` |
| lavender | 147 | `#b4befe` |
| crust | 234 | `#11111b` |

**不要**在 screen 主题里用 `#rrggbb` palette——会再次逼出 truecolor。

### 4.3 写入 / 对齐 `.zshrc`

**推荐（teleai-gpu）**：直接对齐完整模板（含补全、历史、代理）：

```bash
cp configs/teleai-gpu.zshrc /data_wj/.zshrc
# /root/.zshrc 只负责 source：
echo '[ -f /data_wj/.zshrc ] && source /data_wj/.zshrc' > /root/.zshrc
```

**或**把 [configs/zshrc-screen-snippet.zsh](./configs/zshrc-screen-snippet.zsh) **合并**进已有 zsh 配置。

`.zshrc` 至少应包含：

1. `LANG/LC_*=C.UTF-8`
2. 按 `STY` / `TERM=screen*` 切换 `STARSHIP_CONFIG`
3. `alias screen='LANG=C.UTF-8 LC_ALL=C.UTF-8 screen -U'`
4. **`compinit` + autosuggestions + syntax-highlighting**（否则 screen 新窗 Tab 失效）
5. **`HISTFILE` + `SHARE_HISTORY` + `INC_APPEND_HISTORY`**（screen 内外共享历史）

### 4.4（可选）全局 profile

有 root 时：

```bash
sudo cp configs/00-locale-c-utf8.sh /etc/profile.d/00-locale-c-utf8.sh
```

保证非交互 / bash 登录也不会落到不存在的 `en_US.UTF-8`。

### 4.5 必须新开 screen / 重载 zshrc

旧 session 不会自动重载：

```bash
source /data_wj/.zshrc   # 或 source ~/.zshrc
# 或退出后: screen -S test

echo $STARSHIP_CONFIG
# screen 内 → .../starship-screen.toml
```

---

## 5. 命令历史（screen 是否写入 `.zsh_history`？）

**会。** screen 只是多开终端，仍跑同一 zsh 配置，**不会**单独一套 history。

teleai 当前约定：

| 项 | 值 |
|----|-----|
| 历史文件 | **`/data_wj/.zsh_history`**（持久盘；不是 `/root/.zsh_history`） |
| `HISTSIZE` / `SAVEHIST` | 50000 |
| `INC_APPEND_HISTORY` | 执行后立刻追加到文件 |
| `SHARE_HISTORY` | 多窗口 / 多 SSH / screen 共享 |
| `HIST_IGNORE_DUPS` | 连续重复不记 |
| `HIST_IGNORE_SPACE` | **前导空格**的命令不记 |

自检：

```bash
echo $HISTFILE
# → /data_wj/.zsh_history

# screen 里执行一条命令后
tail -5 /data_wj/.zsh_history
```

注意：

- 窗口若是 **bash** 而不是 zsh，不会写 `.zsh_history`（`echo $0` 确认）。
- 磁盘上可能残留旧的 `/root/.zsh_history`；**以 `HISTFILE` 指向为准**。

---

## 6. 验收清单

- [ ] `locale -a` 含 `C` / `C.utf8`；**没有**就不要用 `en_US.UTF-8`
- [ ] 外部：`STARSHIP_CONFIG` → `starship.toml`，prompt 有 truecolor
- [ ] screen 内：`STY` 非空，`STARSHIP_CONFIG` → `starship-screen.toml`
- [ ] screen 内 prompt 有彩色实心块（不是空心三角）
- [ ] 多字节路径 / Nerd 图标不再 ``
- [ ] screen 新窗口 **Tab 补全**正常（`compinit` 在 `.zshrc` 里）
- [ ] `echo $HISTFILE` 为 `/data_wj/.zsh_history`；screen 命令能 `tail` 到
- [ ] `tmux` 仍用 fancy truecolor，行为不变

---

## 7. 常见误区

| 误区 | 说明 |
|------|------|
| 「只改 `TERM=xterm-256color` 塞进 screen」 | 应用以为能发 truecolor，screen 仍可能改写属性，不稳定 |
| 「和外面共用同一个 hex `starship.toml`」 | screen 必丢 24-bit 背景 → 空心 powerline |
| 「装了 Nerd Font 就够了」 | 字体在**客户端**；服务器 locale / screen 编码不对一样碎 |
| 「旧 screen 会话 source 一下就好」 | 建议 **新开会话**；`STY` 与登录时的 env 更干净 |
| 「明文复制 prompt 还有 ``」 | 无 ANSI 背景时纯文本会这样；以**终端彩色渲染**为准 |
| 「只贴了 Starship 段就完事」 | 截断后丢 `compinit` → screen 新窗无法 Tab 补全 |
| 「screen 历史是另一份」 | 否；同一 `HISTFILE`，靠 `SHARE_HISTORY` 共享 |

---

## 8. 与本仓库其它文档的关系

- macOS 本机终端： [shell-config.md](./shell-config.md)（Ghostty + Nerd Font + Starship）
- Linux 服务器通用壳： [ubuntu-shell-config.md](./ubuntu-shell-config.md)
- **本文**：服务器上再开 **GNU screen** 时，与花式 Starship / 补全 / 历史 的兼容补丁

teleai-gpu 当前落地路径备忘：

```text
/data_wj/.zshrc                         # 完整配置（见 configs/teleai-gpu.zshrc）
/data_wj/.zsh_history                   # 命令历史（screen 内外共用）
/data_wj/.cache/zsh/.zcompdump          # 补全缓存
/data_wj/.config/starship.toml          # 外部 truecolor
/data_wj/.config/starship-screen.toml   # screen 256 色
/root/.screenrc  与  /data_wj/.screenrc
/etc/profile.d/00-locale-c-utf8.sh      # 可选
```

---

## 9. 一键安装示例（服务器）

在已 clone / 同步本目录的前提下：

```bash
GUIDE=/path/to/macos-setup-guide   # 改成你的路径
CONF="$GUIDE/configs"
DATA_WJ="${DATA_WJ:-/data_wj}"     # teleai 用 /data_wj

mkdir -p "$DATA_WJ/.config" "$DATA_WJ/.cache/zsh"
cp "$CONF/screenrc" "$HOME/.screenrc"
cp "$CONF/screenrc" "$DATA_WJ/.screenrc" 2>/dev/null || true
cp "$CONF/starship-screen.toml" "$DATA_WJ/.config/starship-screen.toml"

# teleai：整份对齐（备份后覆盖）
cp -a "$DATA_WJ/.zshrc" "$DATA_WJ/.zshrc.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
cp "$CONF/teleai-gpu.zshrc" "$DATA_WJ/.zshrc"
# 或合并 snippet：  # cat "$CONF/zshrc-screen-snippet.zsh" >> ...

# 可选 root：
# sudo cp "$CONF/00-locale-c-utf8.sh" /etc/profile.d/

source "$DATA_WJ/.zshrc"
screen -S test
echo "STARSHIP=$STARSHIP_CONFIG HISTFILE=$HISTFILE"
```
