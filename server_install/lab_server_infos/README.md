# Lab Server Infos

该目录用于存放实验室服务器的硬件记录、安装笔记、故障排查记录，以及采集服务器信息的辅助脚本。

## 文件索引

- `server_lab.md`：服务器资产与配置记录，按机器整理主板、CPU、内存、硬盘、电源等信息。
- `motherboard_notes.md`：主板识别、板级排查、电源兼容性与相关参考资料。
- `ubuntu24_install.md`：Ubuntu 24.04 安装流程、启动设置、分区建议与安装期常见问题。
- `troubleshooting.md`：启动或运行过程中出现的错误记录与解释。
- `collect_server_info.sh`：在 Linux 机器上采集主板、CPU、内存、硬盘信息的脚本。

## 维护约定

- 机器级配置变化统一更新到 `server_lab.md`。
- 主板通用资料、电源适配和板级排查统一更新到 `motherboard_notes.md`。
- 安装系统时只在 `ubuntu24_install.md` 记录安装流程与安装期问题，不重复抄写主板排查内容，改为引用 `motherboard_notes.md`。
- 运行期故障和报错案例统一记录到 `troubleshooting.md`。
