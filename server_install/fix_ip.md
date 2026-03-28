# 固定 IP 配置（Ubuntu 24.04）

## 查看当前网络信息

```bash
ip a          # 查看网卡名和当前 IP
ip route      # 查看网关
```

## 使用 Netplan 固定 IP

Ubuntu 18.04+ 使用 Netplan 管理网络，配置文件在 `/etc/netplan/`。

### 1. 查看现有配置文件

```bash
ls /etc/netplan/
```

### 2. 编辑配置文件

```bash
sudo vim /etc/netplan/01-netcfg.yaml
```

写入以下内容（根据实际情况修改）：

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eno1:                          # 网卡名，用 ip a 确认
      dhcp4: no
      addresses:
        - 10.106.1.140/23          # 固定 IP/子网掩码
      routes:
        - to: default
          via: 10.106.0.1          # 网关，用 ip route 确认
      nameservers:
        addresses:
          - 8.8.8.8
          - 114.114.114.114
```

### 3. 应用配置

```bash
sudo netplan apply
```

### 4. 验证

```bash
ip a
ping baidu.com
```

---

## 本机信息（3090server）

| 项目 | 值 |
|------|----|
| 网卡 | `eno1` |
| MAC  | `3c:ec:ef:28:33:e0` |
| IP   | `10.106.1.140/23` |
| 网关 | `10.106.0.1` |
| 现有配置文件 | `/etc/netplan/01-network-manager-all.yaml`, `50-cloud-init.yaml` |
