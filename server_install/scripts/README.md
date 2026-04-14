# server_install/scripts

本目录存放服务器装机与运维过程中使用的辅助脚本，主要覆盖用户初始化、SSH 配置、常用工具安装、校园网登录和死机排查信息收集。

## 脚本说明

| 脚本 | 用途 | 备注 |
|------|------|------|
| `adduser_data_basedrawroot.sh` | 创建系统用户，并将家目录放到 `/data/users/<用户名>` | 需要 `root` 权限；会复制当前目录下的 `.bashrc`、`.profile`、`.zshrc` |
| `install_tools.sh` | 安装常用命令行工具 | 当前会安装 `screen`、`git`、`python3-pip` 和 `nvitop` |
| `setup_ssh_key.sh` | 为当前用户生成 SSH 密钥并把公钥追加到 `authorized_keys` | 适合快速初始化免密登录 |
| `serverlogin.py` | 通过 SRun 门户进行校园网/内网认证登录 | 脚本内默认地址是 `10.0.0.55`，账号密码需要自行修改 |
| `collect_freeze_info.sh` | 收集死机、卡死、重启前后的系统诊断信息 | 输出 `journalctl`、`dmesg`、`sar`、`ps`、`df` 等结果，默认保存到 `/tmp` |

## 使用建议

- 涉及用户、SSH 或系统软件安装的脚本，执行前先确认当前主机和当前用户是否正确
- `collect_freeze_info.sh` 建议在故障复现后尽快执行；如已知故障时间窗，可传入 `SINCE` / `UNTIL`
- `serverlogin.py` 当前写死了示例账号和密码占位，需要按实际环境改成可用凭据
