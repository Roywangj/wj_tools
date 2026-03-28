# GPU Burn 安装指南

项目地址：<https://github.com/wilicc/gpu-burn>

## 安装

```bash
unzip gpu-burn-master.zip
cd gpu-burn-master
make
```

编译成功后会生成 `gpu_burn` 可执行文件。

## 错误：cublas_v2.h: No such file or directory

编译需要 CUDA Toolkit，系统未安装或 Makefile 未找到 CUDA 路径。

### 解决方案

#### 1. 确认 CUDA 已安装并配置环境变量

```bash
nvcc --version
```

若已安装 CUDA 11.8，确保 `~/.bashrc` 中有：

```bash
export CUDA_HOME=/usr/local/cuda-11.8
export PATH=/usr/local/cuda-11.8/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH
```

#### 2. 如路径未识别，查找 cublas_v2.h 位置

```bash
find / -name "cublas_v2.h" 2>/dev/null
```

#### 3. 修改 Makefile 指定 CUDA 路径

```bash
vim Makefile
# 找到 CUDA_PATH ?= /usr/local/cuda，确认路径正确
```

#### 4. 重新编译

```bash
make clean
make
```

---

## 运行 GPU Burn

> 注意：必须加 `./` 前缀运行，直接输 `gpu_burn` 会报 `command not found`

```bash
# 烤机 60 秒
./gpu_burn 60

# 烤机 1 小时（3600 秒）
./gpu_burn 3600

# 双精度模式（压力更大）
./gpu_burn -d 3600
```

输出示例中会显示每张 GPU 的 Gflop/s 和温度，`OK` 表示通过，`FAULTY` 表示出现计算错误。
