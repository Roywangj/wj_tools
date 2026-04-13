# 主板与电源笔记

## Lab Server 主板识别信息

### BIOS 芯片

- 品牌：AMI Aptio
- 厂商：American Megatrends (AMIBIOS)
- 版权：© 1985-2006
- 型号标签：`LBS-DF`
- BIOS 编号：`BK07389`

### 可识别芯片与组件

- `LATTICE`（FPGA，右侧）
- `U4RR`

### 接口与插针

- `JTAG_FP`
- `JTAG_FPGA`（含 1/2/3/4 引脚）
- `HEADER FOR 5V STBY POWER`
- `JVRM1`
- `JP61`
- `JP2`

### 主板型号判断

- 品牌：Supermicro
- 疑似型号：`X11DAi-N` 或 `X11DPi-N` 系列
- 平台：双路 Intel Xeon，支持 DDR4 ECC RDIMM
- 原产地：Designed in USA

### 其他可见特征

- 绿色 PCB
- 含 CMOS 纽扣电池座

## 相关手册

- 若主板是 `X11DAi-N`：<https://www.supermicro.com/manuals/motherboard/C600/MNL-1957.pdf>
- 若主板是 `X11DPi-N / X11DPi-NT`：<https://www.supermicro.com/manuals/motherboard/C620/MNL-1773.pdf>
- 若需要参考 `MNL-1998`：<https://www.supermicro.com/manuals/motherboard/C620/MNL-1998.pdf>
- Supermicro 下载中心：<https://www.supermicro.com/en/support/resources/downloadcenter/>

> 当前主板型号仍是疑似判断，建议根据丝印再次核对后再使用对应手册。

## 已知故障现象

- 主板待机指示灯正常亮起，但按下电源按钮后无任何反应，无法开机
- 当前状态：排查中

## 上电排查

### 方案一：短接 `JF1` 的 `PWR_SW`

- `JF1` 是 Supermicro 主板前面板接口，通常位于主板边缘
- `PWR_SW` 常见于 `JF1` 的 `1、2` 针脚
- 可用螺丝刀或跳线帽短接约 1 秒，直接触发开机
- 若短接后能开机，优先怀疑前面板按钮或连接线故障
- 若短接后仍无反应，再继续排查供电、内存、CPU 和 BIOS 状态

### `JF1` 常见针脚定义

| 针脚 | 功能 |
| --- | --- |
| 1, 2 | Power Button（`PWR_SW`） |
| 3, 4 | Reset Button |
| 5, 6 | Power Fail LED |
| 15, 16 | Power LED |

### `JF1` 位置提示

- 通常位于主板右下角或下边缘
- 常靠近 SATA 接口区域
- 丝印会标注 `JF1`
- 一般有小三角标记第 1 针

### 其他排查步骤

1. 检查前面板跳线是否接在正确的 `JF1` 针脚上。
2. 确认内存优先安装在建议槽位，例如 `A1/B1`。
3. 检查 CPU `EPS 8-pin` 供电线是否全部插牢。
4. 若主板带 BMC/IPMI，尝试通过管理口远程开机并查看 `SEL` 日志。
5. 断电后取下 CMOS 电池约 30 秒，再上电测试，排除 BIOS 状态异常。

## Supermicro `X10DRG-Q` 主板信息

> 注：原始记录写作 `X10RDG-Q`，此处统一使用更正后的型号 `X10DRG-Q`。

### 基本规格

- 表单规格（Form Factor）：Supermicro 专有规格，15.2" × 13.2"
- 芯片组：Intel C612 Express
- BMC 控制器：ASPEED AST2400
- 适用场景：双路工作站 / 服务器，GPU 计算、HPC、AI 训练

### CPU 支持

- 插槽：双路 Socket R3（LGA 2011-v3）
- 支持处理器：Intel Xeon E5-2600 v3 / v4 系列
- QPI 速度：最高 9.6 GT/s
- 单 CPU 最大 TDP：160W（支持 E5-2699 v3 18 核）

### 内存规格

- 类型：DDR4 ECC（RDIMM / LRDIMM / UDIMM，不可混插）
- 插槽数：16 个 DIMM 槽（每路 CPU 4 通道 × 2 槽）
- 最大容量：2TB（3DS LRDIMM）/ 1TB（标准 DDR4）
- 速度：最高 2400 MT/s
- 单条规格：8GB / 16GB / 32GB / 64GB

### 扩展插槽

- 4× PCIe 3.0 x16
- 2× PCIe 3.0 x8（物理 x16 槽）
- 1× PCIe 2.0 x4（物理 x8 槽）
- 总 PCIe 通道数：80 条（每路 CPU 40 条）
- GPU 支持：最多 4 块 GPU（Tesla / Quadro / GRID / Xeon Phi）

### 存储接口

- 10× SATA3（6Gb/s）
  - 4 口由 Intel SCU 控制（端口 0-3）
  - 6 口由 Intel C612 PCH 控制（端口 0-5）
- RAID：0 / 1 / 5 / 10
- 支持 NVMe / SAS3 / SATA3

### 网络与管理

- 板载 LAN：双口 Intel i350 千兆以太网（10/100/1000 Mb/s）
- IPMI 管理口：独立 Realtek 控制管理网口
- IPMI 版本：IPMI 2.0，支持 KVM-over-IP、虚拟媒体、远程开关机、SEL 日志

### 电源接口

- 24-pin ATX 主电源（`JPWR1`）
- 2× 8-pin CPU 供电（`JPWR2` / `JPWR3`），必须全部接好
- 1× 4-pin 辅助供电（`JPWR4`），建议接
- 规范：SSI EPS 12V

### 其他接口

- 5× USB 3.0
- 4× USB 2.0
- 7.1 HD Audio + 光纤 S/PDIF 输出

## 电源兼容性

### 长城巨龙 `GW-EPS1650DA / GW-EPS1560DA`

| 型号 | 额定功率 | 认证 |
| --- | --- | --- |
| `GW-EPS1650DA` | 1650W | 80 PLUS Gold，全模组 |
| `GW-EPS1560DA` | 1560W | 80 PLUS Gold，全模组 |

### 配合 `X10DRG-Q` + 双路 `Xeon E5-2699 v4` + `RTX 3090`

系统底电约 440W（CPU 290W + 主板/内存/存储 150W），`RTX 3090` 单卡 350W。

| 电源 | 80% 可用功率 | 除去底电 | 稳定带卡数 |
| --- | --- | --- | --- |
| `GW-EPS1650DA`（1650W） | 1320W | 880W | 2 张（勉强可试 3 张） |
| `GW-EPS1560DA`（1560W） | 1248W | 808W | 2 张 |

> 主板物理支持 4× GPU，但电源是瓶颈。跑满负载训练建议 2 张；如需 3 张，电源需升级至 2000W+。
