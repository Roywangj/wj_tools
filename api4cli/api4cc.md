# 使用 CC Switch 将第三方 URL/Key 接入 Claude Code

更新日期：2026-07-22  
实测环境：CC Switch 3.18.0、Claude Code 2.1.218、macOS

## 1. 适用范围与使用约定

本文介绍如何把公司或实验室提供的第三方大模型 API（Base URL + API Key）添加到 CC Switch，并让 Claude Code 通过 CC Switch 的本地路由调用该 API。

### 目前只验证了 Claude Code

本文流程目前只对以下链路做过实际验证：

```text
Claude Code
    ↓ Anthropic Messages 请求
CC Switch 本地路由（127.0.0.1:15721）
    ↓ 协议转换和模型映射
第三方 OpenAI Responses API
    ↓
实际部署的 GPT/其他兼容模型
```

本文不提供 Codex CLI 的第三方 API 接入教程，原因如下：

1. Codex 订阅本身更方便，日常直接使用订阅即可；
2. 大家通常已经熟悉 Codex CLI 的登录和使用方式，没有必要额外维护一套 Key 路由；
3. 第三方 URL 往往只在公司或实验室局域网内可访问，离开办公网络后无法直接使用；
4. 若把工作环境完全绑定到该 URL，下班或离开局域网后还要频繁切换账号、重新认证，维护成本较高；
5. 因此当前采用的策略是：**Codex 继续使用订阅；第三方 URL/Key 只通过 CC Switch 提供给 Claude Code。**

这不是说 CC Switch 不能路由 Codex，而是当前没有对该路径进行完整测试和维护。

## 2. 前置条件

开始前需要准备：

- 第三方 API Base URL，例如 `http://<LAN-IP>:<PORT>`；
- API Key；
- 上游实际模型 ID，例如 `<MODEL_ID>`；
- 上游 API 格式；
- 已安装 CC Switch 和 Claude Code；
- 当前电脑能够访问第三方 URL 所在的局域网，或已经接入公司 VPN/ZeroTier 等网络。

### 先确认 API 格式

CC Switch 添加供应商时会看到类似选项：

- Anthropic Messages（原生）；
- OpenAI Chat Completions（需开启路由）；
- OpenAI Responses API（需开启路由）；
- Gemini Native generateContent（需开启路由）。

本文实际测试的是：

```text
OpenAI Responses API（需开启路由）
```

API 格式必须与上游真实实现一致。模型名称存在并不代表所有 API 格式都可用。

## 3. 在终端中先检查 URL 和模型

不要把真实 Key 写入仓库、Markdown、聊天记录或截图。可以在 zsh 中临时输入：

```bash
export THIRD_PARTY_BASE_URL='http://<LAN-IP>:<PORT>'
read -s 'THIRD_PARTY_API_KEY?API Key: '
echo

curl -sS "$THIRD_PARTY_BASE_URL/v1/models" \
  -H "Authorization: Bearer $THIRD_PARTY_API_KEY" | jq .

unset THIRD_PARTY_API_KEY
unset THIRD_PARTY_BASE_URL
```

重点检查：

- URL 是否可达；
- 是否返回 JSON；
- `data[].id` 中是否存在要调用的模型；
- 是否出现 `401`、`403`、`404` 或连接超时。

`/v1/models` 只能确认模型 ID 和基础连通性，不能证明上下文窗口、推理接口、工具调用和流式响应全部正常。

## 4. 在 CC Switch 中添加第三方供应商

### 4.1 进入 Claude Code 供应商页面

打开 CC Switch：

```text
Claude Code → 添加供应商/Provider → 自定义供应商
```

不同版本的文字可能略有差异，但应当是在 Claude Code 标签页中添加，而不是 Codex 标签页。

### 4.2 填写基本信息

建议填写：

| 字段 | 内容 |
|---|---|
| 名称 | 容易识别的名字，例如 `company-api` |
| Base URL | `http://<LAN-IP>:<PORT>`，通常不要重复添加 `/v1/responses` |
| API Key | 管理员提供的真实 Key |
| API 格式 | `OpenAI Responses API（需开启路由）` |
| 备注 | 标注“仅局域网可用”“Claude Code 已测试”等信息 |

Base URL 通常填写到端口或 API 前缀层级。是否需要尾部 `/v1` 取决于网关实现；如果管理员给出的 URL 已经包含 `/v1`，不要盲目再拼接一次。

### 4.3 设置模型映射

Claude Code 会使用 Claude 风格的模型角色，例如 Opus、Sonnet、Haiku 或 Fable；上游可能实际提供 GPT 模型。因此 CC Switch 需要把 Claude Code 请求的角色映射到上游真实模型 ID。

一个常见配置是：

| Claude Code 角色 | 上游模型 |
|---|---|
| 主模型/Opus/Fable | `<PRIMARY_MODEL_ID>` |
| Sonnet | `<BALANCED_MODEL_ID>` |
| Haiku | `<FAST_MODEL_ID>` 或主模型 |

如果上游只提供一个模型，可以暂时让三个角色都映射到同一个模型。

不要根据 Claude Code 界面显示的名称判断真实模型。例如 Claude Code 可能显示：

```text
Fable 5
```

但 CC Switch 日志中实际路由的可能是：

```text
gpt-5.x-...
```

计费、Token 使用和能力限制由**实际上游模型与第三方网关**决定，不由 Claude Code 显示的别名决定。

### 4.4 关于 `[1M]`/1M Context

只有在管理员明确确认上游完整支持相应上下文时，才启用 `1M Context` 或给模型加 `[1M]` 标记。

该标记主要告诉 Claude Code如何计算上下文和压缩时机，不能证明第三方网关真的允许 1M 输入。若客户端认为有 1M、但网关实际限制更小，Claude Code 可能过晚压缩并最终收到：

```text
Your input exceeds the context window of this model.
```

不确定时应先关闭 1M，或者为 Claude Code单独设置更保守的自动压缩窗口。

## 5. 开启 CC Switch 本地路由

OpenAI Responses API 不能直接作为 Anthropic Messages API 提供给 Claude Code，因此必须开启 CC Switch 的协议转换路由。

进入：

```text
CC Switch → 设置 → 路由/本地路由
```

开启：

1. 本地路由总开关；
2. Claude Code 路由/接管开关；
3. 请求日志，便于确认实际模型和错误原因。

推荐设置：

```text
监听地址：127.0.0.1
监听端口：15721
```

不要把监听地址改成 `0.0.0.0`，除非确实需要让其他机器访问并已经配置防火墙、鉴权和网络隔离。对个人 Mac，使用 `127.0.0.1` 最安全。

保存后回到 Claude Code 供应商页面，启用刚创建的供应商。

启用成功后，CC Switch 会让 Claude Code 指向本地代理：

```text
ANTHROPIC_BASE_URL=http://127.0.0.1:15721
```

本地路由再把请求转换并转发到第三方 Base URL。

## 6. 不要把 `~/.claude/settings.json` 当作主要配置入口

CC Switch 接管 Claude Code 时会管理：

```text
~/.claude/settings.json
```

因此不建议只手工修改该文件：下一次切换供应商或重新接管时，部分字段可能被 CC Switch 重写。

供应商特有的配置应优先写在 CC Switch 的供应商配置中；所有供应商都需要的配置可以放在 Claude Code 通用配置/Common Config 中。

用于理解结构的脱敏示例：

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "<API_KEY>",
    "ANTHROPIC_BASE_URL": "http://<LAN-IP>:<PORT>",
    "ANTHROPIC_MODEL": "<PRIMARY_MODEL_ID>",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "<PRIMARY_MODEL_ID>",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "<BALANCED_MODEL_ID>",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "<FAST_MODEL_ID>",
    "CLAUDE_CODE_AUTO_COMPACT_WINDOW": "350000"
  }
}
```

这只是结构示例。优先使用 CC Switch 图形界面保存，不要把含真实 Key 的 JSON 提交到 Git。

## 7. 启动和验证 Claude Code

关闭已经打开的旧 Claude Code 会话，在实际项目目录重新启动：

```bash
cd /path/to/project
claude
```

进入后依次检查：

```text
/status
/model
/effort medium
/context
```

然后发送一个很短的测试：

```text
只回复：连接正常
```

### 7.1 在 CC Switch 中确认实际路由

打开 CC Switch 的请求日志/用量日志，检查：

- 供应商是否为刚创建的第三方供应商；
- `request_model` 是 Claude Code 的别名还是角色；
- 最终 `model` 是否为预期的上游模型；
- HTTP 状态是否为 `200`；
- input/output/cache tokens 是否正常记录；
- 是否出现格式转换、stream 或 context 错误。

不要通过询问模型“你是什么模型”判断实际身份。模型可能按照 Claude Code 给出的别名回答。**路由日志和第三方网关记录才是更可靠的证据。**

### 7.2 思考强度

如果希望在 Claude Code 中使用 `/effort` 动态调节，应关闭 CC Switch 中强制性的 `Max Effort` 设置。

推荐日常使用：

```text
/effort medium
```

复杂任务可临时使用：

```text
/effort high
```

`xhigh` 会显著增加 reasoning/output tokens。对于长会话、自动压缩和第三方协议转换，它更容易触发长时间无输出、stream watchdog 或输出上限问题，不建议长期设为默认。

## 8. 当前遇到的上下文与自动压缩问题

### 8.1 已出现的故障

长时间运行 Claude Code、启动多个检查代理并积累大量工具结果后，曾出现：

```text
Error during compaction:
API Error: Claude's response exceeded the 64000 output token maximum.
```

随后自动压缩未能完成，会话继续膨胀，并反复出现：

```text
Your input exceeds the context window of this model.
```

以及：

```text
Agent stalled: no progress for 600s
API Error: 502 upstream_error
```

当 `/compact` 本身也因输入超限失败时，该会话通常已经无法在原窗口中安全恢复。应保存 handoff、退出旧会话并从新窗口继续。

### 8.2 为什么会发生

可能因素包括：

1. Claude Code 根据 `[1M]` 认为模型有 1M 上下文；
2. 第三方网关 `/v1/models` 没有公开实际 `context_window`；
3. 网关、协议转换器或实际模型的有效窗口可能小于客户端声明；
4. 工具 schema、文件内容、子代理结果和完整对话都进入输入；
5. `xhigh` reasoning 可能生成非常大的输出/思考流；
6. 自动压缩启动得太晚，或压缩摘要本身超过输出上限。

在当前测试链路中，CC Switch 历史记录至少出现过约 `349,560` 输入 Token 的成功请求；失败请求没有返回 Token 统计，因此只能确定“至少支持约 350K”，不能据此证明完整支持 1M。

### 8.3 推荐的自动压缩配置

如果 `300000` 导致自动压缩过于频繁，可使用一个相对平衡的单变量配置：

```json
{
  "CLAUDE_CODE_AUTO_COMPACT_WINDOW": "350000"
}
```

不额外设置百分比时，Claude Code 通常会在接近该窗口上限时自动压缩，大约是 330K 左右。实际行为以 `/context` 显示为准。

不同取舍：

| 配置 | 大致效果 | 评价 |
|---|---|---|
| Window=`300000` | 约 280K–290K 压缩 | 更安全，但可能频繁打断 |
| Window=`350000` | 约 330K 压缩 | 当前推荐的平衡值 |
| 只设置 PCT=`80` 且模型标为 1M | 约 800K 才压缩 | 可能太晚，不推荐用于尚未确认窗口的网关 |

不建议仅设置：

```json
"CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "80"
```

因为当 Claude Code 认为模型是 1M 时，它可能拖到约 800K 才压缩，再次超过第三方链路的真实限制。

修改后需要退出旧 Claude Code，并在新会话运行：

```text
/context
```

应看到类似：

```text
Auto-compact window: 350k
from CLAUDE_CODE_AUTO_COMPACT_WINDOW
```

### 8.4 避免再次产生不可压缩会话

- 日常默认使用 `medium` 或 `high`，不要长期使用 `xhigh`；
- 不相关任务使用 `/clear` 或新会话；
- 长任务阶段性生成 `handoff.md`；
- 大日志和大文件先过滤再交给模型；
- 子代理只返回结论，不把全部原始输出带回主会话；
- 在窗口已经报 `input exceeds context window` 后，不要持续重复 `/compact`；
- 使用 `/context` 观察 system prompt、skills、MCP 和 conversation 的占用。

## 9. 常见故障排查

### 9.1 `502 upstream_error`

检查：

1. Mac 是否仍在对应局域网/VPN；
2. 第三方 Base URL 是否可以 `curl /v1/models`；
3. CC Switch 本地路由是否运行；
4. Claude Code 是否指向 `127.0.0.1:15721`；
5. CC Switch 日志中的上游错误正文；
6. API 格式是否误选成 Chat Completions 或 Anthropic Messages。

### 9.2 关闭本地路由后能用，开启后不能用

通常说明问题在协议转换、模型映射或本地路由配置，而不是 Claude Code 本体。确认：

- API Format 与上游一致；
- 供应商已启用；
- Claude Code 路由开关已开启；
- 模型 ID 没有拼错；
- Base URL 没有重复 `/v1`；
- 端口 `15721` 未被其他程序占用。

### 9.3 Claude Code 显示 Fable/Opus，但想确认实际 GPT 模型

这是模型映射的正常表现。请看 CC Switch 请求日志中的最终上游 `model`，不要只看 `/model` 的显示名称，也不要只相信模型的自我介绍。

### 9.4 `/compact` 一直失败

若错误是 `input exceeds context window`：

1. 停止反复重试；
2. 记录项目目录和会话 ID；
3. 保存 `git status`、关键文件和下一步到 `handoff.md`；
4. 退出旧会话；
5. 在同一项目目录启动全新 Claude Code；
6. 让新会话先读取 handoff 和当前磁盘状态。

代码、已写入文件和 Git 工作区不会因为退出 Claude Code 而消失。

## 10. 局域网与下班后的使用策略

第三方 URL 往往只在单位局域网内有效。离开后常见表现是：

```text
connection timeout
no route to host
502 upstream_error
```

推荐策略：

- 在公司/实验室网络内：启用第三方 Claude Code 供应商；
- 离开局域网后：切换回 Claude 官方供应商，或使用已经配置好的安全 VPN；
- Codex CLI 始终继续使用订阅，不依赖该局域网 URL；
- 不要为了远程访问而把公司 API 网关直接暴露到公网；
- 不要把 CC Switch 本地代理监听到公网接口。

这样可以避免下班时间为了使用 CLI 频繁退出登录、切换 Codex 账号或重新认证。

## 11. 安全注意事项

1. 不要在教程、聊天、截图、Shell 历史或 Git 中粘贴真实 API Key；
2. 如果 Key 曾出现在可同步的会话记录中，应尽快轮换；
3. CC Switch 数据库和 `~/.claude/settings.json` 可能包含认证信息，不要上传；
4. 本地路由只监听 `127.0.0.1`；
5. 不确认来源时，不安装名字相近的第三方 CC Switch 应用；
6. 使用公司 Key 时遵守内部数据、代码和费用政策；
7. 第三方 API 的 Token 额度和计费以实际上游网关为准。

## 12. 最短配置清单

```text
1. 确认局域网可以访问 Base URL
2. curl /v1/models 确认上游模型 ID
3. CC Switch → Claude Code → 添加自定义供应商
4. 填写 Base URL 和 Key
5. API Format 选择 OpenAI Responses API（需开启路由）
6. 配置 Claude 角色到上游模型的映射
7. 设置 → 本地路由 → 开启总开关和 Claude Code 路由
8. 使用 127.0.0.1:15721
9. 启用供应商并重启 Claude Code
10. /status、/model、/context 验证
11. 在 CC Switch 日志确认真实上游模型
12. 长会话使用合理的自动压缩窗口并定期写 handoff
```

## 13. 当前验证结论

- 已验证：第三方 OpenAI Responses API 经 CC Switch 本地路由供 Claude Code 使用；
- 已验证：Claude Code 的显示模型可映射到不同的实际上游模型；
- 已验证：CC Switch 可记录请求模型、实际上游模型和 Token 用量；
- 未验证：通过同一第三方 URL/Key 接入 Codex CLI 的长期稳定性；
- 当前选择：Codex CLI 继续使用订阅，第三方 URL/Key 只服务 Claude Code；
- 已知问题：长上下文、`xhigh` reasoning 和协议转换组合可能导致 compaction 输出过长或上游 context overflow，需要保守设置自动压缩窗口。
