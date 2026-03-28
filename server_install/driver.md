# NVIDIA Driver Installation Guide

> **3090 用户注意**: 请使用 `NVIDIA-Linux-x86_64-595.45.04.run`

---

## 安装步骤

### 1. 下载驱动

```bash
wget https://cn.download.nvidia.com/XFree86/Linux-x86_64/515.105.01/NVIDIA-Linux-x86_64-515.105.01.run
```

### 2. 赋予执行权限

```bash
sudo chmod +x NVIDIA-Linux-x86_64-515.105.01.run
```

### 3. 卸载原驱动

```bash
sudo ./NVIDIA-Linux-x86_64-460.84.run --uninstall
```

### 4. 检查状态

```bash
nvidia-smi
```

此刻应显示无驱动。

### 5. 重启

```bash
sudo reboot
```

### 6. 安装新驱动

```bash
sudo ./NVIDIA-Linux-x86_64-515.105.01.run -no-x-check -no-nouveau-check -no-opengl-files
```

---

## 编译内核失败：更换 GCC 版本

参考：<https://blog.loxx.cn/archives/1712109364218>

```bash
# 查看当前 gcc 版本
gcc --version

# 安装 gcc-12
sudo apt update
sudo apt install gcc-12 g++-12

# 注册 gcc-11 到 update-alternatives
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 11 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-11 \
  --slave /usr/bin/gcov gcov /usr/bin/gcov-11

# 注册 gcc-12 到 update-alternatives
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 12 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-12 \
  --slave /usr/bin/gcov gcov /usr/bin/gcov-12

# 交互式选择 gcc 版本
sudo update-alternatives --config gcc
```

参考：<https://zhuanlan.zhihu.com/p/261001751>

---

## 错误：Unable to find the development tool `cc`

**报错信息：**
```
ERROR: Unable to find the development tool `cc` in your path; please make sure
that you have the package 'gcc' installed.
```

**原因：** 系统缺少 `gcc` / `build-essential`，或 `cc` 符号链接未建立。

### 解决方案

**方案一：安装 build-essential（推荐）**

```bash
sudo apt update
sudo apt install -y build-essential
```

`build-essential` 包含 gcc、g++、make 以及 `cc` 符号链接，一步到位。

**方案二：单独安装 gcc 并手动创建 cc 链接**

```bash
sudo apt update
sudo apt install -y gcc

# 手动建立 cc 软链接（如果仍提示找不到 cc）
sudo ln -s /usr/bin/gcc /usr/bin/cc
```

**方案三：安装内核头文件（编译驱动必须）**

```bash
sudo apt install -y linux-headers-$(uname -r)
```

**验证安装：**

```bash
cc --version
gcc --version
ls /usr/src/linux-headers-$(uname -r)
```

确认上述命令均正常输出后，重新执行驱动安装命令。

---

## 错误：Unable to load the kernel module 'nvidia.ko'

### 报错信息

```text
ERROR: Unable to load the kernel module 'nvidia.ko'. This happens most frequently
when this kernel module was built against the wrong or improperly configured kernel
sources, with a version of gcc that differs from the one used to build the target kernel,
or if another driver, such as nouveau, is present...
```

### 排查步骤

#### 1. 查看安装日志

```bash
cat /var/log/nvidia-installer.log | tail -50
```

#### 2. 禁用 nouveau 驱动

nouveau 是开源 NVIDIA 驱动，会与官方驱动冲突，必须禁用。

```bash
# 检查 nouveau 是否加载
lsmod | grep nouveau
```

##### 创建黑名单文件（纯命令行逐步操作）

在终端逐行输入（每行输完按回车）：

```bash
sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null <<'EOF'
```

终端会出现 `>` 提示符，继续输入：

```text
blacklist nouveau
```

回车，再输入：

```text
options nouveau modeset=0
```

回车，最后输入：

```text
EOF
```

回车，文件写入完成。

##### 更新 initramfs

```bash
sudo update-initramfs -u
```

##### 切换到纯文本模式并重启

黑名单在图形模式下可能不生效（nouveau 被桌面环境占用），需要切到纯文本模式：

```bash
sudo systemctl set-default multi-user.target
sudo reboot
```

##### 重启后验证

在 tty 登录后执行：

```bash
lsmod | grep nouveau
```

应无输出。如仍有输出，手动卸载：

```bash
sudo modprobe -r nouveau
```

如报 `Module nouveau is in use`，查看占用进程：

```bash
sudo lsof /dev/dri/*
```

kill 占用进程后再次 `sudo modprobe -r nouveau`。

##### 安装完成后恢复图形模式

```bash
sudo systemctl set-default graphical.target
sudo reboot
```

---

## 图形界面相关命令区别

| 命令 | 作用 | 使用场景 |
|------|------|----------|
| `sudo systemctl restart gdm` | 重启 GDM 登录管理器（图形登录界面） | 图形界面卡死或黑屏，快速重启桌面，**不需要重启系统** |
| `sudo systemctl set-default graphical.target` | 设置开机默认启动到图形模式 | 之前用 `set-default multi-user.target` 切换到了纯文本模式，安装完驱动后用此命令**恢复开机进图形界面**，需重启生效 |

简单来说：
- `restart gdm` = 重启当前图形界面（立即生效）
- `set-default graphical.target` = 设置下次开机启动模式（重启后生效）

#### 3. 确保 GCC 版本与内核编译版本一致

```bash
# 查看内核编译使用的 gcc 版本
cat /proc/version

# 查看当前 gcc 版本
gcc --version
```

两者大版本号应一致（如都是 gcc-12），不一致请参考上方「更换 GCC 版本」章节。

#### 4. 安装匹配的内核头文件

```bash
# 查看当前内核版本
uname -r

# 安装对应头文件
sudo apt install -y linux-headers-$(uname -r)
```

#### 5. 卸载残留驱动

```bash
# 卸载可能存在的旧驱动
sudo apt remove --purge -y nvidia-* libnvidia-*
sudo apt autoremove -y

# 如果之前用 .run 安装过
sudo ./NVIDIA-Linux-x86_64-*.run --uninstall
```

#### 6. 重新安装

完成上述步骤后重启，再执行安装：

```bash
sudo reboot

# 重启后
sudo ./NVIDIA-Linux-x86_64-515.105.01.run -no-x-check -no-nouveau-check -no-opengl-files
```

#### 7. 如仍失败：尝试 DKMS 方式安装

```bash
sudo apt update
sudo apt install -y dkms
sudo ./NVIDIA-Linux-x86_64-515.105.01.run --dkms -no-x-check -no-nouveau-check -no-opengl-files
```
