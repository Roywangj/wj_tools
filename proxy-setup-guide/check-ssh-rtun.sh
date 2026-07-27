#!/usr/bin/env bash
# 检查 Mac -> VM -> Mac 的 SSH 反向隧道、Mac SSH 服务和 atimes 共享状态。
#
# 本脚本只读：不会启动/关闭隧道，也不会修改 SSH 配置。

set -uo pipefail

RTUN_ALIAS="${RTUN_ALIAS:-noban-vm-rtun}"
VM_ALIAS="${VM_ALIAS:-noban-vm-211862-417f08}"
VM_RPORT="${VM_RPORT:-2222}"
MAC_BACK_ALIAS="${MAC_BACK_ALIAS:-mac-via-rtun}"
TIMEOUT="${TIMEOUT:-8}"
SKIP_VM=0

usage() {
    cat <<EOF
用法：
  $(basename "$0")
  $(basename "$0") --rtun noban-vm-rtun --vm noban-vm-211862-417f08 --port 2222
  $(basename "$0") --skip-vm

选项：
  --rtun ALIAS       本机负责 RemoteForward 的 SSH 别名（默认：${RTUN_ALIAS}）
  --vm ALIAS         用于远程检测的 VM SSH 别名（默认：${VM_ALIAS}）
  --port PORT        VM 上的反向监听端口（默认：${VM_RPORT}）
  --mac-alias ALIAS  VM 回连 Mac 使用的别名（默认：${MAC_BACK_ALIAS}）
  --timeout SEC      SSH/nc 超时秒数（默认：${TIMEOUT}）
  --skip-vm          只检查 Mac 本机，不连接 VM
  -h, --help         显示帮助
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rtun) RTUN_ALIAS="${2:-}"; shift 2 ;;
        --vm) VM_ALIAS="${2:-}"; shift 2 ;;
        --port) VM_RPORT="${2:-}"; shift 2 ;;
        --mac-alias) MAC_BACK_ALIAS="${2:-}"; shift 2 ;;
        --timeout) TIMEOUT="${2:-}"; shift 2 ;;
        --skip-vm) SKIP_VM=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "未知选项：$1" >&2; usage >&2; exit 2 ;;
    esac
done

have() { command -v "$1" >/dev/null 2>&1; }
hr() { printf '%s\n' '============================================================'; }
sec() { printf '\n%s\n' "---- $* ----"; }
ok() { printf '  [正常] %s\n' "$*"; }
warn() { printf '  [注意] %s\n' "$*"; }
bad() { printf '  [失败] %s\n' "$*"; }
info() { printf '  [信息] %s\n' "$*"; }

run_ssh_vm() {
    ssh -o BatchMode=yes -o ConnectTimeout="${TIMEOUT}" "${VM_ALIAS}" "$@"
}

# 三态值：yes / no / unknown。
RTUN_PROCESS=no
FORWARD_CONFIGURED=unknown
MAC_SSHD_LOCAL=unknown
MAC_SSHD_NETWORK=no
MAC_SSHD_NETWORK_IPS=""
VM_REACHABLE=unknown
VM_LISTENER=unknown
VM_MAC_LOGIN=unknown
ATIMES_MOUNTED=unknown
ATIMES_LINES=""

TMP_OUT="$(mktemp -t check-ssh-rtun.out.XXXXXX)" || exit 1
TMP_ERR="$(mktemp -t check-ssh-rtun.err.XXXXXX)" || {
    rm -f "${TMP_OUT}"
    exit 1
}
trap 'rm -f "${TMP_OUT}" "${TMP_ERR}"' EXIT INT TERM

hr
echo "SSH 反向隧道安全检测"
echo "检测时间：$(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "反向隧道别名：${RTUN_ALIAS}"
echo "VM 别名：${VM_ALIAS}"
echo "VM 反向端口：${VM_RPORT}"
echo "VM 回连 Mac 别名：${MAC_BACK_ALIAS}"
hr

sec "1. Mac 本地反向隧道进程"
rtun_processes="$(pgrep -lf "ssh.*${RTUN_ALIAS}|autossh.*${RTUN_ALIAS}" 2>/dev/null || true)"
if [[ -n "${rtun_processes}" ]]; then
    RTUN_PROCESS=yes
    ok "发现 ${RTUN_ALIAS} 隧道进程："
    printf '%s\n' "${rtun_processes}" | sed 's/^/    /'
else
    warn "未发现 ${RTUN_ALIAS} / autossh 进程。"
fi

sec "2. 本地 SSH 别名的转发配置"
if ssh_g="$(ssh -G "${RTUN_ALIAS}" 2>/dev/null)"; then
    printf '%s\n' "${ssh_g}" | awk '
        /^(hostname|port|user|identityfile|remoteforward|localforward|dynamicforward|exitonforwardfailure|serveraliveinterval|serveralivecountmax) / { print "    " $0 }
    '
    if printf '%s\n' "${ssh_g}" | grep -q '^remoteforward '; then
        FORWARD_CONFIGURED=yes
        ok "${RTUN_ALIAS} 已配置 RemoteForward。"
    else
        FORWARD_CONFIGURED=no
        warn "${RTUN_ALIAS} 没有配置 RemoteForward。"
    fi
else
    bad "无法展开 ${RTUN_ALIAS} 的 SSH 配置。"
fi

sec "3. Mac 本地 SSH 监听端口"
if have lsof; then
    listen_lines="$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | grep -E 'ssh|autossh' || true)"
    if [[ -n "${listen_lines}" ]]; then
        printf '%s\n' "${listen_lines}" | sed 's/^/    /'
    else
        info "没有发现 ssh/autossh 创建的本地监听端口。"
    fi
    info "RemoteForward 的 ${VM_RPORT} 监听在 VM 上，因此通常不会出现在本节。"
else
    warn "未找到 lsof，跳过本地监听检查。"
fi

sec "4. Mac 当前已建立的 SSH 连接"
if have lsof; then
    established_lines="$(lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null | grep -E 'ssh|autossh|relay-ctrl|157\.230\.46\.220|:10041|:22' || true)"
    if [[ -n "${established_lines}" ]]; then
        printf '%s\n' "${established_lines}" | sed 's/^/    /'
    else
        info "没有发现匹配的 SSH TCP 连接。"
    fi
else
    warn "未找到 lsof，跳过已建立连接检查。"
fi

sec "5. Mac 的 SSH 服务可达性"
if have nc; then
    if nc -vz -w "${TIMEOUT}" 127.0.0.1 22 >/dev/null 2>&1; then
        MAC_SSHD_LOCAL=yes
        ok "127.0.0.1:22 可达，Mac 的远程登录/sshd 已启动。"
    else
        MAC_SSHD_LOCAL=no
        warn "127.0.0.1:22 不可达，Mac 的远程登录/sshd 可能未启动。"
    fi

    if have ifconfig; then
        ips="$(ifconfig 2>/dev/null | awk '/inet / && $2 != "127.0.0.1" {print $2}' | sort -u)"
        if [[ -n "${ips}" ]]; then
            while IFS= read -r ip; do
                [[ -z "${ip}" ]] && continue
                if nc -vz -w 2 "${ip}" 22 >/dev/null 2>&1; then
                    MAC_SSHD_NETWORK=yes
                    MAC_SSHD_NETWORK_IPS="${MAC_SSHD_NETWORK_IPS}${MAC_SSHD_NETWORK_IPS:+, }${ip}:22"
                    ok "${ip}:22 可达。"
                else
                    info "${ip}:22 不可达。"
                fi
            done <<< "${ips}"
        fi
    fi
else
    warn "未找到 nc，无法检查 Mac sshd 的可达性。"
fi

if [[ "${SKIP_VM}" -eq 0 ]]; then
    sec "6. VM 上的反向端口监听"
    if vm_listener="$(run_ssh_vm "ss -tlnp | grep -E ':${VM_RPORT}\\b' || true" 2>/dev/null)"; then
        VM_REACHABLE=yes
        if [[ -n "${vm_listener}" ]]; then
            VM_LISTENER=yes
            ok "VM 的 ${VM_RPORT} 端口正在监听："
            printf '%s\n' "${vm_listener}" | sed 's/^/    /'
        else
            VM_LISTENER=no
            warn "VM 没有监听 ${VM_RPORT} 端口，反向隧道未开放。"
        fi
    else
        VM_REACHABLE=no
        bad "无法通过 ${VM_ALIAS} 登录 VM，不能确认 VM 端口状态。"
    fi

    sec "7. VM 回连 Mac 实测"
    if [[ "${VM_REACHABLE}" == yes ]]; then
        vm_alias_config="$(run_ssh_vm "ssh -G ${MAC_BACK_ALIAS} 2>/dev/null | grep -E '^(host|hostname|port|user|identityfile|identitiesonly|serveraliveinterval|serveralivecountmax) ' || true" 2>/dev/null || true)"
        if [[ -n "${vm_alias_config}" ]]; then
            printf '%s\n' "${vm_alias_config}" | sed 's/^/    /'
        else
            warn "VM 上的 ${MAC_BACK_ALIAS} 别名不存在或无法展开。"
        fi

        : >"${TMP_OUT}"
        : >"${TMP_ERR}"
        if run_ssh_vm "ssh -o BatchMode=yes -o ConnectTimeout=${TIMEOUT} ${MAC_BACK_ALIAS} 'hostname; whoami'" >"${TMP_OUT}" 2>"${TMP_ERR}"; then
            VM_MAC_LOGIN=yes
            ok "VM 可以通过 ${MAC_BACK_ALIAS} 登录这台 Mac："
            sed 's/^/    /' "${TMP_OUT}"
        else
            VM_MAC_LOGIN=no
            warn "VM 当前不能通过 ${MAC_BACK_ALIAS} 登录这台 Mac。"
            if [[ -s "${TMP_ERR}" ]]; then
                sed 's/^/    /' "${TMP_ERR}"
            fi
        fi
    else
        warn "由于 VM 不可达，跳过回连实测。"
    fi

    sec "8. VM 上的 atimes 文件共享"
    if [[ "${VM_REACHABLE}" == yes ]]; then
        if ATIMES_LINES="$(run_ssh_vm "grep fuse.atimes /proc/mounts || true" 2>/dev/null)"; then
            if [[ -n "${ATIMES_LINES}" ]]; then
                ATIMES_MOUNTED=yes
                warn "VM 当前存在 atimes FUSE 挂载："
                printf '%s\n' "${ATIMES_LINES}" | sed 's/^/    /'
            else
                ATIMES_MOUNTED=no
                ok "VM 当前没有 fuse.atimes 挂载。"
            fi
        else
            warn "无法检查 VM 上的 atimes 挂载。"
        fi
    else
        warn "由于 VM 不可达，无法检查 atimes 挂载。"
    fi
else
    sec "6-8. VM 远程检查"
    warn "已使用 --skip-vm，未连接 VM；VM 监听、回连和 atimes 状态均未知。"
fi

sec "最终检测结果"

if [[ "${VM_MAC_LOGIN}" == yes ]]; then
    warn "反向 SSH：已开放并实测可用。VM 可以通过 ${MAC_BACK_ALIAS} 登录这台 Mac。"
elif [[ "${VM_LISTENER}" == yes ]]; then
    warn "反向 SSH：VM 的 ${VM_RPORT} 端口已开放，但回连登录失败；端口存在，登录凭据或 Mac sshd 需要检查。"
elif [[ "${VM_LISTENER}" == no ]]; then
    ok "反向 SSH：已关闭。VM 没有监听 ${VM_RPORT}，不能通过 ${MAC_BACK_ALIAS} 回连 Mac。"
elif [[ "${RTUN_PROCESS}" == no ]]; then
    info "反向 SSH：本机未发现隧道进程，但 VM 状态未知，暂时只能判断为很可能已关闭。"
else
    info "反向 SSH：无法确认，请在能够连接 VM 后重新检测。"
fi

if [[ "${MAC_SSHD_NETWORK}" == yes ]]; then
    warn "Mac 直接 SSH：以下本机网络地址的 22 端口可达：${MAC_SSHD_NETWORK_IPS}。能到达这些网络且持有有效凭据的设备可以尝试登录。"
elif [[ "${MAC_SSHD_LOCAL}" == yes ]]; then
    ok "Mac 直接 SSH：sshd 已启动，但本次未发现非回环地址的 22 端口可达。"
elif [[ "${MAC_SSHD_LOCAL}" == no ]]; then
    ok "Mac 直接 SSH：本机 22 端口不可达，远程登录可能已关闭。"
else
    info "Mac 直接 SSH：未能检测。"
fi

if [[ "${ATIMES_MOUNTED}" == yes ]]; then
    warn "atimes 文件共享：已开放。VM 可以访问上面列出的共享目录；带 rw 的挂载可读写，但这不等同于 SSH 登录整台 Mac。"
elif [[ "${ATIMES_MOUNTED}" == no ]]; then
    ok "atimes 文件共享：VM 当前没有可见的 atimes 挂载。"
else
    info "atimes 文件共享：状态未知。"
fi

printf '\n'
if [[ "${VM_MAC_LOGIN}" == yes ]]; then
    printf '  结论：VM 当前可以通过反向隧道 SSH 进入这台 Mac。\n'
elif [[ "${VM_LISTENER}" == no ]]; then
    printf '  结论：VM 当前不能通过这条反向 SSH 隧道进入 Mac。\n'
else
    printf '  结论：反向 SSH 是否可进入 Mac 尚未完全确认。\n'
fi

if [[ "${MAC_SSHD_NETWORK}" == yes ]]; then
    printf '  补充：反向隧道状态不影响 Mac 自身的 22 端口；局域网/VPN 中能到达上述地址的设备仍可凭有效凭据尝试 SSH。\n'
fi
if [[ "${ATIMES_MOUNTED}" == yes ]]; then
    printf '  补充：VM 当前还能通过 atimes 访问已共享的文件夹。\n'
fi
hr
