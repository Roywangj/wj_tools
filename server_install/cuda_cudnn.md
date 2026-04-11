# CUDA & cuDNN 安装记录

## 版本信息

| 组件   | 版本                        | 安装包                                            |
|--------|-----------------------------|---------------------------------------------------|
| CUDA   | 11.8.0 (Driver 520.61.05)   | `cuda_11.8.0_520.61.05_linux.run`                 |
| cuDNN  | 8.9.7.29 (for CUDA 11)      | `cudnn-linux-x86_64-8.9.7.29_cuda11-archive.tar.xz` |

---

## 安装步骤

### 1. 安装 gcc-11（CUDA 11.8 最高支持 gcc 11，Ubuntu 24.04 默认 gcc-13 不兼容）

```bash
sudo apt install gcc-11 g++-11

# 设置 gcc-11 为默认
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 11
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 11
sudo update-alternatives --config gcc  # 选 gcc-11
```

### 2. 安装 CUDA 11.8

```bash
sudo bash cuda_11.8.0_520.61.05_linux.run
```

> 如仍报 gcc 版本错误，可加 `--override` 跳过检查：
>
> ```bash
> sudo bash cuda_11.8.0_520.61.05_linux.run --override
> ```
>
> 安装时 Driver 可跳过（服务器已有驱动时），只选 Toolkit 即可。
> 安装完成后 Toolkit 路径：`/usr/local/cuda-11.8/`

### 3. 安装 cuDNN 8.9.7

```bash
tar -xf cudnn-linux-x86_64-8.9.7.29_cuda11-archive.tar.xz
cd cudnn-linux-x86_64-8.9.7.29_cuda11-archive

sudo cp ./include/cudnn*.h /usr/local/cuda-11.8/include/
sudo cp ./lib/libcudnn* /usr/local/cuda-11.8/lib64/
sudo chmod a+r /usr/local/cuda-11.8/include/cudnn*.h
sudo chmod a+r /usr/local/cuda-11.8/lib64/libcudnn*
```

### 4. 配置环境变量

写入 `~/.bashrc`：

```bash
export CUDA_HOME=/usr/local/cuda-11.8
export PATH=/usr/local/cuda-11.8/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH
```

```bash
source ~/.bashrc
```

---

## 验证

```bash
# 验证 CUDA
nvcc -V

# 验证驱动
nvidia-smi

# 验证 cuDNN
cat /usr/local/cuda-11.8/include/cudnn_version.h | grep CUDNN_MAJOR -A 2
```
