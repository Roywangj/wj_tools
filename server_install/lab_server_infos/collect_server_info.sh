#!/bin/bash
echo "===== 主板 =====" && sudo dmidecode -t baseboard | grep -E "Manufacturer|Product Name|Serial Number"
echo "===== CPU =====" && lscpu | grep -E "Model name|Socket|CPU\(s\)|Thread|Core"
echo "===== 内存 =====" && sudo dmidecode -t memory | grep -E "Size|Speed|Manufacturer|Part Number" | grep -v "No Module"
echo "===== 硬盘 =====" && lsblk -d -o NAME,SIZE,MODEL,ROTA | grep -v loop
