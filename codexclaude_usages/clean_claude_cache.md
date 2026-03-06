# Claude / Anthropic API 残留清理记录

当前重点平台：`macOS`

后续可补充平台：`Linux`

## macOS

日期：2026-03-06
环境：`macOS` + `zsh` + `Cursor` + `conda(base)`

### 现象

本机存在以下 Claude / Anthropic 相关残留：

- 当前 shell 环境变量中存在：
  - `ANTHROPIC_BASE_URL`
  - `ANTHROPIC_AUTH_TOKEN`
  - `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`
- `~/.zshrc` 中留有相关配置和注释残留
- `~/.zsh_history` 中留有 Claude 相关命令历史
- `~/.claude` 目录存在
- `~/Library/Application Support/Cursor/logs` 下存在 `Anthropic.claude-code` 相关日志目录

### 实际清理过程

#### 1. 定位残留

先检查环境变量：

```bash
printenv | grep -E 'ANTHROPIC|CLAUDE'
```

检查 shell 配置和历史：

```bash
grep -n -E 'ANTHROPIC|CLAUDE|claude|anthropic' ~/.zshrc ~/.zsh_history
```

检查本地配置和日志目录：

```bash
find ~/.claude ~/Library/Application\ Support/Cursor -iname '*claude*' -o -iname '*anthropic*'
```

#### 2. 删除磁盘残留

已完成的清理内容：

- 从 `~/.zshrc` 删除 Claude / Anthropic 相关配置行和注释残留
- 从 `~/.zsh_history` 过滤掉 Claude / Anthropic 相关命令
- 删除 `~/.claude`
- 删除 Cursor 下 `Anthropic.claude-code` 相关日志目录
- 尝试清除用户会话中的同名环境变量

对应执行思路如下：

```bash
# 清理 zsh 配置和历史
# 删除 ~/.claude
# 删除 Cursor 的 Anthropic.claude-code 日志目录
# 尝试 unset launchctl 环境变量
```

说明：

- 文件级残留已经清除
- `launchctl unsetenv` 只能处理会话级环境，不会强制改写已经在运行中的 shell 进程

#### 3. 处理当前终端中的环境变量

即使磁盘残留已清除，当前终端仍可能保留已经加载进内存的变量。此时需要在当前 shell 执行：

```bash
unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
```

然后验证：

```bash
printenv | grep -E 'ANTHROPIC|CLAUDE'
```

如果还有输出，通常说明该终端是旧会话，或变量来自父进程。

#### 4. 重新打开终端验证

新开终端后再次执行：

```bash
printenv | grep -E 'ANTHROPIC|CLAUDE'
```

结果：没有任何输出。

这说明：

- 启动文件中的残留已经清除
- 新 shell 不再自动注入 Claude / Anthropic 变量
- 本地清理已经生效

### 结论

本次清理后，以下残留已处理完毕：

- shell 配置残留
- shell 历史残留
- `~/.claude` 本地目录
- Cursor 的 Claude 相关日志目录
- 新终端中的 Claude / Anthropic 环境变量注入

### 建议的最终收尾

建议再做两件事：

1. 废弃并重建原有 Anthropic token
2. 后续不要把 API key 直接写进命令行历史或 shell 配置文件

更安全的做法：

- 用临时环境变量
- 用 `.env` 文件配合本地忽略规则
- 用系统凭据管理器保存敏感信息

### 快速复查命令

```bash
printenv | grep -E 'ANTHROPIC|CLAUDE'
grep -n -E 'ANTHROPIC|CLAUDE|claude|anthropic' ~/.zshrc ~/.zsh_history
test -d ~/.claude && echo "exists" || echo "removed"
find ~/Library/Application\ Support/Cursor -path '*Anthropic.claude-code*'
```

如果这些命令没有命中相关内容，说明本地 Claude API 残留基本已经清理完成。

## Linux

日期：2026-03-06
账户：`wangjie01`
环境：`Linux` + `zsh`

### 当前账户已发现的 Claude 相关信息

本节为实际扫描结果，用于制定清理计划，以下内容不代表已经执行删除：

- 当前 shell 环境变量中仍存在：
  - `ANTHROPIC_AUTH_TOKEN`
  - `ANTHROPIC_BASE_URL`
  - `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`
- `~/.zshrc` 中存在 Claude / Anthropic 相关注释块，且保留过历史 token 文本
- `~/.zsh_history` 中存在 Claude CLI 安装、运行、`unset` 等命令历史
- 当前账户下存在以下本地残留路径：
  - `~/.local/bin/claude`
  - `~/.local/share/claude`
  - `~/.local/state/claude`
  - `~/.cache/claude`
  - `~/.cache/claude-cli-nodejs`
  - `~/.cursor-server/extensions/anthropic.claude-code-2.1.69-linux-x64`
  - `~/.vscode-server/extensions/anthropic.claude-code-2.1.63-linux-x64`
- 额外发现一个第三方工具依赖目录：`~/.cache/opencode/node_modules/opencode-anthropic-auth`
- 当前未发现 `wangjie01` 账户正在运行的 `claude` / `anthropic` 相关进程

### 清理目标

目标不是只删除 `claude` 命令，而是清除当前账户下与 Claude / Anthropic 相关的以下信息：

- 会话级环境变量
- shell 启动文件中的配置残留和明文 token 注释
- shell 历史中的相关命令痕迹
- Claude CLI 的安装、缓存、状态目录
- Cursor / VSCode Server 中的 Claude 扩展残留

### 建议执行计划

#### 1. 先做备份，再清理

建议先备份会被改写的 shell 文件，避免误删普通配置：

```bash
cp ~/.zshrc ~/.zshrc.bak.$(date +%F-%H%M%S)
cp ~/.zsh_history ~/.zsh_history.bak.$(date +%F-%H%M%S)
```

如果系统中存在 `~/.bashrc` 或 `~/.bash_history`，也建议一并备份。

#### 2. 清除当前 shell 中已加载的 Claude 相关变量

先清当前会话，避免删除磁盘文件后当前终端里变量还继续存在：

```bash
unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
printenv | grep -E 'ANTHROPIC|CLAUDE'
```

如果还有输出，说明变量来自父进程或旧 shell，会在后续重开终端后再次验证。

#### 3. 清理 shell 启动文件中的配置残留

重点检查并编辑以下文件：

```bash
rg -n -i 'anthropic|claude' ~/.zshrc ~/.bashrc ~/.profile
```

当前已知至少要处理 `~/.zshrc` 中的 Claude 配置注释块。建议做法：

- 删除所有 `ANTHROPIC_*` / `CLAUDE_*` 配置行
- 删除包含历史 token 的注释行，不要只保留注释
- 确认没有其他 alias、function、source 语句继续注入这些变量

可用编辑器手动处理：

```bash
$EDITOR ~/.zshrc
```

#### 4. 清理 shell 历史中的 Claude 痕迹

当前已知 `~/.zsh_history` 中存在 `claude`、安装脚本、`unset ANTHROPIC_*` 等历史。建议过滤后重载：

```bash
grep -viE 'ANTHROPIC|CLAUDE|claude|anthropic' ~/.zsh_history > ~/.zsh_history.cleaned
mv ~/.zsh_history.cleaned ~/.zsh_history
fc -R ~/.zsh_history
```

如果你也使用过 bash，再检查：

```bash
test -f ~/.bash_history && grep -viE 'ANTHROPIC|CLAUDE|claude|anthropic' ~/.bash_history > ~/.bash_history.cleaned && mv ~/.bash_history.cleaned ~/.bash_history
```

#### 5. 删除 Claude CLI 本地安装、状态和缓存目录

当前账户下已发现的主要目录如下，建议一并删除：

```bash
rm -f ~/.local/bin/claude
rm -rf ~/.local/share/claude
rm -rf ~/.local/state/claude
rm -rf ~/.cache/claude
rm -rf ~/.cache/claude-cli-nodejs
```

说明：

- `~/.local/bin/claude` 当前是一个指向 `~/.local/share/claude/versions/...` 的符号链接
- 删除 `~/.local/share/claude` 后，再保留这个链接没有意义，因此建议一起删除

#### 6. 删除编辑器远程扩展残留

如果你的目标是“当前账户下不再保留 Claude 相关信息”，则建议同时删除扩展目录：

```bash
rm -rf ~/.cursor-server/extensions/anthropic.claude-code-*
rm -rf ~/.vscode-server/extensions/anthropic.claude-code-*
```

这一步会移除远程环境中的 Claude 扩展副本；后续如果还要继续使用，需要重新安装。

#### 7. 可选清理其他工具里的 Anthropic 依赖或缓存

扫描中还发现：

```bash
~/.cache/opencode/node_modules/opencode-anthropic-auth
```

这个路径更像第三方工具依赖，不一定属于 Claude CLI 本体。建议先确认是否仍在使用相关工具，再决定是否删除。若只追求“清除 Claude 本体痕迹”，这一步可以暂缓。

#### 8. 重开 shell 并做最终验证

建议关闭当前终端，重新打开一个新 shell 后执行：

```bash
printenv | grep -E 'ANTHROPIC|CLAUDE'
rg -n -i 'anthropic|claude' ~/.zshrc ~/.bashrc ~/.profile ~/.zsh_history ~/.bash_history
find ~/.local ~/.cache ~/.cursor-server ~/.vscode-server -maxdepth 4 \( -iname '*claude*' -o -iname '*anthropic*' \)
command -v claude || echo "claude binary removed"
ps -u "$USER" -f | rg -i 'claude|anthropic'
```

理想结果：

- `printenv` 没有任何 Claude / Anthropic 变量输出
- 启动文件与历史文件中不再命中相关关键字
- `~/.local`、`~/.cache`、`~/.cursor-server`、`~/.vscode-server` 下不再存在目标目录
- `command -v claude` 不再指向当前账户中的安装路径
- 当前账户下没有 `claude` 相关进程

### 清理后的安全收尾

即使本地文件都清掉了，仍建议补做以下动作：

1. 废弃并重建当前使用过的 `ANTHROPIC_AUTH_TOKEN`
2. 不再把 token 写入 `~/.zshrc`、命令行参数或 shell 历史
3. 后续改用 `.env` 文件配合忽略规则，或使用系统级凭据管理方案

### 推荐执行顺序

为减少残留反复写回，建议按这个顺序执行：

1. 备份 `~/.zshrc` 和 `~/.zsh_history`
2. `unset` 当前 shell 变量
3. 清理 `~/.zshrc` / `~/.bashrc` / `~/.profile`
4. 清理 `~/.zsh_history` / `~/.bash_history`
5. 删除 `~/.local/share/claude`、`~/.local/state/claude`、`~/.cache/claude*`
6. 删除 Cursor / VSCode Server 的 Claude 扩展目录
7. 重新打开终端并执行验证命令
8. 最后废弃旧 token 并换新

### 2026-03-06 实际执行记录

本节记录本次已经实际执行过的清理动作，区别于上面的计划。

#### 已执行的动作

- 先扫描了当前账户的环境变量、shell 启动文件、shell 历史、本地目录和编辑器扩展残留
- 临时备份了以下文件：
  - `~/.zshrc`
  - `~/.zsh_history`
  - `~/.bashrc`
  - `~/.bash_history`
  - `~/.profile`
- 从 `~/.zshrc` 删除了 Claude / Anthropic 配置注释块和历史明文 token 注释
- 过滤并重写了 `~/.zsh_history` 与 `~/.bash_history`，移除了 `claude`、`anthropic`、`ANTHROPIC_*` 等相关历史
- 删除了 Claude CLI 本地安装、状态和缓存：
  - `~/.local/bin/claude`
  - `~/.local/share/claude`
  - `~/.local/state/claude`
  - `~/.cache/claude`
  - `~/.cache/claude-cli-nodejs`
- 删除了编辑器侧残留：
  - `~/.cursor-server/extensions/anthropic.claude-code-2.1.69-linux-x64`
  - `~/.vscode-server/extensions/anthropic.claude-code-2.1.63-linux-x64`
  - `~/.vscode-server/data/CachedExtensionVSIXs/anthropic.claude-code-2.1.63-linux-x64`
  - `~/.cursor-server/data/logs/*/exthost*/Anthropic.claude-code`
  - `~/.vscode-server/data/logs/*/exthost*/Anthropic.claude-code`
- 清理完成后，删除了本次生成的 `.bak.2026-03-06-1115` 备份文件，避免备份本身继续保留敏感残留

#### 验证结果

- `~/.zshrc`、`~/.bashrc`、`~/.profile` 中不再命中 `anthropic|claude`
- `~/.zsh_history`、`~/.bash_history` 中不再命中 `anthropic|claude`
- `command -v claude` 已不再返回当前账户下的 Claude CLI 路径
- 当前账户下未发现运行中的 `claude` 进程
- 主配置和说明路径中，不再命中本次清理前出现过的历史 token 字符串和旧 `ANTHROPIC_BASE_URL`

#### 仍需用户手动完成的收尾

当前已经打开的终端或 IDE 进程中，环境变量仍可能驻留在内存里。实际验证时，当前会话环境里仍能看到：

- `ANTHROPIC_AUTH_TOKEN`
- `ANTHROPIC_BASE_URL`
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`

这是因为这些值来自已经运行中的父进程环境，删除磁盘文件后不会自动从现有进程内存中消失。

建议在当前终端执行：

```bash
unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
exec zsh -l
```

或者直接关闭并重新打开终端 / IDE。

#### 本次未处理的范围

- `opencode` 等第三方工具中，仅作为模型名、依赖名、日志内容或历史消息出现的 `claude` / `anthropic` 文本未删除
- 一些第三方包自带的 `CLAUDE.md` 文档文件未删除

原因：

- 这些内容不属于 Claude CLI 本体残留
- 强行删除可能破坏其他工具的配置、依赖或历史数据
