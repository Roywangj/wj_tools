# Chain Proxy 配置说明

适用于“机场节点 + 静态住宅代理”串联使用的场景。

## 使用目标

- 基础出站仍走机场节点
- AI 服务流量切到静态住宅代理
- 在 Clash 中统一通过规则分流

## 旧版 Clash

### 配置方式

1. 打开旧版 Clash。
2. 新建订阅。
3. 选择 `YAML` 文件。
4. 将下面的配置作为订阅内容导入。

### 配置示例

```yaml
port: 7890
socks-port: 7891
allow-lan: true
mode: rule
log-level: info
external-controller: :9090

proxies:
  # 机场节点 这里直接从当前的机场中复制一个过来就好
  # 注意：后面静态住宅代理的 dialer-proxy 值，必须和这里的 name 完全一致
  - {
      name: 美国高级专线1,
      server: <机场服务器>,
      port: <机场端口>,
      type: ss,
      cipher: <加密方式>,
      password: <机场密码>,
      plugin: <插件类型>,
      plugin-opts: <插件参数>,
      udp: true
    }

  # 静态住宅代理
  - {
      name: 静态住宅代理,
      server: <住宅代理主机>,
      port: <住宅代理端口>,
      type: socks5,
      username: <用户名>,
      password: <密码>,
      dialer-proxy: 美国高级专线1
    }

proxy-groups:
  - name: 🤖 AI 服务
    type: select
    proxies:
      - 静态住宅代理
      - DIRECT

rules:
  - MATCH, 🤖 AI 服务
```

### 旧版注意事项

- `dialer-proxy` 的值必须和机场节点的 `name` 完全一致。
- 如果机场节点名称改了，静态住宅代理里的 `dialer-proxy` 也要一起改。
- 所有占位符都需要替换成你自己的实际参数。

## 新版 Clash

当前记录版本：`2.4.7`（2026-04-13）

### 配置方式

直接在当前机场配置中编辑静态住宅代理节点即可。

### 与旧版的区别

- 不需要 `dialer-proxy`
- 需要显式设置 `udp: true`

### 配置示例

在 proxy 中写入
```yaml
- {
    name: 静态住宅代理,
    type: socks5,
    server: <住宅代理主机>,
    port: <住宅代理端口>,
    username: <用户名>,
    password: <密码>,
    udp: true
  }
```
然后在 proxy group 中写入
```yaml
  - 静态住宅代理
```

Tip: 需要在 proxy 和 proxy group 中都写入，否则无法正常显示

## 版本差异速查

| 项目 | 旧版 Clash | 新版 Clash |
|------|------------|------------|
| 配置入口 | 新建 `YAML` 订阅 | 直接编辑当前机场配置 |
| `dialer-proxy` | 需要 | 不需要 |
| `udp: true` | 机场节点建议开启 | 静态住宅代理需要开启 |

## 配置验证

配置完成后，建议同时做网页测试和终端测试，确认出口 IP 已切到静态住宅代理。

### 1. 网页测试

可在浏览器中打开以下网站查看当前出口 IP、地区和运营商信息：

- `ping0.cc`
- `ip2location.com`
- `whoer.com`

如果网页显示的 IP、地区和运营商与静态住宅代理信息一致，说明链式代理基本生效。

### 2. 终端测试

在已经走代理的终端里执行：

```bash
curl ipinfo.io
```

示例返回结果如下，已对关键信息做脱敏处理：

```json
{
  "ip": "204.252.xx.xx",
  "city": "Dover",
  "region": "Delaware",
  "country": "US",
  "loc": "39.15xx,-75.52xx",
  "org": "AS701 <运营商信息已隐去>",
  "postal": "199xx",
  "timezone": "America/New_York",
  "readme": "https://ipinfo.io/missingauth"
}
```

重点检查以下字段是否符合预期：

- `ip`：是否已经变为住宅代理出口
- `country` / `region` / `city`：是否与目标地区一致
- `org`：是否与预期运营商类型大致匹配

## 建议

- 先确认你使用的是旧版还是新版 Clash，再套用对应配置。
- 如果导入后节点不可用，优先检查节点名称、端口、用户名密码和 `udp` 配置。
