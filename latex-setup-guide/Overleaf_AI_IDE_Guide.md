# 在 AI Coding IDE（Cursor / VSCode）中使用 Overleaf（优先）与本地兜底方案

目标：优先在 IDE 里直接打开 Overleaf 项目并继续使用 AI；如果 IDE 内无法访问 Overleaf（例如 Cursor / Antigravity 连不上），就把项目拉到本地并配置本地 LaTeX 编译。

参考文章：<https://zhuanlan.zhihu.com/p/15165556889>

---

## 方案 A：Overleaf 在 IDE 里“当前窗口打开项目”（可用就到这一步）

### 1) 安装 Overleaf 相关扩展

1. 打开 Cursor / VSCode。
2. 进入扩展（Extensions）面板。
3. 搜索 `Overleaf` 并安装你正在使用教程中对应的扩展（通常会带有登录、列出项目、打开项目等命令）。

> 如果你能在命令面板里看到类似 `Overleaf: Login` / `Overleaf: Open Project ...` 的命令，说明扩展安装成功。

### 2) 登录 Overleaf

1. 打开命令面板（macOS：`Cmd+Shift+P` / Windows/Linux：`Ctrl+Shift+P`）。
2. 输入并选择扩展提供的登录命令（例如 `Overleaf: Login`）。
3. 按提示在浏览器完成授权/登录。

### 3) 在“当前窗口”打开 Overleaf 项目

1. 命令面板中选择扩展提供的打开项目命令。
2. 选择 **Open project in current window**（或同义选项）。
3. 选择你的 Overleaf 项目并打开。

### 4) 检查 AI 是否还能正常工作

- 在该项目工作区内打开 AI 面板/聊天（Cursor / 你的 AI 插件）。
- 让 AI 读取项目结构（例如让它总结 `main.tex` / `tex` 入口文件），确认能访问项目文件即可。

如果这一步正常，后续就按你原来的写作方式即可；不需要本地安装 LaTeX 编译器。

---

## 方案 B：IDE 内无法访问 Overleaf → “本地打开项目” + 本地 LaTeX 编译

当出现以下情况时，建议直接走本地兜底方案：

- 扩展登录/列项目失败、一直转圈、提示网络错误。
- Cursor / Antigravity 环境无法访问 Overleaf（或 WebView 被拦截）。
- 打开项目成功但无法同步/无法拉取文件。

### 1) 把 Overleaf 项目拿到本地

**方式 A：扩展的 Open project locally**

- 在扩展里选择 **Open project locally**（或同义选项），按提示选择本地目录。
- 该方式通常会把项目下载到本地文件夹，然后你在本地工作区里编辑。

### 2) 安装本地 LaTeX 编译器 + IDE 编译配置

- macOS：按 `LaTeX_Setup_Guide.md` 安装 MacTeX 并配置 LaTeX Workshop（已包含“绝对路径”配置，适配 Cursor）。
- Windows / Linux：按 `Local_LaTeX_Compiler_Setup.md` 安装发行版并配置 LaTeX Workshop。

---

## 推荐工作流（最省事）

- 能用方案 A 就用方案 A：不用装任何本地 TeX，协作最轻。
- 方案 A 不稳定就切换方案 B：本地编辑 + 本地编译。
