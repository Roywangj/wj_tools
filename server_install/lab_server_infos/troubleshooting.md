# 故障排查记录

## 启动报错：197 号机器

```text
/dev/sda6: recovering journal
/dev/sda6: clean, 289000/27303936 files, 22978990/109212416 blocks
[   54.083220] proc: Bad value for 'hidepid'
[   58.582341] usb 1-2-port1: Cannot reset (err = -71)
```

### 各行含义

1. `/dev/sda6: recovering journal`
   - 文件系统（ext4）在上次未正常关机后，正在执行日志恢复。属于正常的自动修复行为，不是错误。

2. `/dev/sda6: clean, 289000/27303936 files, 22978990/109212416 blocks`
   - 日志恢复完成，文件系统检查通过，状态正常（clean）。无需处理。

3. `[   54.083220] proc: Bad value for 'hidepid'`
   - `/proc` 挂载时 `hidepid` 参数值不合法。
   - 常见原因：`/etc/fstab` 或 `systemd` 挂载配置中使用了旧版语法（如 `hidepid=2`），新内核（5.8+）改为 `hidepid=invisible` 等字符串格式。
   - 影响：`hidepid` 配置未生效，其他功能不受影响，但可能有安全隐患（其他用户可见进程列表）。
   - **修复**：检查 `/etc/fstab` 中 `proc` 行的 `hidepid` 值，改为新格式或移除。

4. `[   58.582341] usb 1-2-port1: Cannot reset (err = -71)`
   - USB 端口复位失败，错误码 `-71` 对应 `EPROTO`（协议错误）。
   - 常见原因：USB 设备连接不稳定、设备损坏、或驱动兼容性问题。
   - 影响：对应 USB 设备可能无法正常工作。
   - **排查**：用 `lsusb` 查看设备，检查线缆/设备是否正常，或尝试换端口。
