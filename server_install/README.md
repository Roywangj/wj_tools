# Ubuntu 服务器装机与运维

本目录收录 Ubuntu 24.04 服务器从装机到日常运维的完整流程文档。

## 推荐阅读顺序

### 1. [install_ubuntu24.md](./install_ubuntu24.md) — 系统安装

Supermicro 主板上安装 Ubuntu 24.04 的完整记录，包括主板型号识别、BIOS 设置和系统安装流程。

### 2. [lab_server_infos/README.md](./lab_server_infos/README.md) — 实验室服务器资料

实验室服务器的硬件记录、主板与电源笔记、安装补充资料和故障排查入口。

### 3. [apt-mirror.md](./apt-mirror.md) — 换源

将 apt 源替换为清华镜像，覆盖 Ubuntu 24.04 新格式（`ubuntu.sources`）和旧格式（`sources.list`）两种情况。

### 4. [fix_ip.md](./fix_ip.md) — 固定 IP

通过 Netplan 配置静态 IP、网关和 DNS，适用于 Ubuntu 18.04+。

### 5. [driver.md](./driver.md) — NVIDIA 驱动

使用 `.run` 文件手动安装 NVIDIA 驱动，含 3090 驱动版本说明。

### 6. [cuda_cudnn.md](./cuda_cudnn.md) — CUDA & cuDNN

安装 CUDA 11.8 和 cuDNN 8.9.7，包括 gcc 版本兼容处理（Ubuntu 24.04 默认 gcc-13 需降级到 gcc-11）。

### 7. [gpu_burn.md](./gpu_burn.md) — GPU 压力测试

使用 gpu-burn 对 GPU 进行烤机测试，含编译报错排查。

### 8. [mount.md](./mount.md) — NFS 存储挂载

在计算节点挂载存储节点（10.106.15.88）的 NFS 共享目录，含存储端和客户端双侧配置。

### 9. [user_disk.md](./user_disk.md) — 硬盘管理

硬盘使用情况查询（`df`/`fdisk`/`du`）、分区格式化与挂载操作。

### 10. [ohmyzsh.md](./ohmyzsh.md) — Oh My Zsh

安装 zsh 并配置 Oh My Zsh，支持在线和离线两种安装方式。

## 脚本

[scripts/](./scripts/) 目录包含以下辅助脚本：

| 脚本 | 用途 |
|------|------|
| `adduser_data_basedrawroot.sh` | 批量创建用户并配置数据目录 |
| `install_tools.sh` | 常用工具一键安装 |
| `setup_ssh_key.sh` | SSH 密钥配置 |
| `serverlogin.py` | 服务器登录辅助 |
