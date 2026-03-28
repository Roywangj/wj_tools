# 硬盘查询、清理与挂载

## 查询硬盘使用情况

### 查看各挂载点磁盘使用率

```bash
df -h
```

### 查看所有磁盘和分区

```bash
sudo fdisk -l
```

### 查看某目录下各子目录占用空间（排序）

```bash
# 查看当前目录下一级子目录大小
du -h --max-depth=1 . | sort -hr

# 查看指定目录
du -h --max-depth=1 /data | sort -hr
```

### 查找大文件

```bash
# 查找超过 10GB 的文件
find / -type f -size +10G 2>/dev/null

# 查找指定目录下超过 1GB 的文件
find /home -type f -size +1G 2>/dev/null -exec ls -lh {} \;
```

---

## 新硬盘初始化流程

### 1. 检测硬盘是否有旧数据

```bash
# 查看磁盘分区情况
sudo fdisk -l /dev/sdb

# 查看文件系统类型（有输出说明有数据）
sudo file -s /dev/sdb
```

### 2. 临时挂载查看内容（确认是否需要备份）

```bash
sudo mkdir /mnt/tmp_check
sudo mount /dev/sdb /mnt/tmp_check
du -h --max-depth=1 /mnt/tmp_check | sort -hr
```

### 3. 卸载并格式化清空

```bash
sudo umount /mnt/tmp_check
sudo mkfs.ext4 /dev/sdb
```

> 执行时会提示 `Proceed anyway? (y,N)`，输入 `y` 确认。

### 4. 挂载到指定路径

```bash
sudo mkdir -p /data
sudo mount /dev/sdb /data
```

### 5. 写入开机自动挂载

```bash
echo '/dev/sdb /data ext4 defaults 0 0' | sudo tee -a /etc/fstab
```

验证：

```bash
df -h /data
```

---

## 清理硬盘空间

### 清理 apt 缓存

```bash
sudo apt clean
sudo apt autoremove -y
```

### 清理 pip 缓存

```bash
pip cache purge
```

### 清理 conda 缓存

```bash
conda clean -a
```

### 清理 Docker（镜像/容器/卷）

```bash
# 清理所有未使用的资源
docker system prune -a

# 只清理停止的容器
docker container prune

# 只清理未使用的镜像
docker image prune -a
```

### 清理日志文件

```bash
# 查看 journal 日志占用
journalctl --disk-usage

# 清理 30 天前的日志
sudo journalctl --vacuum-time=30d

# 限制日志总大小为 1GB
sudo journalctl --vacuum-size=1G
```

### 清理用户 home 目录常见大文件位置

```bash
# 查看 home 目录各用户占用
du -h --max-depth=1 /home | sort -hr

# 常见可清理路径
~/.cache          # 各类应用缓存
~/.local/share    # 本地数据
~/anaconda3/pkgs  # conda 包缓存（可用 conda clean -a 替代）
```
