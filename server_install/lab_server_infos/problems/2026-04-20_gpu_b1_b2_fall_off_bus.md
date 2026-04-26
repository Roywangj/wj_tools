# 197 服务器 b1 / b2 GPU 同时掉线(Xid 79)

- 报告时间: 2026-04-20
- 故障首次观察: 2026-04-17
- 最近一次复现: 2026-04-19 23:07:38
- 主机: ubuntu(197)
- 硬件: 双路 Sky Lake-E,8× RTX 3090
- 主板 / 背板: 浪潮 YPCB-01149-1P5(NF5468 系列)
- 供电线: PSU 端"大 8pin"→ 4 × (6+2)pin 的 **1 拖 4** 分线(料号 `RWHHW-D434`,16AWG 黄线)
- 状态: 交叉验证已确认为供电线问题,待厂家寄配件替换测试

## 一、故障概述

- PCI 地址 `b1:00.0` 和 `b2:00.0` 两张 GPU,在负载下**几乎同时**从 PCIe 总线掉落(Xid 79 "GPU has fallen off the bus")。
- `nvidia-smi` 卡死;`lspci` 显示两张卡变成 `(rev ff)`。
- 相关用户进程卡在内核 D 态(`uvm_gpu_retain_by_uuid` / `uvm_api_register_gpu`)。
- 热重启无效,必须**断电冷启动(≥30s)**才能恢复。

## 二、关键证据

日志文件 `problems/logs/gpu_diag_ubuntu_20260420_155314.txt`,"===== 上一次开机期间的 nvidia / xid / hung task 日志 =====" 段(起始第 612 行)。

最近一次故障 2026-04-19 23:07:38–39,txt 第 **722–733 行**,1 秒内两张卡相继掉线:

| 行号 | 内容 | 含义 |
|---|---|---|
| 722–724 | `pcieport 0000:b0:04.0: pciehp: Slot(36): Link Down / Card not present` | b2 所在 PCIe switch 下行口链路消失 |
| 726–727 | `NVRM: Xid (PCI:0000:b1:00): 79 ... GPU has fallen off the bus.` | b1 掉线 |
| 728–730 | `pcieport 0000:b0:00.0: pciehp: Slot(32): Link Down / Card not present` | b1 所在 switch 下行口链路消失 |
| 732–733 | `NVRM: Xid (PCI:0000:b2:00): 79 ... GPU has fallen off the bus.` | b2 掉线 |

## 三、已排除项

1. **GPU 本体**:已换两张全新 3090,同位置同样掉线。
2. **PCIe 延长线 / riser**:b1 / b2 为主板直插,无延长线。
3. **PCIe switch / CPU1 Root Complex**:同一 switch 下的 b4 / b5 工作正常,上游链路和 CPU1 无异常。
4. **BIOS 全局配置**:b4 / b5 正常,排除全局配置问题。

## 四、推测原因

两张相邻 GPU **在负载下 1 秒内同时掉线**,且仅冷启动能恢复 —— 高度怀疑 **b1 / b2 这一路 PCIe 供电共享** 存在问题:

- 一拖二(Y 型)8pin 线在双卡峰值功耗下压降超标,或
- 这一路 PSU 供电余量不足 / 有隐性故障。

当前供电线是 **PSU 端"大 8pin"(浪潮原厂规格,料号 `RWHHW-D434`) → 4 × (6+2)pin** 的 **1 拖 4** 分线(16AWG 黄线)—— 也就是说 **4 个 GPU 8pin 口共享同一路 PSU 8pin 输出**,两张 3090 满载(峰值 ≈700W)时远超一根 PSU 8pin 的设计裕度,电压一跌两张卡同时掉就非常典型。

参考图:
- 现场接线:`logs/8d1d821f52cb4d062c7a97e0548f94d6.jpg`
- 接头细节:`logs/bd19d1376596c829d9a9d71c122eb349.jpg`
- 料号标签:`logs/c015826fd8cbac376536e9c653c53331.jpg`

## 四·补、交叉验证(2026-04-20 16:54)

**调换供电线接口顺序后,故障位置随线迁移,不随槽迁移**,定论为供电线/供电一路的问题。

| 项目 | 调线前 | 调线后 |
|---|---|---|
| 掉线槽位 | b1:00.0 / b2:00.0(Xid 79) | b4:00.0(`nvidia-smi: Unable to determine the device handle for GPU 0000:B4:00.0: Unknown Error`) |
| b1 / b2 | 掉线 | **满载 341 W / 348 W,GPU-Util 100% 正常** |
| b4 | 正常 | 掉线 |

解释:原本接在 b1 / b2 上的那根供电线,这次被挪到了 b4,于是掉线跟着线走。排除 GPU 本体、排除槽位 / PCIe switch、排除 BIOS —— **根因锁定在这根供电线(或它所在那一路 PSU 输出)**。

## 五、发给厂家的原文

```
故障报修 —— 197 服务器(8× RTX 3090)b1 / b2 槽位 GPU 双卡同时掉线

你好,我们这台服务器上 PCI 地址 b1:00.0 和 b2:00.0 两张 GPU,在负载下会几乎同时从 PCIe 总线上掉落(Xid 79 "GPU has fallen off the bus"),需要断电冷启动才能恢复,热重启无效。现把诊断脚本和日志发你们,麻烦帮忙寄配件过来替换测试。

【故障现象】
- 运行 nvidia-smi 报 "Unable to determine the device handle for GPU 0000:B1:00.0: Unknown Error",随后整个 nvidia-smi 卡死。
- lspci 显示 b1 / b2 两张卡变成 (rev ff),PCIe 配置空间已失联。
- 相关进程卡在内核 D 态(uvm_gpu_retain_by_uuid / uvm_api_register_gpu)。
- 只有断电冷启动(≥30s)才能恢复;热 reboot 不行。

【关键证据】
见附件 gpu_diag_ubuntu_20260420_155314.txt,"===== 上一次开机期间的 nvidia / xid / hung task 日志 =====" 段,起始第 612 行。
最近一次故障发生在 2026-04-19 23:07:38–39,txt 文件第 722–733 行,1 秒内两张卡相继掉线:
- 第 722–724 行:pcieport 0000:b0:04.0: pciehp: Slot(36): Link Down / Card not present(b2 所在 switch 下行口)
- 第 726–727 行:NVRM: Xid (PCI:0000:b1:00): 79 ... GPU has fallen off the bus.
- 第 728–730 行:pcieport 0000:b0:00.0: pciehp: Slot(32): Link Down / Card not present(b1 所在 switch 下行口)
- 第 732–733 行:NVRM: Xid (PCI:0000:b2:00): 79 ... GPU has fallen off the bus.

【我们已经排除的项】
1. GPU 本身:已经换过两张全新的 3090,同样位置同样掉线。
2. PCIe 延长线 / 转接卡:这两个槽位是主板直插,没有 riser。
3. PCIe switch / CPU1 Root Complex:同一个 switch 下的 b4 / b5 工作正常,说明上游链路和 CPU1 没问题。
4. BIOS 全局配置:b4 / b5 能跑,说明不是 BIOS 配置问题。
5. 驱动 / 软件:Xid 79 是驱动上报的硬件级错误,非软件问题。

【机型信息】
主板 / 背板:浪潮 YPCB-01149-1P5(NF5468 系列)
现用供电线:PSU 端"大 8pin"(料号 RWHHW-D434) → 4 × (6+2)pin 的 1 拖 4 分线,16AWG 黄线

【交叉验证 —— 已确认是供电线问题】
我们调换了供电线的接口顺序:
- 调线前:b1 / b2 掉线
- 调线后:b1 / b2 满载 341W / 348W 正常,改成 b4 掉线(nvidia-smi 报 B4:00.0 Unknown Error)
故障跟着线走,不跟着槽走,排除 GPU 本体、排除槽位 / PCIe switch / BIOS,根因锁定在供电线(一根 PSU 8pin 被分给 4 个 GPU 6+2pin,两张 3090 满载合计 ≈700W 远超 PSU 8pin 裕度)。

【请求寄送以下配件测试】
PSU 端接口请按现有线(浪潮 YPCB-01149-1P5 原厂大 8pin,料号 RWHHW-D434)匹配,不能用通用件。
1. PSU 大 8pin → 2 × (6+2)pin 的 "1 拖 2" 线 × 8 根 —— 每张 3090 独占 1 根 PSU 输出,彻底消除共享
2. PSU 大 8pin → 4 × (6+2)pin 的 "1 拖 4" 线(和现款同款)× 1~2 根 —— 备用 / 对照测试
3. 同型号电源 (PSU) × 1 台 —— 交叉验证是否是现有电源某一路衰减
线规:16AWG(和现款一致),长度和现款一致。

收到后我们会做对照测试并把结果反馈,谢谢!

附件:
- diagnose_gpu.sh —— 诊断脚本
- gpu_diag_ubuntu_20260420_155314.txt —— 诊断输出(关键证据在第 612 段 / 722–733 行)
- 8d1d821f52cb4d062c7a97e0548f94d6.jpg —— 现场接线
- bd19d1376596c829d9a9d71c122eb349.jpg —— 接头细节
- c015826fd8cbac376536e9c653c53331.jpg —— 料号标签
```

## 六、发给厂家的口语版(简短)

```
赵总,我们之前在你们那买的 8 卡风冷 3090(浪潮 YPCB-01149-1P5 主板),最近遇到两张 3090 同时掉卡的问题 —— nvidia-smi 卡死,lspci 看卡变 (rev ff),要断电冷启动才能恢复。
已经做了交叉验证:换新卡问题一样,换了供电线的接口顺序之后故障跟着线走(原来 b1/b2 掉,换线后变成 b4 掉,b1/b2 满载正常),所以基本确定就是供电线 / 这一路 PSU 输出的问题。
我们现在用的是你们原装的 PSU 大 8pin → 4 × (6+2)pin 的 1 拖 4 分线(料号 RWHHW-D434),一根 PSU 8pin 给 4 个 GPU 口供电,两张 3090 满载峰值接近 700W,这一路应该是超裕度了。
想麻烦你们寄一下(PSU 端接口要和现有大 8pin 同款,不能通用):
1. PSU 大 8pin → 2 × (6+2)pin 的"1 拖 2"线 × 8 根(每张 3090 独占一根)
2. 现款 1 拖 4 线 × 1~2 根(备用 / 对照)
3. 同型号电源 × 1 台
线规 16AWG,长度和现款一致就行。收到后做对照测试,结果反馈给你们。我把诊断脚本、日志和线的照片一起发过来,谢谢!
```
