# GPU 掉线诊断笔记(nvidia-smi 卡死 / Unknown Error)

针对 197 八卡 3090 服务器,`nvidia-smi` 卡死 + `Unable to determine the device handle for GPU0000:B1:00.0: Unknown Error` 这一类故障的排查记录。

配套脚本:[`diagnose_gpu.sh`](./diagnose_gpu.sh)

---

## 1. 症状速查

| 症状 | 指向 |
|---|---|
| `nvidia-smi` 报 `Unable to determine the device handle ... Unknown Error` | GPU 从 PCIe 总线掉线(fall off the bus) |
| `nvidia-smi` 直接卡死(无输出也不退出) | 驱动卡在等已掉线的 GPU 响应,相关进程进入 `D` 状态 |
| `lspci` 里目标卡显示 `(rev ff)` | **铁证**:PCIe 配置空间全 `0xFF`,卡已完全无应答 |
| `lspci` 里目标卡直接消失 | 更严重,卡从总线上摘了,基本只能冷重启 |
| `dmesg` 里有 `NVRM: Xid (PCI:...): 79` | 经典 Xid 79 = GPU fall off the bus |
| `dmesg` 里大量 `uvm_gpu_retain_by_uuid` / `uvm_api_register_gpu` 调用栈 | 用户进程 ioctl 被挂死在内核态(hung task) |

---

## 2. 当前情况分析(nvidia-smi 卡死时的典型表现)

这是 **Xid 79 / GPU fall off the bus** 的典型表现:

- GPU 已从 PCIe 掉线,驱动仍在等它响应 → `nvidia-smi` 永远阻塞
- 被卡的进程进入 `D`(不可中断睡眠)状态,`kill -9` 也杀不掉
- 再开 `nvidia-smi` 只会继续堆积 D 状态进程

### 正确的操作顺序(以 197 为例)

1. **不要再反复敲 `nvidia-smi`**,会越堆越多 D 进程。

2. 换一个**不依赖 nvidia 驱动**的终端(新 ssh 窗口),先把硬证据留下:

   ```bash
   sudo dmesg -T | grep -iE 'nvidia|nvrm|xid|pcieport|aer' | tail -100 > ~/gpu_xid.log
   lspci | grep -i nvidia                      # 看卡还在不在 PCI 上
   ls /sys/bus/pci/devices/ | grep -i b1:00.0  # /sys 下节点是否还在
   ```

   - 如果 `lspci` 里**还能看到**这张卡 → 软件层挂了,`reboot` 基本能救
   - 如果 `lspci` 里**已经看不到** → 卡从总线上完全消失,通常**必须冷重启**(关机拔电等 30s),热 reboot 不一定恢复

3. 尝试软恢复(99% 不会成,但代价低):

   ```bash
   sudo rmmod nvidia_uvm nvidia_drm nvidia_modeset nvidia
   ```

   一旦 rmmod 卡住(被 D 状态进程持有模块) → 直接重启。

4. `sudo reboot`;如果 reboot 也卡 → `sudo reboot -f` 或按机箱电源强关。

5. 开机后立刻跑 `diagnose_gpu.sh`,**按 Xid 编号判下一步**是修软件还是排硬件(参考 §8)。

---

## 3. 诊断操作流程

### Step 1 — **不要再敲 `nvidia-smi`**
每敲一次都会多产生一个 `D` 状态僵尸进程(不可中断睡眠),`kill -9` 也杀不掉,只会把系统越拖越死。

### Step 2 — 在新终端收集证据(不依赖 nvidia 驱动)

```bash
# dmesg 里的 Xid / NVRM / PCIe 错误
sudo dmesg -T | grep -iE 'nvidia|nvrm|xid|pcieport|aer' | tail -100

# lspci 看卡还在不在、rev 号正不正常
lspci | grep -i nvidia

# 指定卡的详细链路状态
sudo lspci -vvv -s b1:00.0 | grep -iE 'LnkSta|LnkCap|DevSta|Kernel driver'

# /sys 下 PCI 设备节点是否还存在
ls /sys/bus/pci/devices/ | grep -i b1:00.0
```

或者直接跑:

```bash
sudo bash diagnose_gpu.sh b1:00.0
```

### Step 3 — 根据结果判断

- `lspci` 看到 **`rev a1` 正常** + 只是 `nvidia-smi` 报错 → 驱动层软问题,尝试 rmmod/重启
- `lspci` 看到 **`rev ff`** → 卡电气上还在但已死,`rmmod` 99% 会卡住(被 D 进程持有),**必须重启**
- `lspci` **根本看不到这张卡** → 卡从总线掉了,**必须冷启动**(断电 30s),热 reboot 经常无效

---

## 4. 恢复手段(按侵入性从低到高)

### 3.1 软恢复(代价低,基本无效但可以试一次)
```bash
sudo rmmod nvidia_uvm nvidia_drm nvidia_modeset nvidia
sudo modprobe nvidia
nvidia-smi
```
> 一旦已经出现 `rev ff` 或 D 状态进程,rmmod 必卡 —— 直接进 3.2。

### 3.2 热重启
```bash
sudo reboot
# 如果卡在 systemd 等 D 进程:
sudo reboot -f
```

### 3.3 冷启动(关键!)
`rev ff` 状态经常能扛过热重启,但扛不过物理断电:

1. 彻底关机:`sudo shutdown -h now`(或长按电源键强关)
2. **拔掉电源线,等 30 秒以上**(让 PCIe 电路彻底放电)
3. 接回电源开机
4. 开机后立即:
   ```bash
   lspci | grep -i nvidia   # 看 rev 号是否全部恢复成 rev a1
   ```

---

## 5. 已发生的一次实例(2026-04-17,197 机)

### 现象
- `nvidia-smi` 卡死
- `lspci | grep -i nvidia` 输出:
  ```
  b1:00.0 ... RTX 3090 (rev ff)    ← 挂了
  b1:00.1 ... Audio     (rev ff)   ← 挂了
  b2:00.0 ... RTX 3090 (rev ff)    ← 挂了
  b2:00.1 ... Audio     (rev ff)   ← 挂了
  其余 6 张 (3d/3e/40/41/b4/b5) 都是 rev a1,正常
  ```
- `dmesg` 刷屏 `uvm_gpu_retain_by_uuid` / `uvm_api_register_gpu` hung task 调用栈
- 卡温度正常,刚启动训练就挂

### 诊断要点
- **两张相邻卡同时挂**(b1 和 b2),这种分布不是随机软件 bug
- b1/b2 很可能挂在**同一个 PCIe switch / 同一路 12V 供电**
- 指向 **硬件/供电** 而非驱动或软件

### 处理
1. 不再敲 `nvidia-smi`
2. `sudo reboot -f`(普通 reboot 卡住)
3. 冷启动(断电 30s)
4. 开机后确认 `rev ff` → `rev a1`

---

## 6. 根因排查顺序(2 张以上同时掉 / 反复掉线)

按概率排序:

### 5.1 供电(最可能)
8 张 3090 满载约 2800W+,瞬时峰值更高。相邻卡共用供电时最先暴露。

检查:
- 对应卡的 **PCIe 6+2pin 供电线** 是否松动,尤其是:
  - 矿渣一拖二 / 一拖三线材
  - 转接线接头
- 如果是**双电源冗余**,看掉线的卡是不是都挂在同一个副电源
- 电源总功率是否足够(建议 ≥ 3000W 且留 20% 余量)

验证手段:
```bash
sudo nvidia-smi -pm 1
sudo nvidia-smi -i <idx> -pl 300    # 给怀疑的卡锁 300W 跑一段
```
能稳 → 基本确认供电边缘问题。

### 5.2 PCIe riser / 延长线
8 卡机基本都用 riser 或转接背板,相邻卡常走同一根延长线或同一张转接板。

验证:
- 把掉线卡和其他槽上的卡**对调位置**(例如 b1 ↔ b4)
- 如果故障**跟着卡走** → 卡本身问题
- 如果故障**跟着槽走** → 主板槽 / riser / 供电线问题

### 5.3 BIOS / 内核
- 最近是否 `apt upgrade` 过内核 → 检查 nvidia 驱动是否对新内核重新编译了(`dkms status`)
- BIOS 中 **Above 4G Decoding**、**Resizable BAR**、**PCIe ASPM** 设置是否被动过

### 5.4 卡本身
2 张同时挂的概率低,除非长期供电不稳把相邻卡一起冲坏。放最后考虑。

---

## 7. 拆机排查的正确顺序(关机后该不该先拔卡)

**结论:不要急着拆卡。** 先冷启动、再空载验证、再查线、最后才动卡和槽位。
拆卡会丢掉关键诊断信息,而且重新插拔本身可能"碰巧好了",反而把真正的供电/槽位问题盖住。

### 7.1 第一步:带全部卡冷启动(必做)

关键看 `rev ff` 在冷启动后会不会消失:

```bash
# 关机 → 拔电源等 30s → 开机 → 立刻
lspci | grep -i nvidia
```

- **全变回 `rev a1`** → 卡和槽位电气上都没坏,问题在**运行时**(供电瞬时跌 / 驱动 bug),进入 7.2
- **b1/b2 还是 `rev ff`** → 卡或槽位电气层就异常,跳到 7.3

### 7.2 第二步:带卡空转 + 渐进加压

冷启动恢复后,**不要立刻跑训练**,按下面逐级加压:

```bash
sudo nvidia-smi -pm 1
watch -n 5 'nvidia-smi --query-gpu=index,name,temperature.gpu,power.draw,pstate --format=csv'
```

加压顺序:

1. 空载持续 30 分钟
2. **单卡**轻量负载(只用 b1):
   ```bash
   CUDA_VISIBLE_DEVICES=4 python -c "import torch; x=torch.randn(10000,10000,device='cuda'); [x@x for _ in range(100)]"
   ```
3. b1 + b2 双卡同时跑
4. 8 卡满载

哪一步开始掉就指向那一步对应的瓶颈:
- 单卡掉 → **卡本身**
- 双卡 b1+b2 掉 → **共用供电 / 同 PCIe switch**
- 8 卡满载才掉 → **总功率不够**

### 7.3 第三步:开始动手(只在 7.1 / 7.2 暴露问题后)

侵入性从低到高,**一步一停,每步都重新冷启动测**:

#### 1. 先只检查供电线(不拔卡)
- 关机断电 → 开侧板
- 重点检查 b1 / b2 的 **6+2pin 供电接头**:松动、烧焦、变色、风干胶脱落
- 看这两张卡的供电线是不是来自**同一路**(同一条一拖二 / 同一个电源模块)
- 发现问题 → 换线后回 7.1 重测,**先别动卡**

#### 2. 交换供电线(还是不拔卡)
- 把 b1/b2 的供电线和 b4/b5 的对调
- 冷启动测
- 故障**跟着线走** → 线 / 电源模块问题
- 故障**还在 b1/b2** → 排除供电线,继续

#### 3. 最后才拔卡 / 换槽
- 把 b1 上的卡和 b4 上的卡**对调插槽**(连同供电线一起换)
- 冷启动测
- 故障**跟着卡走**(原 b1 卡现在在 b4 出问题) → **卡坏**
- 故障**跟着槽走**(b1 槽换了卡还是坏) → **主板槽 / riser / 背板供电** 坏

### 7.4 为什么不建议直接拆卡

| 直接拆卡的坏处 | 后果 |
|---|---|
| 可能"插回去就好了" | 假象,3 天后又掉,白折腾 |
| 丢失 `rev ff` 复现条件 | 没法做严谨对比,无法定位 |
| 8 卡机布线复杂,拆装风险高 | 静电、连带松动其他卡的供电、刮伤 PCB |
| 拔下来在别的机器测也未必复现 | 问题可能是**这台机器的供电**,不是卡 |

### 7.5 一句话流程

**冷启动 → 空载验证 → 渐进加压 → 查线 → 换线 → 最后才换槽换卡。**
每一步都是为了**不破坏现场**地缩小嫌疑范围。

---

## 8. 预防措施

```bash
# 持久模式(减少驱动反复初始化带来的尖峰)
sudo nvidia-smi -pm 1

# 长期降功耗墙(牺牲 5-10% 性能换稳定性)
sudo nvidia-smi -pl 300    # 3090 默认 350W

# 开启 ECC 日志留痕(如果卡支持)
sudo nvidia-smi -e 1
```

如需开机自动执行,写入 `/etc/rc.local` 或 systemd service。

---

## 9. Xid 编号速查

| Xid | 含义 | 处理方向 |
|---|---|---|
| 13 | Graphics Engine Exception | 应用层 bug,单次偶发可忽略 |
| 31 | MMU fault | 通常是 CUDA 程序非法访存,app 问题 |
| 43 | Reset channel verif error | 驱动层,可能需重启 |
| 48 | Double bit ECC error | 显存坏,换卡 |
| 63 / 64 | ECC page retirement | 显存有坏块在隔离 |
| **79** | **GPU has fallen off the bus** | **本文主角,硬件/供电优先** |
| 119 | GSP RPC timeout | 驱动/固件问题,升级驱动 |

完整列表参考 NVIDIA 官方 [Xid Errors 文档](https://docs.nvidia.com/deploy/xid-errors/index.html)。
