# Claude 全局安装 Codex MCP Server

`claude mcp add codex npx -y codex mcp-server` 默认更接近“当前项目可用”的配置思路。  
如果希望在所有仓库里都能直接使用 Codex MCP，更稳妥的做法是把配置写到 Claude Code 的全局配置目录。

## 目标

让 Claude Code 在任意项目中都能加载 `codex` 这个 MCP server。

## 1. 先确认 Codex CLI 已全局安装

安装：

```bash
npm install -g @openai/codex
```

验证：

```bash
codex --version
```

如果命令能正常返回版本号，说明 `codex` 已经在全局 `PATH` 中可用。

## 2. 配置 Claude Code 全局 MCP

Claude Code 的全局 MCP 配置文件：

```text
~/.claude/mcp.json
```

如果文件不存在，就创建它。

推荐内容如下：

```json
{
  "mcpServers": {
    "codex": {
      "command": "codex",
      "args": ["mcp-server"]
    }
  }
}
```

这表示 Claude Code 会通过本机的全局 `codex` 命令启动 MCP server。

## 3. 如果需要 OpenAI API Key

如果当前环境没有可用的 OpenAI 认证信息，可以设置：

```bash
export OPENAI_API_KEY=sk-xxxx
```

建议写入 shell 配置文件。

`zsh`：

```bash
echo 'export OPENAI_API_KEY=sk-xxxx' >> ~/.zshrc
source ~/.zshrc
```

`bash`：

```bash
echo 'export OPENAI_API_KEY=sk-xxxx' >> ~/.bashrc
source ~/.bashrc
```

## 4. 验证 Claude 是否已加载 MCP

启动 Claude Code：

```bash
claude
```

然后执行：

```text
/mcp
```

如果配置成功，应该能看到：

```text
codex
```

## 5. 推荐的最终结构

```text
~/.claude/
└── mcp.json
```

内容：

```json
{
  "mcpServers": {
    "codex": {
      "command": "codex",
      "args": ["mcp-server"]
    }
  }
}
```

## 6. 补充说明

- `claude mcp add ...` 很适合快速试用，但容易让人误以为它天然是全局安装。
- 真正要做到“换一个 repo 也能用”，关键是配置 `~/.claude/mcp.json`。
- 如果后续还要接入 `filesystem`、`github` 或其他 MCP，也是在这个全局文件里继续追加。

## 7. 本机这次实际处理结果

这次已经确认并完成了以下事项：

- 本机已存在全局 `codex` 命令。
- 当前检测到的版本是 `codex-cli 0.112.0`。
- 已写入 Claude 全局配置文件 `~/.claude/mcp.json`。
- 当前 shell 中 `OPENAI_API_KEY` 仍是未设置状态，如需通过该方式认证，需要额外补上环境变量。
