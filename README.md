# wj_tools

一个面向日常开发环境配置、排障和工作流整理的文档仓库。

当前主要收录五类内容：

- 代理配置、HuggingFace 镜像下载、网络排障与开发机反向连接
- LaTeX / Overleaf 写作环境配置
- Ubuntu 服务器 SSH 密钥登录配置
- Codex / Claude 相关使用与清理记录
- Ubuntu 服务器装机与运维

## 快速导航

### 1. 我想配置代理 / 下载模型 / 排查网络

从这里开始：

- [proxy-setup-guide/README.md](./proxy-setup-guide/README.md)：统一代理配置总入口

按具体需求继续看：

- [proxy-setup-guide/proxy-setup-guide.md](./proxy-setup-guide/proxy-setup-guide.md)：完整配置指南
- [proxy-setup-guide/proxy-quick-reference.md](./proxy-setup-guide/proxy-quick-reference.md)：常用命令速查
- [proxy-setup-guide/服务器使用本地代理_laprf.md](./proxy-setup-guide/服务器使用本地代理_laprf.md)：服务器复用本地代理的补充方案
- [proxy-setup-guide/校园网认证失败.md](./proxy-setup-guide/校园网认证失败.md)：校园网认证脚本被代理影响时的排查

**稳定下载 HuggingFace 模型 / 数据集**（`hf-mirror.com` 是国内镜像，要直连、不能走国外代理，否则「开了代理反而下不动」）：

- [proxy-setup-guide/hf-download.sh](./proxy-setup-guide/hf-download.sh)：包装 `huggingface-cli / hf`，下载期间**临时关代理（仅本进程）**并强制 `HF_ENDPOINT=hf-mirror`；支持 include/exclude 过滤、`hf_transfer`、aria2c。建议加别名 `alias hfd='~/wj_tools/proxy-setup-guide/hf-download.sh'`
- [proxy-setup-guide/hfd.sh](./proxy-setup-guide/hfd.sh)：纯 aria2c 多连接高速下载器（仿官方 hfd），只依赖 `curl / python3 / aria2c`，支持断点续传、include/exclude、私有库 token、模型/数据集

**网络体检与排障**：

- [proxy-setup-guide/net-doctor.sh](./proxy-setup-guide/net-doctor.sh)：分层定位「开了代理却下不动」——基础网络 / DNS / 直连连通 / 代理体检 / HF 镜像专项，末尾给一句话结论 + 可复制的修复命令；`--fix` 清理拖累镜像的 git 全局代理

**从开发机反向连回本地 Mac（远程开发反连）**：

- [proxy-setup-guide/SSH反向隧道-开发机回连Mac.md](./proxy-setup-guide/SSH反向隧道-开发机回连Mac.md)：在云端开发机上反向 `ssh` 回本地 Mac，并借 Mac 网络访问只有 Mac 能路由到的私网服务器（`RemoteForward` 反向隧道方案，含配置、用法、保活与安全关停）

### 2. 我想配置 LaTeX / Overleaf 工作流

从这里开始：

- [latex-setup-guide/README.md](./latex-setup-guide/README.md)：LaTeX 环境配置总入口

按具体场景继续看：

- [latex-setup-guide/Overleaf_AI_IDE_Guide.md](./latex-setup-guide/Overleaf_AI_IDE_Guide.md)：优先方案，在 Cursor / VSCode 中直接打开 Overleaf 项目
- [latex-setup-guide/LaTeX_Setup_Guide.md](./latex-setup-guide/LaTeX_Setup_Guide.md)：macOS 本地 LaTeX 配置
- [latex-setup-guide/Local_LaTeX_Compiler_Setup.md](./latex-setup-guide/Local_LaTeX_Compiler_Setup.md)：本地编译器安装与通用配置思路

### 3. 我想清理 Claude / Anthropic 残留

- [codexclaude_usages/clean_claude_cache.md](./codexclaude_usages/clean_claude_cache.md)：macOS 下 Claude / Anthropic API 残留定位与清理记录

### 4. 我想装机 / 运维 Ubuntu 服务器

从这里开始：

- [server_install/install_ubuntu24.md](./server_install/install_ubuntu24.md)：Ubuntu 24.04 安装笔记（Supermicro 主板）

按具体需求继续看：

- [server_install/apt-mirror.md](./server_install/apt-mirror.md)：Ubuntu 换源（清华镜像）
- [server_install/fix_ip.md](./server_install/fix_ip.md)：Netplan 固定 IP 配置
- [server_install/driver.md](./server_install/driver.md)：NVIDIA 驱动安装
- [server_install/cuda_cudnn.md](./server_install/cuda_cudnn.md)：CUDA 11.8 & cuDNN 8.9 安装
- [server_install/gpu_burn.md](./server_install/gpu_burn.md)：GPU Burn 压力测试
- [server_install/mount.md](./server_install/mount.md)：NFS 存储挂载
- [server_install/user_disk.md](./server_install/user_disk.md)：硬盘查询、清理与挂载
- [server_install/ohmyzsh.md](./server_install/ohmyzsh.md)：Oh My Zsh 安装
- [server_install/scripts/](./server_install/scripts/)：批量建用户、SSH 密钥配置、常用工具安装等脚本

### 5. 我想配置 Ubuntu 服务器 SSH 密钥登录

从这里开始：

- [Set-up-ssh-keys-on-ubuntu16.04-18.04/README.md](./Set-up-ssh-keys-on-ubuntu16.04-18.04/README.md)：Ubuntu 16.04 / 18.04 SSH 密钥登录总入口

按角色继续看：

- [Set-up-ssh-keys-on-ubuntu16.04-18.04/普通用户/README.md](./Set-up-ssh-keys-on-ubuntu16.04-18.04/普通用户/README.md)：普通用户生成密钥、安装公钥和测试登录
- [Set-up-ssh-keys-on-ubuntu16.04-18.04/管理员用户/README.md](./Set-up-ssh-keys-on-ubuntu16.04-18.04/管理员用户/README.md)：管理员开启公钥认证并关闭密码登录
- [Set-up-ssh-keys-on-ubuntu16.04-18.04/普通用户/修改权限/修改权限.md](./Set-up-ssh-keys-on-ubuntu16.04-18.04/普通用户/修改权限/修改权限.md)：Windows 本地私钥权限修复

## 仓库结构

```text
wj_tools/
├── proxy-setup-guide/
│   ├── README.md
│   ├── proxy-setup-guide.md
│   ├── proxy-quick-reference.md
│   ├── 服务器使用本地代理_laprf.md
│   ├── 校园网认证失败.md
│   ├── SSH反向隧道-开发机回连Mac.md   # 开发机反向连回本地 Mac 及其私网服务器
│   ├── hf-download.sh                  # HF 镜像稳定下载（包装 huggingface-cli/hf）
│   ├── hfd.sh                          # HF 镜像高速下载（aria2c 多连接）
│   ├── net-doctor.sh                   # 网络体检 / 排障（HF 镜像 + 代理）
│   └── sync-proxy-config.sh
├── latex-setup-guide/
│   ├── README.md
│   ├── Overleaf_AI_IDE_Guide.md
│   ├── LaTeX_Setup_Guide.md
│   └── Local_LaTeX_Compiler_Setup.md
├── server_install/
│   ├── install_ubuntu24.md
│   ├── apt-mirror.md
│   ├── fix_ip.md
│   ├── driver.md
│   ├── cuda_cudnn.md
│   ├── gpu_burn.md
│   ├── mount.md
│   ├── user_disk.md
│   ├── ohmyzsh.md
│   └── scripts/
├── Set-up-ssh-keys-on-ubuntu16.04-18.04/
│   ├── README.md
│   ├── 普通用户/
│   │   ├── README.md
│   │   ├── 测试密钥/测试密钥.md
│   │   └── 修改权限/修改权限.md
│   └── 管理员用户/
│       └── README.md
└── codexclaude_usages/
    └── clean_claude_cache.md
```

## 使用建议

- 优先阅读各子目录里的 `README.md`，它们已经按场景整理了入口顺序。
- 如果你只想快速落地配置，先看速查或补充方案，不必从长文档头开始读。
- 如果你要修改现有方案，建议同时更新对应子目录下的 `README.md` 和详细说明文档，避免入口文档与正文不一致。

## 适用环境

- macOS
- Linux
- Zsh / Bash
- VSCode / Cursor

部分文档默认基于我当前使用场景编写，因此会偏向远程开发、代理、Overleaf、本地工具链配置，以及 Ubuntu 服务器的 SSH 密钥登录。

---

**最后更新**: 2026-07-07
