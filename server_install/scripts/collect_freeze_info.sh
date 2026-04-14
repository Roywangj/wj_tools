#!/bin/bash

set -u

usage() {
  cat <<'EOF'
Usage:
  collect_freeze_info.sh [SINCE] [UNTIL] [OUTPUT]

Examples:
  ./collect_freeze_info.sh
  ./collect_freeze_info.sh "2026-04-13 21:10:00" "2026-04-13 21:50:00"
  ./collect_freeze_info.sh "2026-04-13 21:10:00" "2026-04-13 21:50:00" /tmp/freeze.log

Notes:
  - If SINCE and UNTIL are provided, current/previous boot journalctl and sar will use that window.
  - Some commands may require sudo/root privileges.
EOF
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

run_cmd() {
  local title="$1"
  shift
  echo "===== ${title} ====="
  "$@" 2>&1 || true
  echo
}

run_bash_cmd() {
  local title="$1"
  local cmd="$2"
  echo "===== ${title} ====="
  bash -lc "$cmd" 2>&1 || true
  echo
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -ne 0 ] && [ "$#" -ne 2 ] && [ "$#" -ne 3 ]; then
  usage
  exit 1
fi

SINCE="${1:-${T1:-}}"
UNTIL="${2:-${T2:-}}"
OUTPUT="${3:-/tmp/$(hostname)-freeze-$(date +%F-%H%M%S).log}"

if { [ -n "$SINCE" ] && [ -z "$UNTIL" ]; } || { [ -z "$SINCE" ] && [ -n "$UNTIL" ]; }; then
  echo "Error: SINCE and UNTIL must be provided together."
  exit 1
fi

SAR_START=""
SAR_END=""
if [ -n "$SINCE" ] && [ -n "$UNTIL" ] && command_exists date; then
  SAR_START="$(date -d "$SINCE" +%T 2>/dev/null || true)"
  SAR_END="$(date -d "$UNTIL" +%T 2>/dev/null || true)"
fi

{
  echo "Output file: $OUTPUT"
  echo "Collected at: $(date)"
  if [ -n "$SINCE" ] && [ -n "$UNTIL" ]; then
    echo "Window: $SINCE -> $UNTIL"
  else
    echo "Window: not provided, collecting recent/current state"
  fi
  echo

  run_cmd "BASIC date" date
  run_cmd "BASIC uptime" uptime
  run_cmd "BASIC w" w
  run_cmd "BASIC who -b" who -b
  run_cmd "BASIC uname -a" uname -a

  if command_exists hostnamectl; then
    run_cmd "BASIC hostnamectl" hostnamectl
  elif [ -f /etc/os-release ]; then
    run_cmd "BASIC os-release" cat /etc/os-release
  fi

  if command_exists timedatectl; then
    run_cmd "BASIC timedatectl" timedatectl
  fi

  if command_exists free; then
    run_cmd "MEM free -h" free -h
  fi
  if command_exists vmstat; then
    run_cmd "MEM vmstat 1 5" vmstat 1 5
  fi
  if command_exists df; then
    run_cmd "DISK df -hT" df -hT
    run_cmd "DISK df -ih" df -ih
  fi
  run_bash_cmd "DISK mount | head -n 50" "mount | head -n 50"

  run_bash_cmd "PROCESS top cpu" \
    "ps -eo pid,ppid,state,%cpu,%mem,comm,args --sort=-%cpu | head -n 40"
  run_bash_cmd "PROCESS D state" \
    "ps -eo pid,ppid,state,wchan:32,comm,args | awk '\$3 ~ /D/ {print}' | head -n 50"

  run_bash_cmd "KERNEL suspicious dmesg" \
    "dmesg -T | egrep -i 'oom|out of memory|killed process|hung task|blocked for more than|soft lockup|hard lockup|I/O error|ext4|xfs|nvme|call trace|segfault' | tail -n 200"

  if command_exists journalctl; then
    if [ -n "$SINCE" ] && [ -n "$UNTIL" ]; then
      run_cmd "JOURNAL kernel window" journalctl -k --since "$SINCE" --until "$UNTIL" --no-pager
      run_cmd "JOURNAL warning..alert window" journalctl --since "$SINCE" --until "$UNTIL" -p warning..alert --no-pager
      run_cmd "PREVIOUS BOOT kernel window" journalctl -b -1 -k --since "$SINCE" --until "$UNTIL" --no-pager
      run_cmd "PREVIOUS BOOT warning..alert window" journalctl -b -1 --since "$SINCE" --until "$UNTIL" -p warning..alert --no-pager
      run_bash_cmd "PREVIOUS BOOT focused grep" \
        "journalctl -b -1 --since \"$SINCE\" --until \"$UNTIL\" --no-pager | grep -Ei 'oom|out of memory|killed process|hung task|blocked for more than|I/O error|nfs|ext4|xfs|call trace|segfault|reset|timeout'"
    else
      run_cmd "JOURNAL kernel recent" journalctl -k -n 200 --no-pager
      run_cmd "JOURNAL warning..alert recent" journalctl -p warning..alert -n 200 --no-pager
      echo "===== PREVIOUS BOOT ====="
      echo "Skipped: provide SINCE and UNTIL to collect previous boot journal windows."
      echo
    fi
  else
    run_bash_cmd "LOG fallback" \
      "grep -Ei 'oom|out of memory|killed process|hung task|blocked for more than|soft lockup|hard lockup|I/O error|segfault' /var/log/messages /var/log/syslog 2>/dev/null | tail -n 200"
    echo "===== PREVIOUS BOOT ====="
    echo "Skipped: journalctl is unavailable."
    echo
  fi

  if command_exists systemctl; then
    run_cmd "SYSTEM failed units" systemctl --failed
  fi

  run_bash_cmd "REBOOT last -x" "last -x | head -n 30"

  if command_exists lsof; then
    run_bash_cmd "STORAGE lsof +D /data" "lsof +D /data 2>/dev/null | head -n 200"
    run_bash_cmd "STORAGE lsof +D /data3" "lsof +D /data3 2>/dev/null | head -n 200"
  else
    echo "===== STORAGE lsof ====="
    echo "Skipped: lsof is unavailable."
    echo
  fi

  if command_exists iostat; then
    run_cmd "EXTRA iostat -xz 1 3" iostat -xz 1 3
  fi
  if command_exists mpstat; then
    run_cmd "EXTRA mpstat -P ALL 1 3" mpstat -P ALL 1 3
  fi
  if command_exists sar; then
    if [ -n "$SAR_START" ] && [ -n "$SAR_END" ]; then
      run_cmd "EXTRA sar window" sar -q -r -u -d -n DEV -s "$SAR_START" -e "$SAR_END"
    else
      echo "===== EXTRA sar ====="
      echo "Skipped: provide SINCE and UNTIL to collect a sar time window."
      echo
    fi
  fi
} | tee "$OUTPUT"

echo "Saved to: $OUTPUT"
