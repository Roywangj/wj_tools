# LaTeX 写作环境配置指南（Overleaf / 本地编译）

这个仓库用于记录两条最常用的 LaTeX 工作流：

1. **优先方案：在 AI Coding IDE（Cursor / VSCode）里直接打开 Overleaf 项目**（能用就不用装本地 TeX）。
2. **兜底方案：把 Overleaf 项目拉到本地 + 安装本地 LaTeX 编译器 + 用 LaTeX Workshop 编译预览**（适用于 IDE 无法访问 Overleaf 的情况）。

---

## 快速开始（按你的情况选一条）

### A. Overleaf 在 IDE 里打开（推荐）

- 按 [Overleaf_AI_IDE_Guide.md](Overleaf_AI_IDE_Guide.md) 操作：安装 Overleaf 扩展 → 登录 → **Open project in current window** → 检查 AI 是否能正常读取项目文件。

### B. 无法访问 Overleaf → 本地打开 + 本地编译

- 先把项目拿到本地（扩展的 **Open project locally**）。
- 再按以下文档安装本地 LaTeX 编译器并配置 LaTeX Workshop：
  - macOS：[LaTeX_Setup_Guide.md](LaTeX_Setup_Guide.md)
  - Windows / Linux：[Local_LaTeX_Compiler_Setup.md](Local_LaTeX_Compiler_Setup.md)

---

## 文档索引

- [Overleaf_AI_IDE_Guide.md](Overleaf_AI_IDE_Guide.md)：在 Cursor/VSCode 中使用 Overleaf（可用则到“当前窗口打开项目”为止；不可用则给出本地兜底方案）。
- [Local_LaTeX_Compiler_Setup.md](Local_LaTeX_Compiler_Setup.md)：Windows / Linux / macOS 的本地 LaTeX 发行版安装与 LaTeX Workshop 绝对路径思路。
- [LaTeX_Setup_Guide.md](LaTeX_Setup_Guide.md)：macOS 从零配置（Cursor/VSCode + LaTeX Workshop + MacTeX），包含常见报错排查与 `.vscode/settings.json` 示例。
