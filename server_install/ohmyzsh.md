# Oh My Zsh 安装指南

## 1. 安装并切换 zsh

```bash
sudo apt-get install zsh

# 查看可用 shell
cat /etc/shells

# 切换默认 shell 为 zsh
chsh -s /bin/zsh
```

## 2. 安装 Oh My Zsh

### 方式一：在线安装

```bash
sh -c "$(wget -O- https://install.ohmyz.sh/)"
```

### 方式二：手动安装（无法联网时）

1. 下载 Oh My Zsh 压缩包，解压到 `~/.oh-my-zsh`（注意去掉目录名中的 `-master` 后缀）
2. 下载插件压缩包，解压到 `~/.oh-my-zsh/custom/plugins/`（同样去掉 `-master` 后缀）

### 方式三：gitee 安装（需要先安装完 gite）
```
git clone https://gitee.com/mirrors/oh-my-zsh.git  
```
然后重命名 `.oh-my-zsh`

## 3. 安装插件

```bash
# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions


# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
```
or
```bash
git clone https://gitee.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions


# zsh-syntax-highlighting
git clone https://gitee.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
```


## 4. 配置 .zshrc

从 `.bashrc` 中复制需要保留的内容到 `~/.zshrc`，并加入以下配置：

```bash
export ZSH="/home/user/.oh-my-zsh"
ZSH_THEME="cloud"
HIST_STAMPS="mm/dd/yyyy"
plugins=(
  git
  z
  zsh-autosuggestions
  zsh-syntax-highlighting
)
source $ZSH/oh-my-zsh.sh
```
