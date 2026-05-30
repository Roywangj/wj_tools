# 🧾 终端环境日常速查

装完 [README.md](./README.md) 里的环境后,日常就用这些。

## 别名 / 缩写

装好 shell 配置后,这些老命令会自动指向新工具:

| 你敲 | 实际执行 | 说明 |
|------|----------|------|
| `ls` | `eza --icons --group-directories-first` | 带图标、目录排前面 |
| `ll` | `eza -la --icons --group-directories-first` | 长格式 + 隐藏文件 |
| `lt` | `eza --tree --icons --level=2` | 树形视图(2 层) |
| `cat` | `bat` | 语法高亮 + 行号 |
| `find` | `fd` | 更快更直观 |
| `grep` | `rg` | ripgrep,极快 |
| `top` | `btop` | 漂亮的系统监控 |
| `lg` | `lazygit` | Git 终端 UI |
| `cd`(仅 Fish) | `z` | zoxide 智能跳转 |

> 想用回原版命令?加反斜杠:`\ls`、`\cat`,或全路径 `/bin/ls`。

## fzf 快捷键

| 按键 | 功能 |
|------|------|
| `Ctrl + R` | 模糊搜索命令历史 |
| `Ctrl + T` | 模糊查找文件(用 fd 当后端) |
| `Alt + C` | 模糊进入子目录 |

## zoxide(智能 cd)

```bash
z proj           # 跳到最常去的、路径含 "proj" 的目录
z foo bar        # 多关键词匹配
zi               # 交互式选择(fzf 界面)
z -              # 回到上一个目录
```

> 用几天后它就学会你的习惯了,`z 项目名` 直接跳过去,不用敲全路径。

## fnm —— Node 版本管理

```bash
fnm install 22            # 装 Node 22
fnm install --lts         # 装最新 LTS
fnm default 22            # 设默认版本
fnm use 22                # 当前 shell 切过去
fnm list                  # 看已装版本
echo "22" > .node-version # 放进项目目录,进去自动切版本
```

## SSH key 切换

两个 shell 配置都内置了 `set-ssh-key` 函数:

```bash
set-ssh-key my-key-name   # 清空 agent,加载 ~/.ssh/my-key-name
set-ssh-key                # key 不存在时,列出所有可用 key
```

> **更推荐**的做法:在 `~/.ssh/config` 里用 `Host` 别名 + `IdentitiesOnly yes` 让 git/ssh 自动匹配。`set-ssh-key` 是兜底方案。

## git + delta

配好后这些 git 命令自动变成彩色、带行号、并排显示:

```bash
git diff          # 彩色并排 diff
git show          # 同上
lazygit           # 或敲 lg —— 全键盘的 git TUI
```

lazygit 里常用键:`空格` 暂存、`c` 提交、`P` push、`p` pull、`?` 看全部快捷键。

## Ghostty 常用快捷键(macOS)

| 按键 | 功能 |
|------|------|
| `Cmd + T` | 新标签页 |
| `Cmd + D` | 垂直分屏 |
| `Cmd + Shift + D` | 水平分屏 |
| `Cmd + [ / ]` | 在分屏间切换 |
| `Cmd + Shift + ,` | 重新加载配置 |
| `Cmd + K` | 清屏 |

## 改配置文件去哪

| 想改 | 文件 |
|------|------|
| Ghostty(字体/主题/窗口) | `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` |
| 提示符样式 | `~/.config/starship.toml` |
| Zsh(别名/函数/PATH) | `~/.zshrc` |
| Fish(别名/函数/PATH) | `~/.config/fish/config.fish` |

改完 shell 配置后 `source ~/.zshrc`(zsh)或 `exec fish`(fish)生效;改 Ghostty/starship 重开窗口或重载即可。
