# IPMI 远程管理指南（笔记本直连 Supermicro 服务器）

本文档整理了使用 Windows 笔记本通过网线直连服务器 IPMI 的操作流程，适合在服务器尚未接入正常网络、需要检查硬件状态，或需要远程开关机 / 进 BIOS 时使用。

## 1. 当前已知 IPMI 配置

根据 BIOS 中的 `BMC Network Configuration`，当前服务器配置如下：

| 项目 | 值 |
|------|----|
| IPMI LAN Selection | `Failover` |
| IPMI Network Link | `Shared LAN` |
| Config Address Source | `DHCP` |
| Station IP Address | `10.106.1.120` |
| Subnet Mask | `255.255.254.0` |
| Gateway IP Address | `10.106.0.1` |
| MAC Address | `0c-c4-7a-ed-2e-c4` |

默认登录信息：

| 项目 | 值 |
|------|----|
| 用户名 | `ADMIN` |
| 密码 | `ADMIN` |

## 2. 直连场景下的结论

如果只是为了尽快连上当前这台服务器的 IPMI，可以直接按下面的最短路径操作：

1. 笔记本用网线连接服务器 `Dedicated LAN`（推荐）或 `LAN1`
2. Windows 有线网卡手动配置静态地址：`10.106.1.121 / 255.255.254.0`
3. 浏览器访问 `http://10.106.1.120`
4. 用 `ADMIN / ADMIN` 登录

如果目标是排查风扇问题，登录后优先进入 `配置 -> 风扇模式`，切到 `Full` 观察风扇是否恢复转动。

## 3. 硬件连接说明

Supermicro 支持 IPMI 的主板通常有三个 RJ45 网口：

- `Dedicated LAN`：独立管理口，只跑 IPMI 流量，直连时优先使用
- `LAN1 / LAN2`：普通业务网口
- 当前机器处于 `Failover` 模式：`Dedicated LAN` 和 `LAN1` 都可能承载 IPMI

直连方式：

1. 一根普通网线连接服务器 `Dedicated LAN` 或 `LAN1`
2. 另一端连接笔记本有线网口；没有网口时使用 USB 转网口
3. 现代网卡一般支持 Auto-MDIX，不需要交叉线

## 4. Windows 网络配置

直连时通常没有 DHCP 服务器，所以笔记本必须手动设置为和 IPMI 同网段的静态 IP。

推荐填写：

| 项目 | 建议值 |
|------|--------|
| IP 地址 | `10.106.1.121` |
| 子网掩码 | `255.255.254.0` |
| 默认网关 | `10.106.0.1` |
| 首选 DNS | `8.8.8.8` |
| 备用 DNS | `114.114.114.114` |

其中，默认网关和 DNS 在直连场景里基本不会真正使用，但有些 Windows 版本保存时不允许留空，填上即可。

### 4.1 Windows 10 / 11 配置步骤

1. 按 `Win + R`，输入 `ncpa.cpl`
2. 打开连接服务器的有线网卡属性
3. 双击 `Internet 协议版本 4 (TCP/IPv4)`
4. 选择“使用下面的 IP 地址”，填入上表内容
5. 保存退出

### 4.2 避免影响笔记本 Wi-Fi 上网

配置了默认网关后，Windows 可能把有线口当成默认出口，导致 Wi-Fi 断网。推荐这样处理：

1. 在 `TCP/IPv4 -> 高级`
2. 取消勾选“自动跃点”
3. 将“接口跃点数”设为 `9999`

这样系统会优先使用 Wi-Fi 出网，有线口只负责访问 `10.106.1.x` 网段。

如果只是临时使用，也可以在操作结束后把网卡改回“自动获得 IP 地址”。

### 4.3 连通性验证

打开 `cmd` 或 PowerShell，执行：

```cmd
ping 10.106.1.120
```

正常情况下应该能收到回复。若无法连通，依次检查：

- 网线是否插好，两端网口指示灯是否亮
- 笔记本 IP 是否确实设置成同网段地址，可用 `ipconfig` 检查
- Windows 防火墙是否拦截，必要时临时关闭测试
- 服务器是否通电；IPMI 只要主机接电即可工作，不依赖操作系统启动

## 5. 登录 IPMI Web 界面

1. 打开浏览器（Chrome / Edge 均可）
2. 访问 `http://10.106.1.120`
3. 若浏览器提示证书不安全，选择继续访问
4. 输入账号 `ADMIN` / `ADMIN`

若密码已被修改，则使用更新后的账号信息。登录后即可进入 IPMI Web 管理界面。

## 6. 常用功能速查

### 6.1 查看传感器

菜单路径：

```text
服务器健康 -> 传感器读取信息
```

- 绿色表示正常
- 红色表示异常

适合先看温度、风扇、电压有没有明显告警。

### 6.2 调整风扇模式

菜单路径：

```text
配置 -> 风扇模式
```

| 模式 | 散热 | 噪音 | 说明 |
|------|------|------|------|
| `Full` | 最强 | 最大 | 全速模式，排查风扇时优先使用 |
| `Optimal` | 一般 | 最小 | 按温度自动调速 |
| `HeavyIO` | 较强 | 中等 | 偏向 GPU / 重载场景 |
| `Standard` | 中等 | 中等 | 默认通用模式 |

排查风扇异常时，先切到 `Full`，再观察对应风扇是否恢复。

### 6.3 查看事件日志

菜单路径：

```text
服务器健康 -> 事件日志
```

这里可以查看历史硬件报错和告警记录。

### 6.4 远程控制台（KVM over IP）

菜单路径：

```text
远程控制 -> 重定向控制台 -> 启用控制台
```

这是硬件级远程控制，不依赖服务器操作系统。开机自检、BIOS 和阵列卡界面都可以从这里远程操作。新版 IPMI 一般支持 HTML5，无需 Java。

### 6.5 电源控制

菜单路径：

```text
远程控制 -> 电源控制
```

支持远程开机、关机、强制断电和重启。

## 7. 命令行方式（可选）

如果已经 SSH 登录到服务器系统，也可以用 `ipmitool` 查看 BMC 信息和风扇状态：

```bash
# 查看风扇状态
sudo ipmitool sdr type Fan

# 查看当前风扇模式
sudo ipmitool raw 0x30 0x45 0x00

# 切换风扇模式
sudo ipmitool raw 0x30 0x45 0x01 0x00   # Standard
sudo ipmitool raw 0x30 0x45 0x01 0x01   # Full
sudo ipmitool raw 0x30 0x45 0x01 0x02   # Optimal
sudo ipmitool raw 0x30 0x45 0x01 0x04   # HeavyIO

# 查看 IPMI 网络配置
sudo ipmitool lan print 1
```

## 8. 本机排查记录（2026-04-14）

执行 `sudo ipmitool sdr type Fan` 的结果：

```text
FAN1  | ok  | 1000 RPM
FAN2  | ok  | 1000 RPM
FAN3  | ns  | No Reading
FAN4  | ns  | No Reading
FAN5  | ns  | No Reading
FAN6  | lnr | 0 RPM
FANA  | ok  | 1000 RPM
FANB-D| ns  | No Reading
```

当前判断：

- CPU 散热风扇接在 `FAN5 / FAN6`
- `FAN6` 报 `lnr`，即 `Lower Non-Recoverable`
- `FAN6` 当前转速为 `0 RPM`，属于严重告警

建议按以下顺序继续排查：

1. 登录 IPMI Web，把风扇模式切到 `Full`
2. 观察 `FAN6` 是否恢复转动
3. 若仍为 `0 RPM`，检查风扇插头是否松动或风扇本体是否损坏
4. 若 CPU 满载后散热器明显发烫且风扇不转，优先更换同规格 `4-pin PWM` 风扇
