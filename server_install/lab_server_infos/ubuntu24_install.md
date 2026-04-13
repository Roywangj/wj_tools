# Ubuntu 24.04 安装笔记

## 适用范围

本文记录 Ubuntu 24.04 在实验室服务器上的安装流程与安装期问题。

主板识别、上电排查和电源相关说明已统一整理到 [`motherboard_notes.md`](./motherboard_notes.md)。

## BIOS 启动设置

- 开机时连续按 `Delete` 键进入 BIOS
- 不需要手动添加 "Add New Boot Option"，BIOS 会自动识别 U 盘
- 推荐使用一次性启动菜单（`F12` / `F11` / `Esc` / `F8`，具体取决于主板品牌）
- 如果 U 盘不出现在启动列表，检查：
  - 关闭 Secure Boot
  - 关闭 Fast Boot

## U 盘说明

- aigo U 盘默认只有 1 个分区
- 若需手动添加 Boot Option，路径填 `\EFI\BOOT\BOOTx64.EFI`，分区选 Partition 1

## 安装选项选择

- 选择 **`Try or Install Ubuntu`**（默认第一项）
- `Ubuntu (safe graphics)` 仅在花屏、黑屏、画面异常时使用

## 多硬盘情况（1 个启动盘 + 1 个数据盘）

- 分区步骤选择 **`Something else`**（手动分区），避免误格式化数据盘
- 安装前确认各盘符（如 `/dev/sda`、`/dev/sdb`）
- 更稳妥的方式是先拔掉数据盘，装完系统后再插回

### 建议分区方案（仅对启动盘操作）

| 分区 | 大小 | 格式 | 挂载点 |
| --- | --- | --- | --- |
| EFI | 512MB | FAT32 | `/boot/efi` |
| swap | 与内存大小相同 | swap | - |
| 根分区 | 剩余全部 | ext4 | `/` |

## 常见安装报错

### `/init: line 38: can't open /dev/xxx: No medium found`

原因：内核启动后 USB 3.0 驱动未及时加载，导致 U 盘在安装过程中“消失”。

处理方法：

- 将 U 盘换插到 USB 2.0 接口
- 优先尝试主板背部接口
- 重新启动安装流程
