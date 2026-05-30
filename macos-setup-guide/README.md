# 🖥️ macOS 终端环境配置

把 macOS 终端打造成现代化、好看又好用的开发环境。目标终端栈:

> **Ghostty**(终端)+ **Fish 或 Zsh**(shell)+ **Starship**(提示符)+ **Nerd Font**(字体)+ **一堆现代 CLI 工具**(bat / eza / fd / ripgrep / fzf / zoxide / delta / lazygit …)

本指南对应 [`terminal-setup`](https://github.com/lewislulu/terminal-setup) 仓库 `setup.sh` 的 macOS 流程,但拆成**人工一步步执行**的版本。每一步都先给「检查是否已装」的命令,装过的部分会自动跳过。

**前提假设:**
- ✅ 已**手动装好 Ghostty**(`/Applications/Ghostty.app` 存在)
- ✅ 可能已装了一部分工具(不影响,每步都会自查)
- ❓ 还在纠结 **Fish 还是 Zsh** → 看 [第 0 节](./shell-config.md#第-0-节先搞懂-fish-vs-zsh解决你的困惑)

---

## 📂 这个文件夹有什么

| 文件 | 用途 |
|------|------|
| **README.md**(本文件) | 总览 + 各步骤快速跳转 |
| **[shell-config.md](./shell-config.md)** | 👉 手把手安装**完整正文**(所有命令、说明、踩坑) |
| **[ubuntu-shell-config.md](./ubuntu-shell-config.md)** | 🐧 上面这套的 **Linux 服务器版**(SSH 连服务器时用) |
| **[cheatsheet.md](./cheatsheet.md)** | 装完后的日常速查(别名 / 快捷键 / fnm / SSH key) |

---

## 🚀 安装步骤(点击跳转到正文)

公用步骤(1–5)做完,再到第 6 步选 Zsh 或 Fish 其中一条走。

| 步骤 | 内容 | 跳转 |
|------|------|------|
| 第 0 节 | 先搞懂 **Fish vs Zsh**(解决选择困惑) | [→](./shell-config.md#第-0-节先搞懂-fish-vs-zsh解决你的困惑) |
| 第 1 步 | **Homebrew** 包管理器 | [→](./shell-config.md#第-1-步homebrew包管理器) |
| 第 2 步 | **Ghostty** 配置(主题 / 字体 / 窗口) | [→](./shell-config.md#第-2-步ghostty-配置已装只配) |
| 第 3 步 | **Nerd Font** 字体 | [→](./shell-config.md#第-3-步nerd-font-字体) |
| 第 4 步 | **CLI 工具**(bat / eza / fd / fzf …) | [→](./shell-config.md#第-4-步cli-工具) |
| 第 5 步 | **Starship** 提示符 | [→](./shell-config.md#第-5-步starship-提示符) |
| 👉 第 6 步 | **选 Shell** —— 分叉点 | [→](./shell-config.md#-第-6-步选你的-shell--分叉点) |
| &nbsp;&nbsp;路径 A | Zsh(自带、兼容 POSIX、衔接已有经验) | [→](./shell-config.md#路径-azsh) |
| &nbsp;&nbsp;路径 B | Fish(零配置、开箱即用) | [→](./shell-config.md#路径-bfish) |
| 第 7 步 | **git-delta**(美化 git diff) | [→](./shell-config.md#第-7-步git-delta美化-git-diff) |
| 第 8 步 | (可选)**fnm** + Node.js | [→](./shell-config.md#第-8-步可选fnm--nodejs) |
| 第 9 步 | (可选)**Zellij** 终端复用器 | [→](./shell-config.md#第-9-步可选zellij-终端复用器) |
| 第 10 步 | **验证**一切正常 | [→](./shell-config.md#第-10-步验证一切正常) |
| FAQ | 常见问题(豆腐块 / shell 切换 / conda…) | [→](./shell-config.md#常见问题-faq) |

---

## ⚡ Fish 还是 Zsh?一句话版

- 经常 `git clone` 别人项目、复制 `bash` 一行命令、跑 `.sh` 脚本 → **Zsh**(macOS 自带、POSIX 兼容)
- 想要最干净的开箱体验,不介意偶尔 `bash script.sh` → **Fish**(自动补全 / 高亮全内置)
- 拿不定 → 默认 **Zsh**。两条路径正文都写了,换 shell 不用重装任何东西。

> 注意:这套 Zsh 配置**不用 Oh My Zsh 框架**,而是纯 zsh + Homebrew 装的 3 个插件 + Starship,启动更快。详见 [第 0 节](./shell-config.md#第-0-节先搞懂-fish-vs-zsh解决你的困惑)。

---

📖 **开始安装 → [shell-config.md](./shell-config.md)**

---

## 🐧 在 Linux 服务器上也想要同款环境?

如果你常通过 **VSCode 终端 / Termius / SSH** 连实验室或云上的 **Ubuntu 服务器**,可以照 [**ubuntu-shell-config.md**](./ubuntu-shell-config.md) 把服务器也配成 **Zsh + Starship + 现代 CLI 工具** 的环境。它是本 macOS 指南的服务器版,步骤编号一一对应,主要差异:

- **不用装终端 / 字体**:终端在你本地(Ghostty 等),服务器端只配 shell;Starship 用**纯文本符号**预设,任何字体都不出豆腐块。
- **无 sudo 也能装**:共享服务器子用户可用 conda 或下载二进制到 `~/.local/bin`。
- **合并而非覆盖 `.zshrc`**:完整保留服务器上的 CUDA / conda / 代理等个人配置。
- 想保留 Oh My Zsh 框架的话,基础安装见 `server_install/ohmyzsh.md`。

> 字体只装在**客户端**、服务器装无效;如果你用 Ghostty SSH 后遇到「一输入就 `❯` 变暗 / 补全错乱」,排错见本目录 [shell-config.md](./shell-config.md) 第 2 步的「关键坑」一节。
