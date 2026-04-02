# NFS 存储挂载指南

参考教程：<https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-16-04>

---

## 挂载记录

| 存储节点路径           | 本地挂载点 | 服务器     |
|------------------------|------------|------------|
| `10.106.15.88:/datav2` | `/data4`   | 各计算节点 |
| `10.106.15.88:/data`   | `/data3`   | 各计算节点 |

---

## 存储节点（88）：共享新磁盘

新装硬盘（如 `/datav2`）后，在存储节点 `10.106.15.88` 上配置 NFS 共享：

```bash
sudo vim /etc/exports
```

添加：

```text
/datav2 *(rw,sync,no_root_squash,no_subtree_check)
```

重启 NFS 服务：

```bash
sudo systemctl restart nfs-kernel-server
```

---

## 各计算节点：创建挂载点并挂载

### 1. 安装 NFS 客户端

```bash
sudo apt-get install nfs-common
```

### 2. 创建本地目录

```bash
sudo mkdir -p /data3
```

### 3. 立即挂载

```bash
sudo mount 10.106.15.88:/data /data3/
```

### 4. 配置开机自动挂载

```bash
echo '10.106.15.88:/data /data3 nfs defaults 0 0' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
```

> **常见报错**：`mount.nfs: mount point /data3/ does not exist`
> 原因：本地挂载目录未创建，执行 `sudo mkdir -p /data3` 后重试。

---

## 一键全部挂载脚本

将所有 NFS 挂载写入 fstab 后，一条命令全部挂载：

```bash
sudo mount -a
```

或手动全部挂载：

```bash
sudo mkdir -p /data3 /data4
sudo mount 10.106.15.88:/data /data3/
sudo mount 10.106.15.88:/datav2 /data4/
```

写入 fstab（开机自动挂载）：

```bash
echo '10.106.15.88:/data /data3 nfs defaults 0 0' | sudo tee -a /etc/fstab
echo '10.106.15.88:/datav2 /data4 nfs defaults 0 0' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
```

---

## 推荐：按需自动挂载（避免开机卡住）

使用 `noauto,x-systemd.automount`：开机不挂载，访问目录时才自动挂载。
避免存储节点离线时卡住开机（可能卡 90 秒以上）。

```bash
sudo mkdir -p /data3 /data4
echo '10.106.15.88:/data /data3 nfs defaults,noauto,x-systemd.automount 0 0' | sudo tee -a /etc/fstab
echo '10.106.15.88:/datav2 /data4 nfs defaults,noauto,x-systemd.automount 0 0' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
sudo systemctl enable --now data3.automount data4.automount
```

> `daemon-reload` 只是让 systemd 读取新配置，automount unit 仍处于 `inactive` 状态。
> 需要 `enable --now` 才能激活监听（`--now` 等同于同时执行 `start`），并设置开机自启。
> 激活后，首次访问 `/data3` 或 `/data4` 时会自动触发实际挂载。

### fstab NFS 挂载选项说明

| 选项                          | 说明                                     |
|-------------------------------|------------------------------------------|
| `defaults`                    | 默认选项，开机强制挂载                   |
| `noauto,x-systemd.automount` | 开机不挂载，访问目录时才自动挂载（推荐） |
| `_netdev`                     | 等网络就绪后再挂载                       |
| `soft,timeo=5`                | 超时不卡死，0.5 秒后报错返回             |
