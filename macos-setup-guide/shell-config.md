# 🖥️ macOS 终端环境配置 · 完整教程正文

> 这是手把手安装的**完整正文**。总览和快速跳转见 **[README.md](./README.md)**;日常速查见 **[cheatsheet.md](./cheatsheet.md)**。
>
> 目标终端栈:**Ghostty + (Fish 或 Zsh) + Starship + Nerd Font + 一堆现代 CLI 工具**
>
> 对应 [`terminal-setup`](https://github.com/lewislulu/terminal-setup) 仓库 `setup.sh` 的 macOS 流程,
> 拆成**人工一步步执行**的版本。每一步都先给「检查是否已装」的命令 —— 之前装过的部分会自动跳过,
> 不会重复安装、不会出错。

**前提假设:**
- ✅ 你已经**手动装好了 Ghostty**(`/Applications/Ghostty.app` 存在)
- ✅ 你已经装了**一部分插件/工具**(具体哪些不重要,每步都会自查)
- ❓ 你还在纠结 **Fish 还是 Zsh** —— 第 0 节专门讲清楚

---

## 目录

- [第 0 节:先搞懂 Fish vs Zsh(解决你的困惑)](#第-0-节先搞懂-fish-vs-zsh解决你的困惑)
- [第 1 步:Homebrew(包管理器)](#第-1-步homebrew包管理器)
- [第 2 步:Ghostty 配置(已装,只配)](#第-2-步ghostty-配置已装只配)
- [第 3 步:Nerd Font 字体](#第-3-步nerd-font-字体)
- [第 4 步:CLI 工具](#第-4-步cli-工具)
- [第 5 步:Starship 提示符](#第-5-步starship-提示符)
- [👉 第 6 步:选你的 Shell —— 分叉点](#-第-6-步选你的-shell--分叉点)
  - [路径 A:Zsh](#路径-azsh)
  - [路径 B:Fish](#路径-bfish)
- [第 7 步:git-delta(美化 git diff)](#第-7-步git-delta美化-git-diff)
- [第 8 步(可选):fnm + Node.js](#第-8-步可选fnm--nodejs)
- [第 9 步(可选):Zellij 终端复用器](#第-9-步可选zellij-终端复用器)
- [第 10 步:验证一切正常](#第-10-步验证一切正常)
- [常见问题 FAQ](#常见问题-faq)

---

## 第 0 节:先搞懂 Fish vs Zsh(解决你的困惑)

你纠结的核心问题是:**到底用哪个 shell?** 先一句话区分:

| | 🐟 **Fish** | 🐚 **Zsh** |
|---|------------|-----------|
| 自动补全建议(灰字提示) | ✅ 内置,零配置 | ⚠️ 要装插件 `zsh-autosuggestions` |
| 语法高亮(命令变绿/红) | ✅ 内置,零配置 | ⚠️ 要装插件 `zsh-syntax-highlighting` |
| 兼容 bash 脚本 / 一行命令 | ❌ **不兼容**,语法不一样 | ✅ 完全兼容(POSIX) |
| macOS 是否自带 | ❌ 要 `brew install` | ✅ **系统自带**,默认 shell |
| 适合谁 | 想开箱即用、少折腾 | 经常跑别人的脚本、要 POSIX |

**一句话决策:**
- 你经常 `git clone` 别人的项目、复制网上的 `bash` 一行命令、跑各种 `.sh` 脚本 → **用 Zsh**。
- 你想要最干净的开箱体验,不介意偶尔写 `bash script.sh` 来跑脚本 → **用 Fish**。

### ⚠️ 重要:这套 Zsh 配置**不用 Oh My Zsh**

你在服务器上(`server_install/ohmyzsh.md`)用的是 **Oh My Zsh** 框架。这里**不一样**,要注意区别:

| | 你服务器上的 Oh My Zsh | 本教程的纯 Zsh |
|---|----------------------|---------------|
| 框架 | Oh My Zsh(启动时加载 100+ 文件) | 无框架,纯 zsh |
| 插件来源 | `git clone` 到 `~/.oh-my-zsh/custom/plugins/` | `brew install` 装到 Homebrew 目录 |
| 启动速度 | 较慢 | 快(只 `source` 3 个文件) |
| 主题/提示符 | Oh My Zsh 主题(如 `cloud`) | **Starship**(跨 shell 通用) |
| 配置文件 | `~/.zshrc` 里 `plugins=(...)` | `~/.zshrc` 里直接 `source` 插件 |

**为什么不用 Oh My Zsh?** 只需要 3 个插件(autosuggestions、syntax-highlighting、completions),用 Homebrew 装一行 `source` 就够了,不需要一整个框架。启动更快、依赖更少。

> 如果你之前在这台 Mac 上装过 Oh My Zsh,**不用卸载**,但本教程会用一份全新的 `~/.zshrc`(会自动备份你的旧配置)。两者别混用,以本教程的 `.zshrc` 为准即可。

**还是拿不定?** 默认走 **Zsh**(macOS 自带、兼容性最好、和你已有的 zsh 经验衔接)。本教程两条路径都写了,第 1~5 步是公用的,做完再到第 6 步选一条走。

---

## 第 1 步:Homebrew(包管理器)

后面几乎所有东西都靠它装。先检查:

```bash
brew --version
```

- **有版本号输出** → 已装,跳到第 2 步。
- **command not found** → 装它:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

装完按提示把 brew 加进 PATH。**Apple 芯片(M1/M2/M3/M4)** 在 `/opt/homebrew`:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Intel 芯片** 在 `/usr/local`,安装脚本通常会自动处理好。

> 不确定自己是哪种芯片?`uname -m`:`arm64` = Apple 芯片,`x86_64` = Intel。

验证:

```bash
brew --version   # 能看到版本号即可
```

---

## 第 2 步:Ghostty 配置(已装,只配)

你已经手动装好 Ghostty 了,这一步只是**放配置文件**。

macOS 上 Ghostty 的配置目录是:

```
~/Library/Application Support/com.mitchellh.ghostty/
```

配置文件名是 **`config.ghostty`**(macOS 专用,Linux 上叫 `config`,别搞混)。

执行:

```bash
GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$GHOSTTY_DIR"

# 如果已有配置,先备份
[ -f "$GHOSTTY_DIR/config.ghostty" ] && cp "$GHOSTTY_DIR/config.ghostty" "$GHOSTTY_DIR/config.ghostty.bak.$(date +%s)"

# 写入配置
cat > "$GHOSTTY_DIR/config.ghostty" <<'EOF'
theme = Catppuccin Mocha
font-family = MesloLGS Nerd Font Mono
font-size = 14

# 窗口
window-padding-x = 12
window-padding-y = 8
EOF
```

> ⚠️ **字体名必须和实际安装的对得上。** 这里写 `MesloLGS Nerd Font Mono`,是因为 [第 3 步](#第-3-步nerd-font-字体) 用 `brew install --cask font-meslo-lg-nerd-font` 装的字体族名就是它。
> **别写成 `MesloLGS NF`** —— 那是 Powerlevel10k 那套字体文件的名字(terminal-setup 仓库自带的),和 Homebrew 装的这版名字不同,写错 Ghostty 会找不到字体、回退成默认字体(图标变豆腐块)。
> 装完字体后,可以用 `/Applications/Ghostty.app/Contents/MacOS/ghostty +list-fonts | grep -i meslo` 查实际可用的字体族名,以列表里的为准。

改完配置,在 Ghostty 里按 **`Cmd + Shift + ,`** 可以重新加载配置(或直接重启 Ghostty)。

### 方式二:在 Ghostty app 里改(不想敲命令的话)

⚠️ 先说清楚:Ghostty **没有** iTerm2 那种带下拉框、开关的图形设置面板。它的「设置」本质上就是**帮你打开上面那个 `config.ghostty` 文件**,你再用文本编辑器手改。所以这只是方式一的另一种入口,改的是同一个文件。

步骤:

1. 打开 Ghostty,菜单栏点 **Ghostty → Settings**,或直接按快捷键 **`Cmd + ,`**。
   - 这会用你的默认编辑器打开 `config.ghostty`(第一次可能是空文件,或文件还不存在 —— Ghostty 会帮你创建)。
2. 在打开的文件里**逐行填配置**(每行一个 `键 = 值`,`#` 开头是注释):

   ```
   theme = Catppuccin Mocha
   font-family = MesloLGS Nerd Font Mono
   font-size = 14

   # 窗口
   window-padding-x = 12
   window-padding-y = 8
   ```

3. **保存**文件(编辑器里 `Cmd + S`)。
4. 回到 Ghostty 窗口,按 **`Cmd + Shift + ,`** 重新加载配置(或重启 Ghostty)立即生效。

> 想知道有哪些配置项可填?在终端里运行 `ghostty +show-config --default --docs`,会列出**所有**可用配置项和说明;或查 [官方配置文档](https://ghostty.org/docs/config)。比如想加光标闪烁:`cursor-style-blink = true`。

**两种方式选一个就行**,效果完全一样,改的都是 `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`。命令行方式(方式一)适合一次到位、可复制;app 方式(方式二)适合边看边调。

### ⚠️ 关键坑:用 Ghostty SSH 连服务器后「一输入就光标错位 / `❯` 变暗 / 自动补全错乱」

**现象:** 用 Ghostty SSH 到服务器,**不输入时** starship 提示符正常、`❯` 是绿色;**一开始打字**,`❯` 就变暗、自动补全的灰字错位重叠(例如 `nvidia-smi` 显示成 `nnvviiddiiaa--smmi` 这种鬼影)。**同一台服务器用 macOS 自带「终端」连却完全正常。**

**根因:** Ghostty 默认把 `TERM` 设成 `xterm-ghostty`。这是 Ghostty 自带的 terminfo 条目,**你的服务器上没有**。zsh 的行编辑器(zle)靠 terminfo 里的光标移动/清行序列来重绘命令行;远端不认识 `xterm-ghostty` 时这些序列用错,一重绘就错位。系统终端用的是人尽皆知的 `xterm-256color`,所有服务器都认识,所以它一直正常 —— 这正好说明问题出在 `TERM`,与服务器上的 starship / zsh 配置无关。

> ❌ 不要用 `grapheme-width-method = legacy` 去治这个 —— 那是针对字符**宽度**的开关,治不了 terminfo 缺失,反而可能让字符两两重复(`nnvviiddiiaa`)并改变配色。

**✅ 推荐解法:把 Ghostty 的 terminfo 装到服务器(本地保持原样,颜色不受影响)。** 在你的 **Mac 本地**跑一行(`<server>` 换成你的 ssh 别名/地址):

```bash
infocmp -x xterm-ghostty | ssh <server> -- tic -x -
```

它把 `xterm-ghostty` 的 terminfo 编译进服务器的 `~/.terminfo/`(**无需 sudo**)。之后**重新 SSH 连一次**即正常,且本地 Ghostty 仍是原生 `xterm-ghostty`、truecolor 配色不降级。

> 跑这条命令时如果看到 `tic` 打印一行 `older tic versions may treat the description field as an alias` —— 那只是**警告不是报错**,terminfo 已正常写入,可忽略。
> 另外 `infocmp -x xterm-ghostty` 必须在**本地 Ghostty 窗口**里跑(它才读得到 Ghostty 自带的 terminfo)。若在别的终端跑报 `couldn't open terminfo file`,改用绝对路径:
> ```bash
> TERMINFO=/Applications/Ghostty.app/Contents/Resources/terminfo \
>   infocmp -x xterm-ghostty | ssh <server> -- tic -x -
> ```

**验证(在服务器上跑):**

```bash
echo $TERM                                   # 应为 xterm-ghostty
infocmp xterm-ghostty >/dev/null 2>&1 && echo "✅ terminfo 已装" || echo "❌ 未装"
ls ~/.terminfo/x/xterm-ghostty 2>/dev/null && echo "文件已就位"
```

实测输出(已确认生效):

```text
✅ terminfo 已装
/data1/users/<user>/.terminfo/x/xterm-ghostty
文件已就位
```

装好后**完全退出 Ghostty 再重开**(并重新 SSH),`$TERM` 会变回 `xterm-ghostty`,此时一边打字一边看:`❯` 不再变暗、`nvidia-smi` 之类补全不再错位重叠,本地 Catppuccin 配色也保持满血。

> 注意:如果你之前用过下面的「兜底解法」加了 `term = xterm-256color`,装好 terminfo 后记得**把那行删掉并重开 Ghostty**,否则 `$TERM` 会一直停在 `xterm-256color`(配色降级)。删掉后 `echo $TERM` 才会显示 `xterm-ghostty`。

**🅱 兜底解法(实在装不了 terminfo 时):让 Ghostty 谎报 TERM。** 在 `config.ghostty` 加一行:

```ini
term = xterm-256color
```

立刻消除错位,且无需动服务器。**代价:本地 Ghostty 的 `TERM` 也被降到 256 色档,Catppuccin 等 truecolor 配色会变样**(如果你改了这行又觉得「颜色没恢复」,就是它干的——删掉这行并重载即可恢复)。所以**优先用推荐解法**,只有没法给服务器装 terminfo 时才用它。

> 小结:错位 = 服务器缺 `xterm-ghostty` terminfo。最佳是给服务器补 terminfo(本地不动、颜色满血);`term = xterm-256color` 是会牺牲本地配色的应急手段。

---

## 第 3 步:Nerd Font 字体

Starship 提示符里那些图标(目录图标、git 分支符号、语言图标)需要 **Nerd Font** 才能正常显示,否则会看到一堆「豆腐块」□。我们用 **Meslo Nerd Font**(Homebrew 装出来的字体族名是 `MesloLGS Nerd Font Mono`)。

检查是否已装:

```bash
ls ~/Library/Fonts/ | grep -i "MesloLGS"
```

- **列出 4 个 `.ttf`** → 已装,跳到第 4 步。
- **没输出** → 用 Homebrew 装(最省事):

```bash
brew install --cask font-meslo-lg-nerd-font
```

> 这会把整套 Meslo Nerd Font 装到 `~/Library/Fonts/`。装完**重启 Ghostty**,第 2 步配的字体就生效了。

**验证:** 命令行查 Ghostty 实际能用的字体族名(这才是要填进配置的名字):

```bash
/Applications/Ghostty.app/Contents/MacOS/ghostty +list-fonts | grep -i meslo
# 用 Homebrew cask 装的话,会看到 "MesloLGS Nerd Font Mono" 等族名
# —— 第 2 步 config.ghostty 里的 font-family 必须和这里列出的某个名字完全一致
```

> ⚠️ 常见坑:`brew install --cask font-meslo-lg-nerd-font` 装出来的族名是 **`MesloLGS Nerd Font Mono`**,不是 `MesloLGS NF`。如果你第 2 步填了 `MesloLGS NF`,这里就要回去改成 `MesloLGS Nerd Font Mono`(或 `+list-fonts` 里列出的实际名字),否则 Ghostty 找不到字体会回退成默认字体。

**如果你用的是 macOS 自带的「终端」Terminal.app(不是 Ghostty)**,字体要在它自己的设置里选 —— 上面那个 `config.ghostty` 对 Terminal.app **无效**,而且同样的族名坑在这里照样成立:**别选 `MesloLGS NF`,要选 `MesloLGS Nerd Font Mono`**。步骤:打开「终端」→ 菜单 **终端 → 设置…**(`Cmd + ,`)→ 左侧选中你正在用的描述文件 → **文本** 标签 → 「字体」区右下角 **更改…** → 在字体面板里搜 `Meslo`,家族选 **MesloLGS Nerd Font Mono**、字重 Regular、调好字号 → 关闭面板,**新开一个终端窗口**即生效。注意 Terminal.app 是从这个图形列表里**选**字体(不像 Ghostty 那样敲名字),所以只要面板里能搜到 `MesloLGS Nerd Font Mono` 就证明第 3 步字体装好了;搜不到就回第 3 步重装字体。

> 顺带一提:Terminal.app 不会做字体回退(fallback),一旦选错/没选到 Nerd Font,Starship 的图标就直接是豆腐块 □。这也是为什么有人在 VSCode 终端正常、在系统终端却豆腐 —— 两个客户端各自的字体设置不同,与服务器、与 Ghostty 配置都无关。

---

## 第 4 步:CLI 工具

这是这套环境的精华 —— 一批现代命令行工具,替代老旧的 `ls`/`cat`/`find`/`grep` 等。

**一次性检查哪些没装:**

```bash
for t in bat eza fd ripgrep btop zoxide jq tldr git-delta lazygit fzf; do
  if brew list "$t" &>/dev/null; then echo "✅ $t"; else echo "❌ $t  (未装)"; fi
done
```

**装所有缺的(已装的会自动跳过):**

```bash
brew install bat eza fd ripgrep btop zoxide jq tldr git-delta lazygit fzf
```

每个工具是干嘛的:

| 工具 | 作用 | 替代 |
|------|------|------|
| `bat` | 带语法高亮和行号的文件查看 | `cat` |
| `eza` | 带图标、git 状态、树形的列目录 | `ls` |
| `fd` | 更快更直观的文件查找 | `find` |
| `ripgrep`(命令是 `rg`) | 极快的全文搜索 | `grep` |
| `btop` | 漂亮的系统监控 | `top` |
| `zoxide`(命令是 `z`) | 会学习习惯的智能 `cd` | `cd` |
| `jq` | JSON 处理 | — |
| `tldr` | 带例子的简化版 man | `man` |
| `git-delta`(命令是 `delta`) | 带语法高亮的 git diff | — |
| `lazygit`(命令是 `lazygit`) | Git 的终端 UI | — |
| `fzf` | 模糊查找器(Ctrl+R 搜历史等) | — |

> 这些命令的别名(让 `ls` 自动变成 `eza` 等)在 [第 6 步](#-第-6-步选你的-shell--分叉点) 写进 shell 配置后才生效。

---

## 第 5 步:Starship 提示符

Starship 是跨 shell 的提示符(就是你命令行最左边那段彩色的东西),Fish 和 Zsh 共用**同一份配置**。这也是为什么我们不用 Oh My Zsh 主题或 Powerlevel10k —— 一份配置两个 shell 都能用。

检查:

```bash
starship --version
```

没装就装:

```bash
brew install starship
```

**放配置文件**(Catppuccin Mocha 主题,Fish/Zsh 通用):

```bash
mkdir -p ~/.config

# 已有配置先备份
[ -f ~/.config/starship.toml ] && cp ~/.config/starship.toml ~/.config/starship.toml.bak.$(date +%s)
```

然后把 `terminal-setup` 仓库里的 `configs/starship.toml` 复制过来。如果你本地有 `terminal-setup` 仓库:

```bash
cp /路径/到/terminal-setup/configs/starship.toml ~/.config/starship.toml
```

> 没有仓库的话,从 [terminal-setup/configs/starship.toml](https://github.com/lewislulu/terminal-setup/blob/main/configs/starship.toml) 下载这份文件放到 `~/.config/starship.toml` 即可。它定义了那条彩色 powerline 风格的提示符。

⚠️ **现在还看不到效果** —— Starship 需要在 shell 配置里 `init` 才会启用。下一步选完 shell 后就生效了。

---

## 👉 第 6 步:选你的 Shell —— 分叉点

到这里公用部分结束。**根据第 0 节的决策选一条路径走:**

- 想要兼容性、和已有 zsh 经验衔接 → **[路径 A:Zsh](#路径-azsh)**
- 想要零配置开箱即用 → **[路径 B:Fish](#路径-bfish)**

> 两条都想试也行 —— 先走完一条,验证没问题,以后想换再走另一条(换默认 shell 用 `chsh` 即可,配置互不影响)。

---

### 路径 A:Zsh

macOS **自带 Zsh**,所以不用装 shell 本体,只要装 3 个插件 + 放配置。

#### A-1. 装 3 个 Zsh 插件

检查:

```bash
for p in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
  if brew list "$p" &>/dev/null; then echo "✅ $p"; else echo "❌ $p"; fi
done
```

装缺的:

```bash
brew install zsh-autosuggestions zsh-syntax-highlighting zsh-completions
```

- `zsh-autosuggestions` —— 打字时灰色显示历史里匹配的命令,按 → 补全
- `zsh-syntax-highlighting` —— 命令合法变绿、非法变红
- `zsh-completions` —— 更全的 Tab 补全

> 注意:这是 **Homebrew 装的**,装在 `/opt/homebrew/share/`(Apple 芯片),**不是** `git clone` 到 `~/.oh-my-zsh/`。这就是和你服务器 Oh My Zsh 的最大区别。

#### A-2. 设 Zsh 为默认 shell

macOS 新系统默认就是 zsh,确认一下:

```bash
echo $SHELL   # 看到 /bin/zsh 就已经是了
```

如果不是 zsh,切过去:

```bash
chsh -s $(which zsh)
```

(切换后要**重开终端窗口**才生效。)

#### A-3. 放 `.zshrc` 配置

这份 `.zshrc` 会把前面装的所有东西(插件、Starship、fzf、zoxide、别名)串起来。

```bash
# 备份你现有的 .zshrc(重要!尤其你之前配过 Oh My Zsh)
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak.$(date +%s)
```

> ### ⚠️⚠️ 千万别直接覆盖!先看你现有的 `.zshrc` 里有没有要保留的东西
>
> 很多人(尤其装过 conda/Anaconda 的)现有 `.zshrc` 里有**绝不能丢**的个人配置。先看一眼:
>
> ```bash
> cat ~/.zshrc
> ```
>
> 重点找这几样,**它们必须保留**:
> - **conda 初始化块**(`# >>> conda initialize >>>` 到 `# <<< conda initialize <<<`)—— 丢了 `conda` / `(base)` 就废了
> - 镜像/代理类环境变量(如 `HF_ENDPOINT`、`http_proxy`)
> - 语言运行时(`bun`、`nvm`、`pyenv`、`rbenv` 等)的 init / PATH / 补全
> - 你自己加的 PATH(如 `export PATH="$HOME/.local/bin:$PATH"`)
>
> **正确做法是「合并」而不是「覆盖」:**
> 1. 用仓库的 `configs/.zshrc` 作为新主体(Starship + 插件 + 别名那套)
> 2. 把上面那些个人块**原样粘贴**到新 `.zshrc` 中部(建一个「个人配置」区,见下方示例)
> 3. **conda 块和 `bun`/`openclaw` 等补全**放在靠后,但要在最后的 `zsh-syntax-highlighting` 那段**之前**
> 4. 旧的 Oh My Zsh 框架部分(`export ZSH=...`、`plugins=(...)`、`source $ZSH/oh-my-zsh.sh`)新配置不再需要 —— 可以删,也可以**注释掉留作备查**(想以后切回 OMZ 方便)
>
> 实战参考:本仓库这台机器就是这么合并的,结构如下 ——
> ```zsh
> # … 仓库 .zshrc 主体(Homebrew/Starship/插件/fzf/zoxide/别名/pnpm)…
>
> # ═══ 个人配置(从旧 .zshrc 迁移,保持启用)═══
> export HF_ENDPOINT="https://hf-mirror.com"      # 你的环境变量
> [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"   # bun 补全
> export PATH="$HOME/.local/bin:$PATH"
> # >>> conda initialize >>> … # <<< conda initialize <<<   ← 整块照搬
>
> # ═══ zsh-syntax-highlighting(必须在最后)═══
> source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
>
> # ═══ 旧 Oh My Zsh 配置(已注释保留,可回退)═══
> # export ZSH="$HOME/.oh-my-zsh"
> # plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)
> # source $ZSH/oh-my-zsh.sh
> ```

**如果你的 `.zshrc` 是空的 / 全新机器**,没有要保留的东西,才可以直接复制仓库的 `configs/.zshrc`:

```bash
cp /路径/到/terminal-setup/configs/.zshrc ~/.zshrc
```

> 没有仓库就从 [terminal-setup/configs/.zshrc](https://github.com/lewislulu/terminal-setup/blob/main/configs/.zshrc) 下载。

这份 `.zshrc` 里都干了啥(看一眼有数):
- 自动检测 Homebrew 路径(Apple 芯片 `/opt/homebrew` / Intel `/usr/local`)
- `eval "$(starship init zsh)"` —— 启用 Starship 提示符
- `source` 那两个插件(autosuggestions 在前、syntax-highlighting 在最后)
- 配好历史记录、↑/↓ 前缀搜索
- `eval "$(fzf --zsh)"` —— Ctrl+R / Ctrl+T / Alt+C
- `eval "$(zoxide init zsh)"` —— 智能 cd
- 别名:`ls→eza`、`cat→bat`、`find→fd`、`grep→rg`、`top→btop`、`lg→lazygit`
- `set-ssh-key` 函数(多 SSH key 切换)

> 改完后用 `zsh -n ~/.zshrc` 做个语法检查(无输出 = 没语法错误),再 `source` 或重开窗口,避免把 shell 搞坏。

#### A-4. 生效

```bash
source ~/.zshrc
```

或者直接**关掉终端重开一个新窗口**。这时你应该看到那条彩色的 Starship 提示符了 🎉

➡️ 跳到 [第 7 步:git-delta](#第-7-步git-delta美化-git-diff)。

---

### 路径 B:Fish

Fish 需要先装 shell 本体,然后放配置(自动补全和高亮是内置的,不用装插件)。

#### B-1. 装 Fish

```bash
fish --version          # 检查
brew install fish       # 没装就装
```

#### B-2. 设 Fish 为默认 shell

先把 fish 加进系统允许的 shell 列表,再切换:

```bash
# 1) 加入 /etc/shells(需要 sudo,输你的开机密码)
echo "$(which fish)" | sudo tee -a /etc/shells

# 2) 设为默认
chsh -s "$(which fish)"
```

(切换后**重开终端窗口**才生效。)

> 不想改默认 shell?也可以保持 zsh 为默认,只在需要时手动敲 `fish` 进入。但那样 Ghostty 一开还是 zsh。

#### B-3. 放 `config.fish` 配置

Fish 的配置在 `~/.config/fish/config.fish`:

```bash
mkdir -p ~/.config/fish

# 备份现有配置
[ -f ~/.config/fish/config.fish ] && cp ~/.config/fish/config.fish ~/.config/fish/config.fish.bak.$(date +%s)

# 复制仓库里的基础配置
cp /路径/到/terminal-setup/configs/config.fish ~/.config/fish/config.fish
```

> 没有仓库就从 [terminal-setup/configs/config.fish](https://github.com/lewislulu/terminal-setup/blob/main/configs/config.fish) 下载。

#### B-4. 补上别名、zoxide、fzf 初始化

仓库的基础 `config.fish` 里有 Homebrew/Starship/fnm/ssh,但**别名和 zoxide/fzf 初始化是 `setup.sh` 运行时追加的**。人工安装要自己补上 —— 把下面这段**追加**到 `~/.config/fish/config.fish` 末尾:

```bash
cat >> ~/.config/fish/config.fish <<'EOF'

# 别名(Fish 用 abbr,兼容 3.x 和 4.x)
if status is-interactive
    abbr -a ls "eza --icons --group-directories-first"
    abbr -a ll "eza -la --icons --group-directories-first"
    abbr -a lt "eza --tree --icons --level=2"
    abbr -a cat "bat"
    abbr -a find "fd"
    abbr -a grep "rg"
    abbr -a top "btop"
    abbr -a lg "lazygit"
    abbr -a cd "z"
end

# zoxide(智能 cd)
zoxide init fish | source

# fzf(Ctrl+R / Ctrl+T / Alt+C)
fzf --fish | source
set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'
if command -q fd
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
end
EOF
```

> 基础 `config.fish` 里已经有 `starship init fish`,所以 Starship 提示符会自动启用,不用额外加。

#### B-5. 生效

```bash
exec fish
```

或重开终端窗口。应该能看到彩色 Starship 提示符,打字有灰色补全建议(fish 内置的)🎉

➡️ 继续 [第 7 步:git-delta](#第-7-步git-delta美化-git-diff)。

---

## 第 7 步:git-delta(美化 git diff)

第 4 步装了 `git-delta`,但还要告诉 git「用 delta 当 diff 工具」。这步对 Fish/Zsh 都一样(改的是 git 全局配置,跟 shell 无关):

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

验证:进任意一个 git 仓库改点东西,`git diff` 应该是彩色、带行号、并排显示的。

> 这些设置**永久写在 `~/.gitconfig` 里**(git 只读这个文件,**不读 `.zshrc`**),跑一次就行,不会丢。

### (可选)让配置随 `.zshrc` 一起带走

上面的命令把配置存进了 `~/.gitconfig`。如果你希望**换机器时一份 `.zshrc` 就自动把 git-delta 也配好**,可以在 `.zshrc` 里加一个**幂等兜底块**(只在还没配置时才写入,不拖慢启动):

```zsh
# ─── git-delta(幂等兜底:仅在未配置 delta 时自动写入 ~/.gitconfig)───
if command -v delta &>/dev/null && [[ "$(git config --global --get core.pager 2>/dev/null)" != "delta" ]]; then
    git config --global core.pager delta
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
    git config --global delta.dark true
    git config --global delta.line-numbers true
    git config --global delta.side-by-side true
    git config --global merge.conflictstyle diff3
    git config --global diff.colorMoved default
fi
```

> 注意:这段**不是 git 的配置本身**(git 永远只读 `~/.gitconfig`),而是「确保 `.gitconfig` 被配好」的脚本。它有 `core.pager != delta` 的判断,所以你日后手动改 delta 设置不会被它覆盖。**纯本机用、不在乎换机器** 的话,这段加不加都行 —— 第 7 步那 8 条命令已经够了。

---

## 第 8 步(可选):fnm + Node.js

`fnm` 是 Rust 写的极速 Node 版本管理器(替代 nvm)。

> ⚠️ **先想清楚再装!** fnm 会管理自己的 Node 版本,可能**遮蔽**你已有的 Node/npm(比如通过 Homebrew、nvm 装的,或全局装的 Claude Code、pnpm 包)。**只有你需要管理多个 Node 版本时才装。**

如果确定要装:

```bash
brew install fnm
```

`init` 已经写在第 6 步的 shell 配置里了(`.zshrc` / `config.fish` 都有 `fnm env --use-on-cd`),所以装完重开终端就能用:

```bash
fnm install --lts        # 装最新 LTS 版 Node
fnm default lts-latest    # 设为默认
fnm use lts-latest        # 当前 shell 切过去
node --version            # 验证
```

> 进到带 `.node-version` 或 `.nvmrc` 文件的目录会自动切版本(`--use-on-cd`)。

---

## 第 9 步(可选):Zellij 终端复用器

类似 tmux,但 UX 更现代(底部有快捷键提示)。不需要可跳过。

```bash
zellij --version       # 检查
brew install zellij    # 没装就装
zellij                 # 启动
```

---

## 第 10 步:验证一切正常

重开一个 Ghostty 窗口,逐项确认:

```bash
# 1) 提示符是彩色 powerline 风格(Starship + Nerd Font 生效)
#    —— 直接看左边那条彩色的就行,图标不是豆腐块

# 2) 现代工具就位
eza --icons        # 带图标的 ls
bat README.md      # 带高亮的 cat(随便找个文件)
z --version        # zoxide
rg --version       # ripgrep

# 3) 别名生效(应该指向新工具)
type ls            # zsh: 显示 alias / fish: 显示 abbr
                   # 期望看到 eza --icons --group-directories-first

# 4) fzf 快捷键 —— 按 Ctrl+R,应弹出模糊搜索历史的界面

# 5) Starship 提示符确实是 starship
#    zsh: echo $STARSHIP_SHELL  →  zsh
```

**检查清单:**

- [ ] Ghostty 打开后提示符是彩色的,**没有豆腐块 □**(字体生效)
- [ ] 打字时有**灰色补全建议**(zsh 的 autosuggestions / fish 内置)
- [ ] 命令合法变**绿**、敲错变**红**(syntax highlighting)
- [ ] `ls` 显示**图标和颜色**(eza 别名)
- [ ] `Ctrl+R` 弹出 **fzf 模糊搜索**
- [ ] `git diff` 是**彩色并排**的(delta)

全打勾就完事了 🎉

---

## 常见问题 FAQ

**Q: 提示符里全是方块 □ / 问号 / 乱码?**
A: Nerd Font 没装或 Ghostty 没用上,或**字体名填错**。确认第 3 步装了 Meslo Nerd Font,且 Ghostty 配置里的 `font-family` 和 `ghostty +list-fonts | grep -i meslo` 列出的名字**完全一致**(Homebrew cask 装的是 `MesloLGS Nerd Font Mono`,不是 `MesloLGS NF`),然后**重启 Ghostty**。

**Q: `source ~/.zshrc` 报错 `command not found: starship`(或 eza/zoxide 等)?**
A: 那个工具还没装,或者 Homebrew 不在 PATH 里。先 `brew --version` 确认 brew 能用,再 `brew install <工具名>` 补上。Apple 芯片确保 `~/.zprofile` 里有 `eval "$(/opt/homebrew/bin/brew shellenv)"`。

**Q: 我之前在这台 Mac 上装过 Oh My Zsh,会冲突吗?**
A: 不会自动冲突,但**别同时用**。本教程的 `.zshrc` 不加载 Oh My Zsh。如果你想彻底切过来,用本教程的 `.zshrc` 即可(旧的已备份成 `.zshrc.bak.*`)。想保留 Oh My Zsh 就别覆盖 `.zshrc`,但那样这套配置不生效。

**Q: 改了默认 shell(`chsh`)没生效?**
A: 必须**完全关掉终端窗口重开**(不是 `source`)。还不行就检查 `echo $SHELL`,以及 `/etc/shells` 里有没有那个 shell 的路径。

**Q: 装了 fnm 之后,我原来的 `node` / `npm` / 全局命令(如 claude)不见了?**
A: 这就是第 8 步警告的「遮蔽」问题。fnm 接管了 Node。要么 `fnm use` 一个版本再重装全局包,要么卸载 fnm(`brew uninstall fnm` 并删掉 shell 配置里的 fnm 那段)恢复原来的 Node。

**Q: 想从 Zsh 换成 Fish(或反过来)?**
A: 直接 `chsh -s "$(which fish)"`(或 `$(which zsh)`),重开终端。两份配置文件互不影响,Starship/字体/工具都是共用的,换 shell 不用重装任何东西。

---

## 附:这套环境的日常用法

别名、快捷键、fnm、SSH key 切换等日常速查,见同目录的 **[cheatsheet.md](./cheatsheet.md)**。

---

## 附录:本机实际配置记录(2026-05-29)

> 这台 Mac(Apple 芯片,Homebrew 在 `/opt/homebrew`)按本教程实际跑过一遍的结果,留作回溯。你的机器照着正文做即可,本节仅作参考。

### 已完成

| 步骤 | 状态 | 实际情况 / 注意点 |
|------|------|------------------|
| 1. Homebrew | ✅ | 已装 |
| 2. Ghostty 配置 | ✅ | `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` |
| 3. Nerd Font | ✅ | `brew install --cask font-meslo-lg-nerd-font` |
| 4. CLI 工具(11 个) | ✅ | bat / eza / fd / ripgrep / btop / zoxide / jq / tldr / git-delta / lazygit / fzf 全装 |
| 5. Starship | ✅ | v1.25.1;配置复制自 `terminal-setup/configs/starship.toml` |
| 6. Shell = **Zsh** | ✅ | 装了 3 个插件;`.zshrc` 用**合并方案**(见下) |
| 7. git-delta | ✅ | 写入 `~/.gitconfig`,并在 `.zshrc` 加了幂等兜底块 |
| 8. fnm / 9. Zellij | ⬜ 未装 | 可选,按需再装 |

### 三个关键决策(和正文默认不同的地方)

1. **字体名修正为 `MesloLGS Nerd Font Mono`**
   一开始 Ghostty 配置写的是 `MesloLGS NF`,但 Homebrew cask 装出来的字体族名其实是 `MesloLGS Nerd Font Mono`,两者不一致会导致字体回退。已用 `ghostty +list-fonts` 确认真实族名后改正。详见 [第 2 步](#第-2-步ghostty-配置已装只配) / [第 3 步](#第-3-步nerd-font-字体)。

2. **`.zshrc` 用「合并」而非「覆盖」**
   旧 `.zshrc` 是 Oh My Zsh 配置,含必须保留的个人块。最终结构:
   - 主体 = 仓库 `configs/.zshrc`(Starship + 插件 + 别名)
   - 中部「个人配置」区(保持启用):**conda 初始化块**、HuggingFace 镜像(`HF_ENDPOINT` 等)、`bun`、`~/.local/bin`、OpenClaw 补全
   - `zsh-syntax-highlighting` 放最后
   - **旧 Oh My Zsh 框架部分:注释保留在文件底部**(可回退,未删除)
   - 旧备份在 `~/.zshrc.bak.*`
   详见 [第 6 步 · 路径 A](#路径-azsh)。

3. **git-delta 既写 `~/.gitconfig` 也写 `.zshrc`**
   除了 `git config --global` 写进 `~/.gitconfig`,还在 `.zshrc` 加了幂等兜底块(仅在未配置时自动写入),方便换机器时随 `.zshrc` 带走。详见 [第 7 步](#第-7-步git-delta美化-git-diff)。

### 回退方法

- **Ghostty 配置**:`~/Library/Application Support/com.mitchellh.ghostty/config.ghostty.bak.*`
- **`.zshrc`**:`cp ~/.zshrc.bak.<时间戳> ~/.zshrc`,或取消文件底部 Oh My Zsh 注释、注释掉新配置
- **git-delta**:`git config --global --unset core.pager`(及其他 `delta.*` 项)
