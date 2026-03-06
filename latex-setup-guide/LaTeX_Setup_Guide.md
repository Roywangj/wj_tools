# macOS 上从零配置 LaTeX 写作环境（Cursor / VSCode + LaTeX Workshop + MacTeX）

本文档记录如何在 macOS 上搭建一个完整的 LaTeX 写作环境，使用 **Cursor**（或 VSCode）作为编辑器，**LaTeX Workshop** 插件进行编译预览，**MacTeX** 作为 TeX 发行版。

快速入口：
- 优先走 Overleaf（能用就不用本地装 TeX）：`Overleaf_AI_IDE_Guide.md`
- 如果需要本地编译（含 Windows / Linux 快速指引）：`Local_LaTeX_Compiler_Setup.md`

---

## 目录

1. [安装 MacTeX](#1-安装-mactex)
2. [配置环境变量（可选）](#2-配置环境变量可选)
3. [安装 Cursor / VSCode](#3-安装-cursor--vscode)
4. [安装 LaTeX Workshop 插件](#4-安装-latex-workshop-插件)
5. [配置 LaTeX Workshop（核心步骤）](#5-配置-latex-workshop核心步骤)
6. [编译与预览 LaTeX 文档](#6-编译与预览-latex-文档)
7. [常见问题排查](#7-常见问题排查)

---

## 1. 安装 MacTeX

MacTeX 是 macOS 上最完整的 TeX 发行版，包含 `pdflatex`、`latexmk`、`bibtex` 等所有常用工具。

### 下载

访问官网：<https://www.tug.org/mactex/>

点击 **MacTeX Download** 下载 `.pkg` 安装包（约 4-5 GB）。

> 如果只需要核心工具，可以选择 **BasicTeX**（约 100 MB），但可能缺少部分宏包，新手建议装完整版。

### 安装

1. 双击下载的 `.pkg` 文件；
2. 按提示一路点击"继续"、"安装"；
3. 安装完成后，TeX 工具会被放在 `/Library/TeX/texbin/` 目录下。

### 验证安装

打开终端（Terminal.app），运行：

```bash
which pdflatex
which latexmk
```

如果输出类似：

```
/Library/TeX/texbin/pdflatex
/Library/TeX/texbin/latexmk
```

说明安装成功。

---

## 2. 配置环境变量（可选）

macOS 的 GUI 应用（如 Cursor）启动时，不一定能继承终端里的 `PATH`。

### 对于 zsh（macOS 默认 shell）

编辑 `~/.zshrc`：

```bash
nano ~/.zshrc
```

在文件末尾添加：

```zsh
# MacTeX PATH 设置
if [ -d "/Library/TeX/texbin" ]; then
  export PATH="/Library/TeX/texbin:$PATH"
fi
```

保存后执行：

```bash
source ~/.zshrc
```

验证：

```bash
which latexmk
# 应输出 /Library/TeX/texbin/latexmk
```

> ⚠️ **重要提示**：即使配置了 `~/.zshrc`，从 Dock 或 Spotlight 启动的 Cursor **仍然可能读不到这个 PATH**。  
> 因此，**必须按照下面第 5 节的方法配置 LaTeX Workshop**，使用绝对路径才能确保编译正常。

---

## 3. 安装 Cursor / VSCode

### Cursor

访问：<https://cursor.sh/>  
下载 macOS 版本，拖入 Applications 文件夹即可。

### VSCode

访问：<https://code.visualstudio.com/>  
下载 macOS 版本，拖入 Applications 文件夹。

两者操作方式几乎一致，下文以 Cursor 为例。

---

## 4. 安装 LaTeX Workshop 插件

1. 打开 Cursor；
2. 按 `Cmd + Shift + X` 打开扩展面板；
3. 搜索 **LaTeX Workshop**（作者：James Yu）；
4. 点击 **Install** 安装。

安装完成后，打开任意 `.tex` 文件，插件会自动激活。

---

## 5. 配置 LaTeX Workshop（核心步骤）

### 为什么需要配置？

LaTeX Workshop 默认调用 `latexmk` 命令，但 Cursor 进程的 `PATH` 里通常没有 `/Library/TeX/texbin`，会报错：

```
Error: spawn latexmk ENOENT
```

或者即使 `latexmk` 能找到，它内部调用 `pdflatex` 时又会报：

```
sh: pdflatex: command not found
```

### 解决方案

**在配置里写死所有 TeX 工具的绝对路径**，包括：
- `latexmk` 的路径
- `latexmk` 内部调用的 `pdflatex` 路径（通过 `-pdflatex=` 参数指定）

### 配置方法（工作区级别，推荐）

在你的 LaTeX 项目根目录下，创建 `.vscode/settings.json` 文件（如果已存在则编辑），写入以下内容：

```json
{
  "latex-workshop.formatting.latex": "latexindent",
  "latex-workshop.formatting.latexindent.path": "/Library/TeX/texbin/latexindent",

  // LaTeX Workshop 使用 MacTeX（所有路径都用绝对路径）
  "latex-workshop.latex.tools": [
    {
      "name": "latexmk-mactex",
      "command": "/Library/TeX/texbin/latexmk",
      "args": [
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "-pdf",
        "-pdflatex=/Library/TeX/texbin/pdflatex",
        "-outdir=%OUTDIR%",
        "%DOC%"
      ]
    },
    {
      "name": "xelatex-mactex",
      "command": "/Library/TeX/texbin/latexmk",
      "args": [
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "-xelatex",
        "-xelatex=/Library/TeX/texbin/xelatex",
        "-outdir=%OUTDIR%",
        "%DOC%"
      ]
    },
    {
      "name": "pdflatex-mactex",
      "command": "/Library/TeX/texbin/pdflatex",
      "args": [
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "-output-directory=%OUTDIR%",
        "%DOC%"
      ]
    },
    {
      "name": "bibtex-mactex",
      "command": "/Library/TeX/texbin/bibtex",
      "args": [
        "%DOCFILE%"
      ]
    }
  ],

  // 定义编译流程（recipe）
  "latex-workshop.latex.recipes": [
    {
      "name": "latexmk (MacTeX)",
      "tools": ["latexmk-mactex"]
    },
    {
      "name": "xelatex (MacTeX)",
      "tools": ["xelatex-mactex"]
    },
    {
      "name": "pdflatex -> bibtex -> pdflatex x2",
      "tools": ["pdflatex-mactex", "bibtex-mactex", "pdflatex-mactex", "pdflatex-mactex"]
    }
  ],

  // 输出目录：与 .tex 文件同目录
  "latex-workshop.latex.outDir": "%DIR%",

  // 保存时自动编译（如果不想自动编译，改成 "never"）
  "latex-workshop.latex.autoBuild.run": "onSave"
}
```

### 关键配置说明

| 配置项 | 说明 |
|--------|------|
| `-pdflatex=/Library/TeX/texbin/pdflatex` | **关键！** 告诉 `latexmk` 用绝对路径调用 `pdflatex`，否则会报 `pdflatex: command not found` |
| `latex-workshop.latex.tools` | 定义可用的编译工具，每个工具指定命令和参数 |
| `latex-workshop.latex.recipes` | 定义编译流程，可以组合多个工具 |
| `latex-workshop.latex.autoBuild.run` | `onSave` = 保存时自动编译；`never` = 手动编译 |
| `latex-workshop.latex.outDir` | 编译输出目录，`%DIR%` 表示与 .tex 文件同目录 |

---

## 6. 编译与预览 LaTeX 文档

### 方法一：保存时自动编译

如果配置了 `"latex-workshop.latex.autoBuild.run": "onSave"`，每次按 `Cmd + S` 保存 `.tex` 文件时，会自动触发编译。

### 方法二：手动编译

1. 打开 `.tex` 文件；
2. 按 `Cmd + Shift + P` 打开命令面板；
3. 输入并选择：**LaTeX Workshop: Build with recipe**；
4. 选择你想用的 recipe（如 `latexmk (MacTeX)`）。

### 方法三：终端手动编译（调试用）

如果 LaTeX Workshop 编译失败，可以在终端里手动运行，方便查看详细错误：

```bash
cd /path/to/your/project
/Library/TeX/texbin/latexmk -synctex=1 -interaction=nonstopmode -file-line-error -pdf -pdflatex=/Library/TeX/texbin/pdflatex your_file.tex
```

### 预览 PDF

1. 按 `Cmd + Shift + P`；
2. 选择：**LaTeX Workshop: View LaTeX PDF**；
3. PDF 会在右侧标签页中打开。

或者直接点击编辑器右上角的"预览"图标（放大镜 + PDF 图标）。

### 正向 / 反向搜索（SyncTeX）

- **正向搜索**（从 .tex 跳转到 PDF 对应位置）：  
  在 `.tex` 文件中，`Cmd + 点击` 某行，PDF 会滚动到对应位置。

- **反向搜索**（从 PDF 跳转到 .tex 对应位置）：  
  在 PDF 预览中，`Cmd + 点击` 某处，编辑器会跳转到对应的 `.tex` 代码行。

---

## 7. 常见问题排查

### 问题 1：`spawn latexmk ENOENT`

**原因**：Cursor 进程的 `PATH` 里没有 `/Library/TeX/texbin`。

**解决**：在 `.vscode/settings.json` 里把 `latexmk` 的 `command` 改成绝对路径 `/Library/TeX/texbin/latexmk`（见上面配置）。

---

### 问题 2：`sh: pdflatex: command not found`

**原因**：`latexmk` 能找到了，但它内部调用 `pdflatex` 时，Cursor 的 `PATH` 里仍然没有 `/Library/TeX/texbin`。

**解决**：在 `latexmk` 的 `args` 里加上 `-pdflatex=/Library/TeX/texbin/pdflatex` 参数，让 `latexmk` 也用绝对路径调用 `pdflatex`。

```json
"args": [
  "-synctex=1",
  "-interaction=nonstopmode",
  "-file-line-error",
  "-pdf",
  "-pdflatex=/Library/TeX/texbin/pdflatex",  // 关键！
  "-outdir=%OUTDIR%",
  "%DOC%"
]
```

---

### 问题 3：PDF 预览空白

**可能原因**：
1. 编译失败，PDF 没有生成；
2. PDF 已生成但预览器没刷新。

**解决**：
1. 查看 LaTeX Workshop 的"输出"面板（`Cmd + Shift + U`，选择 `LaTeX Compiler`），看有没有编译错误；
2. 关闭 PDF 标签页，重新打开；
3. 在终端里手动编译确认：
   ```bash
   cd /path/to/your/project
   /Library/TeX/texbin/latexmk -pdf -pdflatex=/Library/TeX/texbin/pdflatex your_file.tex
   ```

---

### 问题 4：缺少宏包 `! LaTeX Error: File 'xxx.sty' not found.`

**原因**：所需的 LaTeX 宏包没有安装。

**解决**：使用 TeX Live 的包管理器安装：

```bash
sudo /Library/TeX/texbin/tlmgr install <package_name>
```

例如：

```bash
sudo /Library/TeX/texbin/tlmgr install enumitem
```

---

### 问题 5：BibTeX 引用不显示

**原因**：需要多次编译才能正确解析引用。

**解决**：使用 `latexmk`（它会自动处理多次编译），或者手动按顺序运行：

```bash
/Library/TeX/texbin/pdflatex main.tex
/Library/TeX/texbin/bibtex main
/Library/TeX/texbin/pdflatex main.tex
/Library/TeX/texbin/pdflatex main.tex
```

---

### 问题 6：中文显示乱码 / 无法编译中文

**原因**：`pdflatex` 对中文支持有限。

**解决**：改用 `xelatex`。使用上面配置中的 `xelatex (MacTeX)` recipe，同时在 `.tex` 文件中使用 `ctex` 宏包或 `xeCJK` 宏包处理中文：

```latex
\usepackage{ctex}
% 或
\usepackage{xeCJK}
```

---

## 附录：完整的 `.vscode/settings.json` 示例

```json
{
  "latex-workshop.formatting.latex": "latexindent",
  "latex-workshop.formatting.latexindent.path": "/Library/TeX/texbin/latexindent",

  "latex-workshop.latex.tools": [
    {
      "name": "latexmk-mactex",
      "command": "/Library/TeX/texbin/latexmk",
      "args": [
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "-pdf",
        "-pdflatex=/Library/TeX/texbin/pdflatex",
        "-outdir=%OUTDIR%",
        "%DOC%"
      ]
    },
    {
      "name": "xelatex-mactex",
      "command": "/Library/TeX/texbin/latexmk",
      "args": [
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "-xelatex",
        "-xelatex=/Library/TeX/texbin/xelatex",
        "-outdir=%OUTDIR%",
        "%DOC%"
      ]
    },
    {
      "name": "pdflatex-mactex",
      "command": "/Library/TeX/texbin/pdflatex",
      "args": [
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "-output-directory=%OUTDIR%",
        "%DOC%"
      ]
    },
    {
      "name": "bibtex-mactex",
      "command": "/Library/TeX/texbin/bibtex",
      "args": [
        "%DOCFILE%"
      ]
    }
  ],

  "latex-workshop.latex.recipes": [
    {
      "name": "latexmk (MacTeX)",
      "tools": ["latexmk-mactex"]
    },
    {
      "name": "xelatex (MacTeX)",
      "tools": ["xelatex-mactex"]
    },
    {
      "name": "pdflatex -> bibtex -> pdflatex x2",
      "tools": ["pdflatex-mactex", "bibtex-mactex", "pdflatex-mactex", "pdflatex-mactex"]
    }
  ],

  "latex-workshop.latex.outDir": "%DIR%",
  "latex-workshop.latex.autoBuild.run": "onSave"
}
```

---

## 参考链接

- MacTeX 官网：<https://www.tug.org/mactex/>
- LaTeX Workshop 文档：<https://github.com/James-Yu/LaTeX-Workshop/wiki>
- TeX Live 包管理器 (tlmgr)：<https://www.tug.org/texlive/tlmgr.html>

---

*文档创建日期：2025-12-03*  
*最后更新：2025-12-03（增加 `-pdflatex=` 绝对路径配置，解决 `pdflatex: command not found` 问题）*
