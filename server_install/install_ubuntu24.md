# Ubuntu 24.04 安装笔记

## 服务器主板信息

- 品牌：Supermicro
- 疑似型号：`X11DAi-N` 或 `X11DPi-N` 系列
- 平台：双路 Intel Xeon，支持 DDR4 ECC RDIMM
- BIOS：AMI Aptio / American Megatrends
- 当前现象：待机指示灯正常亮起，但按下电源按钮后无任何反应，暂时无法开机

### 可见丝印/组件

- `LBS-DF`
- `BK07389`
- `LATTICE`（FPGA，右侧）
- `U4RR`
- `JTAG_FP`
- `JTAG_FPGA`
- `HEADER FOR 5V STBY POWER`
- `JVRM1`
- `JP61`
- `JP2`

### 官方 PDF 说明书下载

- 若主板是 `X11DAi-N`：https://www.supermicro.com/manuals/motherboard/C600/MNL-1957.pdf
- 若主板是 `X11DPi-N / X11DPi-NT`：https://www.supermicro.com/manuals/motherboard/C620/MNL-1773.pdf
- 若需要参考 `MNL-1998`：https://www.supermicro.com/manuals/motherboard/C620/MNL-1998.pdf
- Supermicro 资源页（可进一步核对型号后下载）：https://www.supermicro.com/en/support/resources/downloadcenter/

> 以上 PDF 链接来自 Supermicro 官方站点。由于当前主板型号仍是疑似，建议先根据主板丝印再次确认再使用对应手册。

## BIOS 启动设置

- 开机时连续按 `Delete` 键进入 BIOS
- 不需要手动 "Add New Boot Option"，BIOS 会自动识别 U 盘
- 推荐使用一次性启动菜单（F12 / F11 / Esc / F8，取决于主板品牌）
- 如果 U 盘不出现在启动列表，检查：
  - 关闭 Secure Boot
  - 关闭 Fast Boot

## U 盘说明

- aigo U 盘默认 1 个分区
- 若需手动 Add Boot Option，路径填：`\EFI\BOOT\BOOTx64.EFI`，分区选 Partition 1

## 安装选项选择

- 选 **"Try or Install Ubuntu"**（默认第一项）
- "Ubuntu (safe graphics)" 仅在花屏、黑屏、画面异常时使用

## 多硬盘情况（1个启动盘 + 1个数据盘）

- 分区步骤选 **"Something else"（手动分区）**，避免误格式化数据盘
- 安装前认准各盘符（/dev/sda、/dev/sdb）
- 最稳妥方式：**拔掉数据盘再装系统**，装完重新插回

### 建议分区方案（仅对启动盘操作）

| 分区 | 大小 | 格式 | 挂载点 |
|------|------|------|--------|
| EFI | 512MB | FAT32 | /boot/efi |
| swap | 与内存大小相同 | swap | — |
| 根分区 | 剩余全部 | ext4 | / |

## 常见报错

### `/init: line 38: can't open /dev/xxx: No medium found`

**原因**：内核启动后 USB 3.0 驱动未及时加载，U 盘"消失"

**解决**：将 U 盘换插到 **USB 2.0 口**（黑色口），或换主板背面接口，重新启动

## 上电前排查

如果当前机器表现为待机灯亮、但按电源键无反应，建议先完成下面的硬件排查，再继续安装 Ubuntu。

### 方案一：短接 JF1 的 PWR_SW 针脚

- Supermicro 主板的前面板接口通常是 `JF1`
- `PWR_SW` 一般位于 `JF1` 的 `1、2` 针脚
- 可用螺丝刀或跳线帽短接约 1 秒，直接触发开机
- 若短接后能开机，优先怀疑前面板按钮或连接线故障
- 若短接后仍无反应，再继续检查供电、内存、CPU 和 BIOS 状态

### JF1 常见针脚定义

| 针脚 | 功能 |
|------|------|
| 1, 2 | Power Button (`PWR_SW`) |
| 3, 4 | Reset Button |
| 5, 6 | Power Fail LED |
| 15, 16 | Power LED |

### JF1 位置提示

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
