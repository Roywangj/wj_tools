# wj_tools

一个面向日常开发环境配置、排障和工作流整理的文档仓库。

当前主要收录四类内容：

- 代理配置与远程开发代理方案
- LaTeX / Overleaf 写作环境配置
- Ubuntu 服务器 SSH 密钥登录配置
- Codex / Claude 相关使用与清理记录

## 快速导航

### 1. 我想配置代理

从这里开始：

- [proxy-setup-guide/README.md](./proxy-setup-guide/README.md)：统一代理配置总入口

按具体需求继续看：

- [proxy-setup-guide/proxy-setup-guide.md](./proxy-setup-guide/proxy-setup-guide.md)：完整配置指南
- [proxy-setup-guide/proxy-quick-reference.md](./proxy-setup-guide/proxy-quick-reference.md)：常用命令速查
- [proxy-setup-guide/服务器使用本地代理_laprf.md](./proxy-setup-guide/服务器使用本地代理_laprf.md)：服务器复用本地代理的补充方案
- [proxy-setup-guide/校园网认证失败.md](./proxy-setup-guide/校园网认证失败.md)：校园网认证脚本被代理影响时的排查

### 2. 我想配置 LaTeX / Overleaf 工作流

从这里开始：

- [latex-setup-guide/README.md](./latex-setup-guide/README.md)：LaTeX 环境配置总入口

按具体场景继续看：

- [latex-setup-guide/Overleaf_AI_IDE_Guide.md](./latex-setup-guide/Overleaf_AI_IDE_Guide.md)：优先方案，在 Cursor / VSCode 中直接打开 Overleaf 项目
- [latex-setup-guide/LaTeX_Setup_Guide.md](./latex-setup-guide/LaTeX_Setup_Guide.md)：macOS 本地 LaTeX 配置
- [latex-setup-guide/Local_LaTeX_Compiler_Setup.md](./latex-setup-guide/Local_LaTeX_Compiler_Setup.md)：本地编译器安装与通用配置思路

### 3. 我想清理 Claude / Anthropic 残留

- [codexclaude_usages/clean_claude_cache.md](./codexclaude_usages/clean_claude_cache.md)：macOS 下 Claude / Anthropic API 残留定位与清理记录

### 4. 我想配置 Ubuntu 服务器 SSH 密钥登录

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
│   └── sync-proxy-config.sh
├── latex-setup-guide/
│   ├── README.md
│   ├── Overleaf_AI_IDE_Guide.md
│   ├── LaTeX_Setup_Guide.md
│   └── Local_LaTeX_Compiler_Setup.md
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

**最后更新**: 2026-03-06
