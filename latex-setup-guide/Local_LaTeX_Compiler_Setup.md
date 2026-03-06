# 本地安装 LaTeX 编译器（Windows / Linux / macOS 快速指引）

当 Overleaf 无法在 IDE 内访问（或你选择 “Open project locally”）时，需要在本机安装 LaTeX 发行版，才能用 LaTeX Workshop 本地编译预览。

macOS 详细版本见：`LaTeX_Setup_Guide.md`（MacTeX + Cursor/VSCode + LaTeX Workshop，包含绝对路径配置）。

---

## 1) Windows

### 方案 A：MiKTeX（上手快）

1. 安装 MiKTeX：<https://miktex.org/download>
2. 安装后重启 IDE（Cursor / VSCode）。
3. 在终端验证：

```powershell
where pdflatex
where latexmk
```

如果找不到命令：
- 确认 MiKTeX 的 `bin` 目录在系统 PATH；
- 或者在 LaTeX Workshop 里使用“绝对路径”配置（见下文）。

### 方案 B：TeX Live（更接近 Overleaf 环境）

- TeX Live 安装较大，但与 Overleaf/TeX Live 更一致：<https://tug.org/texlive/>
- 安装完成后同样用 `where latexmk` 验证。

---

## 2) Linux（TeX Live）

不同发行版命令不同，目标是装到 `latexmk` / `pdflatex` / `xelatex` 可用即可。

### Ubuntu / Debian

```bash
sudo apt update
sudo apt install -y texlive-full
```

如果你只想装常用集合（体积更小），可先从：

```bash
sudo apt install -y texlive-latex-extra texlive-lang-chinese latexmk
```

### Arch / Manjaro

```bash
sudo pacman -S texlive-most texlive-langchinese
```

### 验证

```bash
which pdflatex
which latexmk
```

---

## 3) macOS（简版指引）

- 建议直接按 `LaTeX_Setup_Guide.md` 安装 MacTeX（或 BasicTeX）并按文档配置 LaTeX Workshop（解决 Cursor 进程 PATH 继承问题）。

---

## 4) LaTeX Workshop：如果 IDE 找不到命令，改用绝对路径

典型报错：

- `spawn latexmk ENOENT`
- `pdflatex: command not found`

解决思路：像 `LaTeX_Setup_Guide.md` 一样，在项目的 `.vscode/settings.json` 里把 `command` 写成绝对路径，并在 `latexmk` 参数里显式指定 `-pdflatex=` / `-xelatex=`。

### Windows 如何找到绝对路径

```powershell
where latexmk
where pdflatex
where xelatex
```

把输出的路径填到 `.vscode/settings.json` 里（注意 JSON 里反斜杠要写成 `\\`）。

### Linux 如何找到绝对路径

```bash
which latexmk
which pdflatex
which xelatex
```

---

## 5) 推荐编译命令（用于排错）

在项目目录下运行（把 `main.tex` 换成你的入口文件）：

```bash
latexmk -synctex=1 -interaction=nonstopmode -file-line-error -pdf main.tex
```

如果需要中文/字体更顺滑，推荐 XeLaTeX：

```bash
latexmk -synctex=1 -interaction=nonstopmode -file-line-error -xelatex main.tex
```

