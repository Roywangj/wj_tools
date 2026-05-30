# 🐧 Linux 服务器 Shell 环境配置

把通过 **VSCode 终端 / Termius / SSH** 连接的 Linux 服务器,打造成现代终端环境:

> **Zsh + Starship**(提示符)+ **modern CLI 工具**(bat / eza / fd / ripgrep / fzf / zoxide / delta / lazygit)+ **git-delta**

这是 macOS 版 `[macos-setup-guide/shell-config.md](../macos-setup-guide/shell-config.md)` 的 **Linux 服务器版**。步骤编号沿用 macOS 版,方便对照 —— 服务器上**只做第 3~7 步**:


| 步骤                | macOS 版     | 服务器上                              |
| ----------------- | ----------- | --------------------------------- |
| 1. 包管理器           | Homebrew    | ❌ 跳过(Linux 用 `apt`,系统自带)          |
| 2. Ghostty 终端     | 安装 app      | ❌ **不需要** —— 终端在你本地,不在服务器         |
| **3. 字体**         | 装 Nerd Font | ✅ **不用配**,用默认字体(见第 3 步)           |
| **4. CLI 工具**     | brew        | ✅ apt 或下载二进制                      |
| **5. Starship**   | brew        | ✅ 官方脚本 + **纯文本符号**(不依赖 Nerd Font) |
| **6. Shell(zsh)** | 自带          | ✅ 装插件 + 合并 `.zshrc`               |
| **7. git-delta**  | brew        | ✅ apt 或二进制                        |


> **关于字体:** 你不想在客户端折腾 Nerd Font —— 没问题。本指南的 Starship 配置(第 5 步)用**纯文本符号**,任何默认等宽字体都能正常显示,**不会出现豆腐块**。代价是没有那些花哨图标,但提示符依旧彩色、信息完整。
>
> 基础的 zsh + Oh My Zsh 安装见同目录 [ohmyzsh.md](./ohmyzsh.md)。本指南采用 **Starship + 独立插件**(不依赖 Oh My Zsh 框架),和 macOS 版保持一致。

---

## 目录

- [第 0 节:开工前两个关键判断](#第-0-节开工前两个关键判断)
- [第 3 步:字体(不用配,用默认即可)](#第-3-步字体不用配用默认即可)
- [第 4 步:CLI 工具](#第-4-步cli-工具)
- [第 5 步:Starship 提示符(纯文本符号)](#第-5-步starship-提示符纯文本符号)
- [第 6 步:Zsh 插件 + 合并 `.zshrc](#第-6-步zsh-插件--合并-zshrc)`
- [第 7 步:git-delta](#第-7-步git-delta)
- [第 8 步:验证](#第-8-步验证)
- [常见问题 FAQ](#常见问题-faq)

---

## 第 0 节:开工前两个关键判断

### 判断 1:你在服务器上有没有 `sudo`?

这决定了 CLI 工具怎么装:

```bash
sudo -v && echo "✅ 有 sudo,可用 apt 安装" || echo "❌ 无 sudo,需装到用户目录 ~/.local"
```

- **有 sudo**(自己的机器 / root)→ 可用 `apt install`,简单
- **没 sudo + 有 conda**(你的情况:共享服务器子用户,家目录在 `/data1/users/xxx`)→ **🌟 直接用 `conda install -c conda-forge` 装所有工具**,最省事,全程不需管理员
- **没 sudo 也没 conda** → 二进制下载到 `~/.local/bin`

第 4 步三种路径都给了。你是**无 sudo 子用户 + 有 conda**,走 conda 那条最顺。
另外:你**已经装了 zsh 且它已是你的默认 shell**(oh-my-zsh 在跑就是证据),所以不用 `sudo apt install zsh`、也不用 `chsh` —— shell 本体那一关已经过了。

### 判断 2:下载慢就先开代理

GitHub / 官方脚本下载慢或被墙时,先用你 `.zshrc` 里已有的代理函数:`proxy_lab` 或 `proxy_local`,再执行下载。

---

## 第 3 步:字体(不用配,用默认即可)

**服务器上不用装字体,客户端也不用换字体。** 直接用 VSCode 终端 / Termius / 本机终端的默认等宽字体即可。

**那为什么不会出现豆腐块?** 因为第 5 步的 Starship 配置用**纯文本符号**(plain-text symbols)—— 它不使用任何 Nerd Font 专有图标,提示符里只有普通字符和颜色,任何字体都能渲染。

### (可选)想要和 macOS 一样的完整图标?装 Nerd Font

服务器端**永远不用动字体** —— 图标渲染只取决于你**客户端**(连服务器的那个终端)用什么字体。默认字体 + 第 5 步的纯文本符号预设已经不会出豆腐块;但如果你想要 macOS 那种带 powerline 分隔符、OS / conda / git 图标的完整观感(配合[附录](#附录与-macos-一致的-starshiptoml手动创建用)那份 `starship.toml`),就在客户端装一个 Nerd Font。

**第 1 步:在本地电脑装一款 Nerd Font**(注意是本地电脑,不是服务器)。任选一款,如 `MesloLGS NF`、`JetBrainsMono Nerd Font`、`FiraCode Nerd Font`。

- **macOS**
  - 有 Homebrew(推荐):`brew install --cask font-meslo-lg-nerd-font`
  - 手动:从 [https://www.nerdfonts.com/font-downloads](https://www.nerdfonts.com/font-downloads) 下载字体 zip → 解压 → 选中所有 `.ttf` 双击 →「安装字体」(或拖进「字体册」App)
- **Windows**
  - 手动(最稳):从 [https://www.nerdfonts.com/font-downloads](https://www.nerdfonts.com/font-downloads) 下载 zip → 解压 → 选中所有 `.ttf` → 右键「为所有用户安装」(或拖进 设置 → 个性化 → 字体)
  - 有 Scoop:`scoop bucket add nerd-fonts && scoop install Meslo-NF`(字体名还有 `FiraCode-NF`、`JetBrainsMono-NF` 等)

**第 2 步:在客户端终端里选用这款字体**

- **VSCode 终端**:`settings.json` 加 `"terminal.integrated.fontFamily": "MesloLGS NF"`(换成你装的字体名)
- **macOS 系统终端 Terminal.app**:设置 → 描述文件 → 文本 → 字体 → 选它
- **Windows Terminal**:设置 → 对应配置文件 → 外观 → 字体 → 选它
- **Termius**:Settings → Terminal → Font 选它
- **iTerm2 / Ghostty 等**:各自字体设置里选

**第 3 步:服务器端**用[附录](#附录与-macos-一致的-starshiptoml手动创建用)那份 `starship.toml`,或 `starship preset nerd-font-symbols -o ~/.config/starship.toml`。

> 一句话:**字体装在客户端、配在客户端;服务器只管 `starship.toml`。** 不想折腾就跳过本节 —— 默认字体 + 纯文本符号一样彩色好用,不会豆腐块。

---

## 第 4 步:CLI 工具

替代老旧 `ls`/`cat`/`find`/`grep` 的现代工具。

**先检查哪些已装**(用命令名查):

```bash
for c in bat eza fd rg btop zoxide jq tldr delta lazygit fzf; do
  command -v "$c" &>/dev/null && echo "✅ $c" || echo "❌ $c"
done
```

### 🌟 路径(推荐,无 sudo 子用户首选)—— 用 conda 装

你有 conda、且无 sudo —— 这是**最省事**的办法。上面这些工具**全都在 conda-forge** 上,一条命令装完,不用手动下二进制、不用管理员、命令名也正常(没有 `batcat`/`fdfind` 那套问题)。

装进 **base 环境**(你默认就在 base,装完随时可用):

```bash
conda install -n base -c conda-forge \
  bat eza fd-find ripgrep fzf zoxide jq tealdeer git-delta lazygit btop starship
```

> 说明:
>
> - 包名对照命令:`fd-find`→命令 `fd`、`ripgrep`→`rg`、`tealdeer`→`tldr`、`git-delta`→`delta`。conda-forge 上 `fd` 的包名就是 `fd-find` 但**装出来的命令直接是 `fd`**(不像 apt 那样叫 `fdfind`),省去软链接。
> - **starship 也一起装了** —— 那第 5 步的安装就可以跳过,直接到「生成配置」。
> - 不想污染 base?可建专用环境:`conda create -n tools -c conda-forge bat eza ...`,再把 `~/anaconda3/envs/tools/bin` 加进 PATH(但装 base 最简单,推荐)。
> - 下载慢先开代理 `proxy_lab` / `proxy_local`,或给 conda 配清华镜像。

**⚠️ 关键一步:软链接到 `~/.local/bin`(否则切 conda 环境后工具会消失)**

装进 base 的工具,二进制在 `<anaconda3>/bin/`,**只有 base 在 PATH 时才可用**。你登录默认在 base 没问题,但一旦 `conda activate 研究环境`,conda 会把 base/bin 移出 PATH,这些工具(尤其 **starship**)就**全部失效** —— starship 失效会导致每次回车报 `command not found: starship`,提示符直接崩。

解决:软链接到 `~/.local/bin`(你 `.zshrc` 里这个目录**始终在 PATH**,不随 conda 环境切换而变):

```bash
conda activate base                       # 确保在 base
mkdir -p ~/.local/bin
for t in bat eza fd rg fzf zoxide jq tldr delta lazygit btop starship; do
  src=$(command -v "$t")
  [ -n "$src" ] && ln -sf "$src" ~/.local/bin/"$t" && echo "链接 $t"
done
```

这些是 Rust/Go 静态二进制,不依赖 conda 环境激活即可运行,所以软链接后切到任何环境都能用。

装完检查(**切到一个别的环境再查,验证不会消失**):

```bash
for c in bat eza fd rg fzf zoxide jq tldr delta lazygit btop starship; do
  command -v "$c" &>/dev/null && echo "✅ $c → $(command -v $c)" || echo "❌ $c"
done
```

全 ✅ 的话,**第 4 步就完成了**,直接跳到 [第 5 步生成 Starship 配置](#第-5-步starship-提示符纯文本符号)(安装部分可跳过)。下面 apt / 二进制两种路径是给没有 conda 的情况备用。

---

### 路径一:有 sudo —— 用 apt

```bash
sudo apt update
sudo apt install -y bat fd-find ripgrep jq fzf btop zoxide
```

> ⚠️ **Debian/Ubuntu 上两个命令名不一样**,要建软链接(放用户目录,不需 sudo):
>
> ```bash
> mkdir -p ~/.local/bin
> ln -sf "$(command -v batcat)" ~/.local/bin/bat
> ln -sf "$(command -v fdfind)" ~/.local/bin/fd
> ```
>
> 你的 `.zshrc` 已有 `export PATH="$HOME/.local/bin:$PATH"`,软链接自动生效。

`eza`、`git-delta`、`lazygit` apt 里通常没有 → 见下方「下载二进制」。

### 路径二:无 sudo(共享服务器)—— 下载二进制到 `~/.local/bin`

所有工具都是单文件静态二进制,下载解压到 `~/.local/bin` 即可,**不需要 root**。

```bash
mkdir -p ~/.local/bin
cd /tmp
# 下载慢就先开代理:proxy_lab 或 proxy_local

# eza(替代 ls)
curl -fsSL https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz | tar xz
mv eza ~/.local/bin/

# git-delta
DELTA_VER=$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest | grep -oP '"tag_name": "\K[^"]+')
curl -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VER}/delta-${DELTA_VER}-x86_64-unknown-linux-gnu.tar.gz" | tar xz
mv delta-*/delta ~/.local/bin/

# lazygit
LG_VER=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -oP '"tag_name": "v\K[^"]+')
curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VER}_Linux_x86_64.tar.gz" | tar xz lazygit
mv lazygit ~/.local/bin/

# bat / fd / ripgrep / fzf / btop / zoxide / jq 同理,各自 GitHub releases 有 x86_64 Linux 二进制
```

> **更省事:** 本仓库 `terminal-setup/bin/linux-x86_64/` 已打包 `eza`、`delta`、`lazygit`、`starship`、`tldr` 的 Linux 二进制,`scp` 到服务器 `~/.local/bin/` 再 `chmod +x` 即可。
> **zoxide / starship 有官方一键脚本**(支持自定义目录,无 sudo):见第 5 步。

**工具清单**(和 macOS 版一致):


| 工具        | 命令                       | 替代       |
| --------- | ------------------------ | -------- |
| bat       | `bat`(Debian 上 `batcat`) | `cat`    |
| eza       | `eza`                    | `ls`     |
| fd        | `fd`(Debian 上 `fdfind`)  | `find`   |
| ripgrep   | `rg`                     | `grep`   |
| btop      | `btop`                   | `top`    |
| zoxide    | `z`                      | `cd`     |
| jq        | `jq`                     | —        |
| tldr      | `tldr`                   | `man`    |
| git-delta | `delta`                  | git diff |
| lazygit   | `lazygit`                | git TUI  |
| fzf       | `fzf`                    | 模糊查找     |


---

## 第 5 步:Starship 提示符(纯文本符号)

> ✅ **如果第 4 步用 conda 装了 starship**,本步「安装」可**直接跳过**,从下面的「生成配置」开始。

**安装**(官方脚本,可指定目录,无 sudo):

```bash
# 装到 ~/.local/bin(无 sudo 场景)
curl -sS https://starship.rs/install.sh | sh -s -- -b ~/.local/bin -y

# 有 sudo 想装到 /usr/local/bin:
# curl -sS https://starship.rs/install.sh | sh
```

> 下载慢先开代理;或用 `terminal-setup/bin/linux-x86_64/starship` 二进制 `scp` 到 `~/.local/bin/`。

**生成 starship 配置 —— 下面两种选其一:**

**① 图标版(和 macOS 一致,需客户端 Nerd Font)**
适合已按第 3 步在客户端装好并选用了 Nerd Font 的人。两种来源任选:

```bash
mkdir -p ~/.config
[ -f ~/.config/starship.toml ] && cp ~/.config/starship.toml ~/.config/starship.toml.bak.$(date +%s)

# 来源 A:Starship 官方图标预设
starship preset nerd-font-symbols -o ~/.config/starship.toml

# 来源 B:用与 macOS 完全一致的那份(见文末附录),或从 Mac 直接 scp:
# scp ~/.config/starship.toml <server>:~/.config/starship.toml
```

带 powerline 分隔符、OS / conda / git 图标,最好看;但客户端没配 Nerd Font 就会出豆腐块。

**② 纯文本符号版(默认推荐,零字体折腾)**
不想碰客户端字体就用这个 —— 全是普通字符,任何默认字体都正常显示、**不会豆腐块**,同时保留颜色、git 状态、目录、时长等信息。

```bash
mkdir -p ~/.config
[ -f ~/.config/starship.toml ] && cp ~/.config/starship.toml ~/.config/starship.toml.bak.$(date +%s)

# Starship 官方预设:用纯文本替代所有 Nerd Font 图标
starship preset plain-text-symbols -o ~/.config/starship.toml
```

代价:没有那些花哨图标(但**彩色块、颜色仍在**)。想要「保留彩色块、只去掉图标」的折中做法,见文末 FAQ。

⚠️ Starship 要在 `.zshrc` 里 `init` 才生效 —— 见第 6 步。

---

## 第 6 步:Zsh 插件 + 合并 `.zshrc`

你服务器上**已装 zsh + Oh My Zsh**。本步:装 2 个独立插件 → 把 `.zshrc` 改成 Starship 方案,**同时完整保留你现有的全部个人配置**。

### 6-1. 装 2 个插件(用户目录,无 sudo)

```bash
mkdir -p ~/.zsh
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
```

> GitHub 慢:先 `proxy_lab`/`proxy_local`,或换 gitee 源(见 [ohmyzsh.md](./ohmyzsh.md))。

### 6-2. ⚠️⚠️ 合并 `.zshrc`,千万别覆盖

你的 `.zshrc` 里有**一大堆绝不能丢**的东西:

- **CUDA 环境变量**(`CUDA_HOME` / `PATH` / `LD_LIBRARY_PATH`,cuda-12.8)
- **conda 初始化块**(路径 `/data1/users/wangjie01/anaconda3`)
- **别名**:`ca` / `cda` / `cvd0`~`cvd7`
- **HuggingFace 镜像**(`HF_ENDPOINT` 等)
- **整套代理配置**(`proxy_lab` / `proxy_local` / `proxy_off` / `proxy_test` / `_proxy_apply`、`sync-proxy` / `echo-proxy` 别名,以及登录时自动跑的 `proxy_local` / `sync-proxy` / `echo-proxy`)
- **各种 PATH**:opencode、node、`~/.local/bin`

**正确做法:新主体 + 把上面这些原样搬进去 + 注释掉 Oh My Zsh 框架。** 结构如下:

```zsh
#!/bin/zsh
# ═══ 1) Starship + 插件主体(新)═══

# 用户级 bin 优先(让 ~/.local/bin 里的 starship/eza/delta 等生效)
export PATH="$HOME/.local/bin:$PATH"

# Starship 提示符
command -v starship &>/dev/null && eval "$(starship init zsh)"

# 自动补全建议
[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# 补全系统
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# 历史
HISTSIZE=50000; SAVEHIST=50000; HISTFILE=~/.zsh_history
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE INC_APPEND_HISTORY

# ↑/↓ 前缀搜索
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search; zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# fzf
command -v fzf &>/dev/null && eval "$(fzf --zsh 2>/dev/null)"
command -v fd &>/dev/null && export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# zoxide(智能 cd)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# modern CLI 别名(命令存在才设)
command -v eza   &>/dev/null && alias ls='eza --icons --group-directories-first' ll='eza -la --icons --group-directories-first' lt='eza --tree --icons --level=2'
command -v bat   &>/dev/null && alias cat='bat'
command -v rg    &>/dev/null && alias grep='rg'
command -v btop  &>/dev/null && alias top='btop'
command -v lazygit &>/dev/null && alias lg='lazygit'

# ═══════════════════════════════════════════════════════════
# ═══ 2) 个人配置(从旧 .zshrc 原样搬过来,保持启用)═══
# ═══════════════════════════════════════════════════════════

# CUDA
# export PATH=/usr/local/cuda-11.3/bin${PATH:+:${PATH}}
# export LD_LIBRARY_PATH=/usr/local/cuda-11.3/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# export PATH="/data/users/wangying/cuda/cuda-11.8/bin:$PATH"
# export LD_LIBRARY_PATH="/data/users/wangying/cuda/cuda-11.8/lib64:/data/users/wangying/cuda/cuda-11.8/mylib/lib64:$LD_LIBRARY_PATH"

# export PATH=/usr/local/cuda-12.1/bin${PATH:+:${PATH}}
# export LD_LIBRARY_PATH=/usr/local/cuda-12.1/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

export CUDA_HOME=/usr/local/cuda-12.8
export PATH=/usr/local/cuda-12.8/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64:$LD_LIBRARY_PATH

# >>> conda initialize >>>            ← 整块照搬
__conda_setup="$('/data1/users/wangjie01/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/data1/users/wangjie01/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/data1/users/wangjie01/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/data1/users/wangjie01/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# conda / CUDA 别名
alias ca='conda activate'
alias cda='conda deactivate'
alias cvd0='CUDA_VISIBLE_DEVICES=0'
alias cvd1='CUDA_VISIBLE_DEVICES=1'
alias cvd2='CUDA_VISIBLE_DEVICES=2'
alias cvd3='CUDA_VISIBLE_DEVICES=3'
alias cvd4='CUDA_VISIBLE_DEVICES=4'
alias cvd5='CUDA_VISIBLE_DEVICES=5'
alias cvd6='CUDA_VISIBLE_DEVICES=6'
alias cvd7='CUDA_VISIBLE_DEVICES=7'

# HuggingFace 镜像
export HF_ENDPOINT="https://hf-mirror.com"
export HF_HOME="/data1/users/wangjie01/.cache"
export HUGGINGFACE_HUB_CACHE="$HF_HOME/huggingface/hub"

# ==================== 代理配置(整段照搬,保持多行形式)====================
# 第一步：两种切换入口（端口各自指定，避免与其他同学冲突）
function proxy_lab() {    # 走实验室代理机（LAN 固定网关）
    export PROXY_HOST="10.106.1.36"                  # 修改为您的 LAN 代理地址
    # export PROXY_HOST="10.62.249.209"                  # 修改为您的 LAN 代理地址
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

# 同步代理配置到 VSCode/Cursor 的别名（被自动同步以及手动调用复用）
alias sync-proxy='~/wj_tools/proxy-setup-guide/sync-proxy-config.sh'
# 一键体检：打印当前终端代理变量 + 编辑器 settings.json 内容
alias echo-proxy='~/wj_tools/proxy-setup-guide/echo_proxy.sh'

# 第四步：默认登录时走哪条线路？（二选一，取消对应行前的 # 即可）
#   - proxy_lab   ：走实验室代理机（LAN 固定网关，断线不影响后台任务）
#   - proxy_local ：走本机代理（需本地 ~/.ssh/config 配 RemoteForward）
# proxy_lab
proxy_local

# proxy_test
# proxy_off

# 第五步：登录时自动同步代理到编辑器，并打印一次体检信息（不想要就注释掉）
sync-proxy >/dev/null
echo-proxy

# 其他 PATH
export PATH=/data1/users/wangjie01/.opencode/bin:$PATH
export PATH="/data1/users/wangjie01/coding_tools/node-v24.14.0-linux-x64/bin:$PATH"

# ═══════════════════════════════════════════════════════════
# ═══ 3) zsh-syntax-highlighting(必须在最后)═══
# ═══════════════════════════════════════════════════════════
[ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
    source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ═══════════════════════════════════════════════════════════
# ═══ 4) 旧 Oh My Zsh 配置(注释保留,可回退)═══
# 想切回 OMZ:注释掉上面 Starship 那段,取消下面注释。
# ═══════════════════════════════════════════════════════════
# export ZSH="$HOME/.oh-my-zsh"
# ZSH_THEME="cloud"
# HIST_STAMPS="mm/dd/yyyy"
# plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)
# source $ZSH/oh-my-zsh.sh
```

> 几个要点:
>
> - **先备份**:`cp ~/.zshrc ~/.zshrc.bak.$(date +%s)`
> - conda hook 建议从 `shell.bash` 改成 **`shell.zsh`**(你在 zsh 里更对路;不改也能跑)
> - 代理那几个函数和登录自动执行的 `proxy_local` / `sync-proxy` / `echo-proxy` 一定要保留,否则登录后没代理
> - 改完 `zsh -n ~/.zshrc` 查语法,再 `source`

### 6-3. 生效

```bash
zsh -n ~/.zshrc && source ~/.zshrc   # 语法 OK 才 source
```

或断开重连。应该能看到彩色 Starship 提示符,**且没有任何豆腐块**。

---

## 第 7 步:git-delta(可选)

让 `git diff` 变成彩色、带行号、并排。改的是 `~/.gitconfig`,与 shell 无关:

```bash
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.dark true
git config --global delta.line-numbers true
git config --global delta.side-by-side true
git config --global merge.conflictstyle diff3
git config --global diff.colorMoved default
```

> ⚠️ 你的代理函数 `_proxy_apply` / `proxy_off` 也会写 `git config --global http.proxy`,和这里互不冲突(一个管 pager,一个管 proxy)。
> 配置永久存在 `~/.gitconfig`,跑一次即可。

---

## 第 8 步:验证

重连服务器,逐项确认:

```bash
command -v starship && echo $STARSHIP_SHELL   # zsh
eza --icons      # 带图标的 ls
type ls          # 应为 eza ...
zoxide --version # zoxide(注意:不是 z --version)
delta --version  # git-delta
```

**检查清单:**

- 提示符彩色、**无豆腐块**(纯文本符号 + 默认字体)
- 打字有灰色补全建议(autosuggestions)
- 命令变绿/红(syntax-highlighting)
- `ls` 有图标(eza 别名;注:eza 自己的图标在无 Nerd Font 时可能不全,可改用 `eza --no-icons` 别名)
- `conda activate xxx` 能用 ← 个人配置保留成功
- `proxy_local` / `proxy_test` 能用 ← 代理配置保留成功
- `git diff` 彩色并排(delta)

> 提示:`eza --icons` 的文件类型图标也属于 Nerd Font 字形,默认字体下可能显示为方块。**不想要的话**把别名里的 `--icons` 去掉即可:`alias ls='eza --group-directories-first'`。Starship 提示符本身用纯文本符号,不受影响。

---

## 常见问题 FAQ

**Q:提示符还是出现豆腐块?**
A:确认第 5 步用的是 `plain-text-symbols` 预设(`grep -i symbol ~/.config/starship.toml` 看是不是纯文本)。另外 `eza --icons` 的图标也会是方块 —— 去掉别名里的 `--icons` 即可。Starship 本身用纯文本不会有问题。

**Q:conda 装的工具,切到别的环境后就 `command not found` 了 / starship 报错了?**
A:因为它们装在 base,`conda activate 别的环境` 会把 base/bin 移出 PATH。解决:在 base 下把它们软链接到 `~/.local/bin`(见第 4 步「关键一步」),那里始终在 PATH,切环境也不丢。

**Q:没有 sudo,apt 装不了?**
A:走第 4 步「无 sudo」分支,二进制下载到 `~/.local/bin`(已在 PATH)。Starship/zoxide 官方脚本支持 `-b ~/.local/bin`。

**Q:GitHub / 官方脚本下载极慢或失败?**
A:先开 `.zshrc` 里的代理 `proxy_lab` / `proxy_local`,再下载;或用 `terminal-setup/bin/linux-x86_64/` 里打包好的二进制 `scp` 上去。

**Q:合并 `.zshrc` 后 conda 用不了 / 代理没了?**
A:多半是个人配置块没搬全或位置错。`cp ~/.zshrc.bak.* ~/.zshrc` 还原,对照第 6-2 节重新合并,重点保 conda 块、CUDA、代理函数 + 登录自动执行那几行。

**Q:想保留 Oh My Zsh 不换 Starship?**
A:可以共存 —— 保留 OMZ,只在 `.zshrc` 末尾加 `eval "$(starship init zsh)"`,Starship 接管提示符。但本指南推荐纯 zsh + Starship(更快、和 macOS 一致)。基础 OMZ 安装见 [ohmyzsh.md](./ohmyzsh.md)。

**Q:每台服务器都要重配?**
A:配好一台后,把 `~/.zshrc`、`~/.config/starship.toml`、`~/.local/bin/` 二进制、`~/.zsh/` 插件目录 `scp`/`rsync` 到新服务器即可,几乎零重装。

**Q:以后想要花哨图标版?**
A:① 在你连服务器的客户端选一个 Nerd Font;② 服务器上 `starship preset nerd-font-symbols -o ~/.config/starship.toml`,或把 Mac 的 Catppuccin `starship.toml` `scp` 过来;③ 别名保留 `eza --icons`。

**Q:服务器提示符和我 macOS 本地长得不一样?`(base)` 还单独占一行?**
A:这**不是字体问题**。字体只决定图标显不显示成豆腐块,**不影响**「`base` 在不在同一行」「提示符几行」。真正原因有两个,分开解决:

**原因 1:两台机器用的根本是两套 starship 配置。**
你 macOS 用的是自定义 powerline 配置(把 os/目录/语言/`$conda`/时间串在**同一行**);服务器若按第 5 步生成的是 `plain-text-symbols` **默认格式**(所以显示成 `用户 in 主机 in 目录 via py …` 这种措辞)。要排版一致,把 Mac 的配置拷过去:

```bash
# 在 macOS 本地执行,<server> 换成你的 ssh 别名/地址
scp ~/.config/starship.toml <server>:~/.config/starship.toml
```

> Mac 这份配置里 `[conda]` 设了 `ignore_base = false` + `format = '[$symbol$environment ]($style)'`,所以 `base` 会显示在 powerline 同一行内。
>
> 不方便 `scp`?这份配置的完整内容见文末**[附录:与 macOS 一致的 starship.toml](#附录与-macos-一致的-starshiptoml手动创建用)**,可手动创建。

**原因 2:conda 自带 prompt(`changeps1`)在作怪 —— 这才是 `(base)` 跑到单独一行的根源。**


|            | `changeps1` | 现象                                               |
| ---------- | ----------- | ------------------------------------------------ |
| macOS(你已是) | **false**   | conda 不自己画,`base` 全交给 starship `$conda` 模块 → 同一行 |
| 服务器(默认)    | **true**    | conda 自己往 PS1 塞 `(base)`,和 starship 打架 → 单独一行    |


服务器上关掉它即可对齐:

```bash
conda config --set changeps1 false
```

**关于字体(第三件独立的事):** Mac 那份配置**重度依赖 Nerd Font**(分隔符 `、os 图标 `󰕈`、conda 图标`  等)。服务器客户端若没设 Nerd Font,这些图标会变方块,但**布局(单行 + base 同行)依旧和 macOS 一致**。想完全一样好看,就在**客户端**(VSCode `terminal.integrated.fontFamily` / Termius Terminal Font)装并选一个 Nerd Font;不想折腾字体,就保留 `plain-text-symbols`,只做「关 changeps1」让 base 归位即可。

**Q:VSCode 终端里比 Termius 多出一个 `(.venv)` 前缀?**
A:和 starship、和服务器配置都**无关**。那是 **VSCode 的 Python 扩展**自动激活了工作区里的 `.venv` 并注入终端。不想要它,在 VSCode settings 里关掉:

```json
"python.terminal.activateEnvironment": false
```

**Q:那在服务器上装字体行不行?装了能解决豆腐块吗?**
A:**不行,装了也没用。** SSH 下服务器只负责输出字符,真正把字符画成图形的是你**本地电脑的终端 App**,用的也是**本地的字体**;服务器上的字体只给「服务器自己的图形界面程序」用,而你 SSH 进去根本没碰图形界面。所以:

- ❌ 服务器装 Nerd Font → 豆腐块照旧,毫无变化
- ✅ 想要图标 → 在**客户端**(你的 Mac / Windows)装字体并在终端里选用(见第 3 步)
- ✅ 不想碰字体 → 服务器改用 `plain-text-symbols`;或保留彩色块、只删字形(把 `format` 里的分隔符 `[](...)` 删掉、各模块 `symbol=""`)—— 彩色块是 ANSI 颜色转义码,**与字体无关**

> 同一台服务器,在 VSCode 终端正常、在 macOS 系统终端却豆腐,正是这个原因:两个客户端用的字体不同,跟服务器无关。

---

## 附录:与 macOS 一致的 `starship.toml`(手动创建用)

想让服务器提示符和 macOS 本地**完全一致**(单行 powerline、`base` 同行),除了 FAQ 里的 `scp` 方案,也可以**在服务器上手动创建** `~/.config/starship.toml`,内容见下方,直接整段粘贴即可。

> ⚠️ **这份配置重度依赖 Nerd Font**(powerline 分隔符 `、os 图标 `󰕈`、conda 图标`  等)。客户端(VSCode 的 `terminal.integrated.fontFamily` / Termius 的 Terminal Font)要选一个 Nerd Font 才能正常显示图标,否则会出现方块。不想折腾字体,就继续用第 5 步的 `plain-text-symbols` 预设。
>
> 另外别忘了配套:`conda config --set changeps1 false`(否则 conda 自带的 `(base)` 会单独占一行,见 FAQ)。

**创建步骤:**

```bash
mkdir -p ~/.config
# 先备份已有的(如果有)
[ -f ~/.config/starship.toml ] && cp ~/.config/starship.toml ~/.config/starship.toml.bak.$(date +%s)
# 用编辑器打开,把下面整段粘贴进去保存
vim ~/.config/starship.toml      # 或 nano ~/.config/starship.toml
```

粘贴以下内容:

```toml
"$schema" = 'https://starship.rs/config-schema.json'

format = """
[](red)\
$os\
$username\
[](bg:peach fg:red)\
$directory\
[](bg:yellow fg:peach)\
$git_branch\
$git_status\
[](fg:yellow bg:green)\
$c\
$rust\
$golang\
$nodejs\
$php\
$java\
$kotlin\
$haskell\
$python\
[](fg:green bg:sapphire)\
$conda\
[](fg:sapphire bg:lavender)\
$time\
[ ](fg:lavender)\
$cmd_duration\
$line_break\
$character"""

palette = 'catppuccin_mocha'

[os]
disabled = false
style = "bg:red fg:crust"

[os.symbols]
Windows = ""
Ubuntu = "󰕈"
SUSE = ""
Raspbian = "󰐿"
Mint = "󰣭"
Macos = "󰀵"
Manjaro = ""
Linux = "󰌽"
Gentoo = "󰣨"
Fedora = "󰣛"
Alpine = ""
Amazon = ""
Android = ""
AOSC = ""
Arch = "󰣇"
Artix = "󰣇"
CentOS = ""
Debian = "󰣚"
Redhat = "󱄛"
RedHatEnterprise = "󱄛"

[username]
show_always = true
style_user = "bg:red fg:crust"
style_root = "bg:red fg:crust"
format = '[ $user]($style)'

[directory]
style = "bg:peach fg:crust"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = "󰝚 "
"Pictures" = " "
"Developer" = "󰲋 "

[git_branch]
symbol = ""
style = "bg:yellow"
format = '[[ $symbol $branch ](fg:crust bg:yellow)]($style)'

[git_status]
style = "bg:yellow"
format = '[[($all_status$ahead_behind )](fg:crust bg:yellow)]($style)'

[nodejs]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[c]
symbol = " "
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[rust]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[golang]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[php]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[java]
symbol = " "
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[kotlin]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[haskell]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[python]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version)(\(#$virtualenv\)) ](fg:crust bg:green)]($style)'

[docker_context]
symbol = ""
style = "bg:sapphire"
format = '[[ $symbol( $context) ](fg:crust bg:sapphire)]($style)'

[conda]
symbol = "  "
style = "fg:crust bg:sapphire"
format = '[$symbol$environment ]($style)'
ignore_base = false

[time]
disabled = false
time_format = "%R"
style = "bg:lavender"
format = '[[  $time ](fg:crust bg:lavender)]($style)'

[line_break]
disabled = false

[character]
disabled = false
success_symbol = '[❯](bold fg:green)'
error_symbol = '[❯](bold fg:red)'
vimcmd_symbol = '[❮](bold fg:green)'
vimcmd_replace_one_symbol = '[❮](bold fg:lavender)'
vimcmd_replace_symbol = '[❮](bold fg:lavender)'
vimcmd_visual_symbol = '[❮](bold fg:yellow)'

[cmd_duration]
show_milliseconds = true
format = " in $duration "
style = "bg:lavender"
disabled = false
show_notifications = true
min_time_to_notify = 45000

[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
flamingo = "#f2cdcd"
pink = "#f5c2e7"
mauve = "#cba6f7"
red = "#f38ba8"
maroon = "#eba0ac"
peach = "#fab387"
yellow = "#f9e2af"
green = "#a6e3a1"
teal = "#94e2d5"
sky = "#89dceb"
sapphire = "#74c7ec"
blue = "#89b4fa"
lavender = "#b4befe"
text = "#cdd6f4"
subtext1 = "#bac2de"
subtext0 = "#a6adc8"
overlay2 = "#9399b2"
overlay1 = "#7f849c"
overlay0 = "#6c7086"
surface2 = "#585b70"
surface1 = "#45475a"
surface0 = "#313244"
base = "#1e1e2e"
mantle = "#181825"
crust = "#11111b"

[palettes.catppuccin_frappe]
rosewater = "#f2d5cf"
flamingo = "#eebebe"
pink = "#f4b8e4"
mauve = "#ca9ee6"
red = "#e78284"
maroon = "#ea999c"
peach = "#ef9f76"
yellow = "#e5c890"
green = "#a6d189"
teal = "#81c8be"
sky = "#99d1db"
sapphire = "#85c1dc"
blue = "#8caaee"
lavender = "#babbf1"
text = "#c6d0f5"
subtext1 = "#b5bfe2"
subtext0 = "#a5adce"
overlay2 = "#949cbb"
overlay1 = "#838ba7"
overlay0 = "#737994"
surface2 = "#626880"
surface1 = "#51576d"
surface0 = "#414559"
base = "#303446"
mantle = "#292c3c"
crust = "#232634"

[palettes.catppuccin_latte]
rosewater = "#dc8a78"
flamingo = "#dd7878"
pink = "#ea76cb"
mauve = "#8839ef"
red = "#d20f39"
maroon = "#e64553"
peach = "#fe640b"
yellow = "#df8e1d"
green = "#40a02b"
teal = "#179299"
sky = "#04a5e5"
sapphire = "#209fb5"
blue = "#1e66f5"
lavender = "#7287fd"
text = "#4c4f69"
subtext1 = "#5c5f77"
subtext0 = "#6c6f85"
overlay2 = "#7c7f93"
overlay1 = "#8c8fa1"
overlay0 = "#9ca0b0"
surface2 = "#acb0be"
surface1 = "#bcc0cc"
surface0 = "#ccd0da"
base = "#eff1f5"
mantle = "#e6e9ef"
crust = "#dce0e8"

[palettes.catppuccin_macchiato]
rosewater = "#f4dbd6"
flamingo = "#f0c6c6"
pink = "#f5bde6"
mauve = "#c6a0f6"
red = "#ed8796"
maroon = "#ee99a0"
peach = "#f5a97f"
yellow = "#eed49f"
green = "#a6da95"
teal = "#8bd5ca"
sky = "#91d7e3"
sapphire = "#7dc4e4"
blue = "#8aadf4"
lavender = "#b7bdf8"
text = "#cad3f5"
subtext1 = "#b8c0e0"
subtext0 = "#a5adcb"
overlay2 = "#939ab7"
overlay1 = "#8087a2"
overlay0 = "#6e738d"
surface2 = "#5b6078"
surface1 = "#494d64"
surface0 = "#363a4f"
base = "#24273a"
mantle = "#1e2030"
crust = "#181926"
```

