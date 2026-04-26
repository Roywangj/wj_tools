#!/bin/bash
# GPU 掉线 / nvidia-smi 卡死 / "Unknown Error" 诊断脚本
#
# 用法:
#   sudo bash diagnose_gpu.sh              # 通用诊断 + 健康基线
#   sudo bash diagnose_gpu.sh b1:00.0      # 额外输出目标卡的详细链路信息
#
# 输出: ./gpu_diag_<host>_<时间戳>.txt
# 发厂家报修时把这个 txt 一起附上即可。

set -u
PCI_BUS="${1:-}"
TS=$(date +%Y%m%d_%H%M%S)
HOST=$(hostname)
OUT="$(dirname "$0")/gpu_diag_${HOST}_${TS}.txt"

run() {
    local title="$1"; shift
    {
        echo "===== ${title} ====="
        echo "\$ $*"
        eval "$@" 2>&1
        echo
    } >> "$OUT"
}

if [ "$(id -u)" -ne 0 ]; then
    echo "提示: 建议用 sudo 运行,否则 lspci 权限信息和 journalctl 可能不完整"
fi
echo "写入: $OUT"
: > "$OUT"

{
    echo "# GPU 诊断报告"
    echo "时间: $(date)"
    echo "主机: $HOST"
    [ -n "$PCI_BUS" ] && echo "目标 PCI: $PCI_BUS"
    echo
} >> "$OUT"

# ---------- 基本环境 ----------
run "内核版本" "uname -a"
run "驱动版本" "cat /proc/driver/nvidia/version 2>/dev/null || echo '(no nvidia driver loaded)'"
run "已加载的 nvidia 内核模块" "lsmod | grep -i nvidia || echo '(无)'"

# ---------- 当前 GPU 状态 ----------
run "nvidia-smi (5s 超时;卡死说明 GPU 已掉线)" "timeout 5 nvidia-smi; echo '[exit='\$?']'"
run "nvidia-smi topo -m (PCIe 拓扑 + NUMA)" "timeout 5 nvidia-smi topo -m; echo '[exit='\$?']'"

# ---------- PCIe 设备与拓扑 ----------
run "lspci: 所有 NVIDIA 设备 (留意 rev ff = 掉线)" "lspci | grep -i nvidia"
run "lspci -tv (完整 PCIe 树)" "lspci -tv"

# ---------- 所有 NVIDIA GPU 的链路状态对比 ----------
run "每张 NVIDIA GPU 的 LnkCap / LnkSta (对比找出异常卡;需 sudo)" "
for s in \$(lspci -D | awk '/NVIDIA/ && /VGA|3D/ {print \$1}'); do
    echo --- \$s ---;
    sudo lspci -vvv -s \$s 2>/dev/null | grep -E 'LnkCap:|LnkSta:|DevSta:' | head -6;
done"

# ---------- 目标卡详细信息(仅当指定 PCI_BUS)----------
if [ -n "$PCI_BUS" ]; then
    run "目标卡 ${PCI_BUS} 详细链路" "lspci -vvv -s ${PCI_BUS} | grep -iE 'LnkCap|LnkSta|DevSta|Product Name|Kernel driver'"
    run "目标卡是否还在 /sys/bus/pci" "ls /sys/bus/pci/devices/ | grep -i ${PCI_BUS,,} || echo '(PCI 设备已消失!)'"
fi

# ---------- 故障现场证据 ----------
run "本次开机 dmesg: nvidia / nvrm / xid" "dmesg -T 2>/dev/null | grep -iE 'nvidia|nvrm|xid' | tail -80 || echo '(空)'"
run "本次开机 dmesg: PCIe AER / link down" "dmesg -T 2>/dev/null | grep -iE 'pcieport|aer|link down|bus error' | tail -40 || echo '(空)'"
run "卡死在内核态的 GPU 相关进程 (D 状态)" "ps -eo pid,stat,wchan:32,cmd | awk '\$2 ~ /D/' | grep -iE 'nvidia|python|cuda' || echo '(无)'"

# ---------- 历史启动的故障证据(关键:不用复现就能给厂家) ----------
run "历史 boot 列表" "journalctl --list-boots 2>/dev/null | tail -10"
run "上一次开机期间的 nvidia / xid / hung task 日志" "sudo journalctl -b -1 -k 2>/dev/null | grep -iE 'nvidia|nvrm|xid|hung task|pcieport|aer' | tail -120 || echo '(无历史 boot 或未开启持久 journal)'"

echo "完成: $OUT"
echo
echo "--- 关键片段预览 ---"
grep -A1 -iE 'xid|fall|unknown error|link down|aer|rev ff' "$OUT" | head -40
