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

待补充。
