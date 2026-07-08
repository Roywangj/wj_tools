#!/usr/bin/env bash
# Check local SSH reverse tunnel status for Mac -> VM -> Mac access.
#
# Default target:
#   Mac tunnel alias: noban-vm-rtun
#   VM alias:         noban-vm-211862-417f08
#   VM remote port:   2222
#   VM Mac alias:     mac-via-rtun
#
# This script is read-only: it does not start/stop tunnels or modify SSH config.

set -uo pipefail

RTUN_ALIAS="${RTUN_ALIAS:-noban-vm-rtun}"
VM_ALIAS="${VM_ALIAS:-noban-vm-211862-417f08}"
VM_RPORT="${VM_RPORT:-2222}"
MAC_BACK_ALIAS="${MAC_BACK_ALIAS:-mac-via-rtun}"
TIMEOUT="${TIMEOUT:-8}"
SKIP_VM=0

usage() {
    sed -n '1,36p' "$0" | sed 's/^# \{0,1\}//'
    cat <<EOF

Usage:
  $(basename "$0")
  $(basename "$0") --rtun noban-vm-rtun --vm noban-vm-211862-417f08 --port 2222
  $(basename "$0") --skip-vm

Options:
  --rtun ALIAS       Local SSH alias that owns RemoteForward. Default: ${RTUN_ALIAS}
  --vm ALIAS         VM SSH alias used for remote checks. Default: ${VM_ALIAS}
  --port PORT        RemoteForward listen port on VM. Default: ${VM_RPORT}
  --mac-alias ALIAS  Alias on VM for returning to Mac. Default: ${MAC_BACK_ALIAS}
  --timeout SEC      SSH/nc timeout. Default: ${TIMEOUT}
  --skip-vm          Only run local checks.
  -h, --help         Show this help.
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
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

have() { command -v "$1" >/dev/null 2>&1; }
hr() { printf '%s\n' '============================================================'; }
sec() { printf '\n%s\n' "---- $* ----"; }
ok() { printf '  [OK] %s\n' "$*"; }
warn() { printf '  [WARN] %s\n' "$*"; }
bad() { printf '  [BAD] %s\n' "$*"; }
info() { printf '  [INFO] %s\n' "$*"; }

run_ssh_vm() {
    ssh -o BatchMode=yes -o ConnectTimeout="${TIMEOUT}" "${VM_ALIAS}" "$@"
}

hr
echo "SSH reverse tunnel check"
echo "Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "RTUN_ALIAS=${RTUN_ALIAS}"
echo "VM_ALIAS=${VM_ALIAS}"
echo "VM_RPORT=${VM_RPORT}"
echo "MAC_BACK_ALIAS=${MAC_BACK_ALIAS}"
hr

sec "1. Local tunnel process"
rtun_processes="$(pgrep -lf "ssh.*${RTUN_ALIAS}|autossh.*${RTUN_ALIAS}" 2>/dev/null || true)"
if [[ -n "${rtun_processes}" ]]; then
    ok "Found ${RTUN_ALIAS} process:"
    printf '%s\n' "${rtun_processes}" | sed 's/^/    /'
else
    warn "No ${RTUN_ALIAS} / autossh process found. Reverse tunnel is likely closed."
fi

sec "2. SSH forwarding configured on local alias"
if ssh_g="$(ssh -G "${RTUN_ALIAS}" 2>/dev/null)"; then
    printf '%s\n' "${ssh_g}" | awk '
        /^(hostname|port|user|identityfile|remoteforward|localforward|dynamicforward|exitonforwardfailure|serveraliveinterval|serveralivecountmax) / { print "    " $0 }
    '
    if printf '%s\n' "${ssh_g}" | grep -q '^remoteforward '; then
        ok "RemoteForward is present in ${RTUN_ALIAS}."
    else
        warn "No RemoteForward found in ${RTUN_ALIAS}."
    fi
else
    bad "Cannot expand SSH config for ${RTUN_ALIAS}."
fi

sec "3. Local listening SSH tunnel ports"
if have lsof; then
    listen_lines="$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | grep -E 'ssh|autossh' || true)"
    if [[ -n "${listen_lines}" ]]; then
        printf '%s\n' "${listen_lines}" | sed 's/^/    /'
    else
        info "No local ssh/autossh LISTEN sockets found."
    fi
    info "For RemoteForward, the LISTEN port is on the VM, not on this Mac."
else
    warn "lsof not found; skipped local LISTEN check."
fi

sec "4. Established SSH connections from this Mac"
if have lsof; then
    established_lines="$(lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null | grep -E 'ssh|autossh|relay-ctrl|157\.230\.46\.220|:10041|:22' || true)"
    if [[ -n "${established_lines}" ]]; then
        printf '%s\n' "${established_lines}" | sed 's/^/    /'
    else
        info "No matching established SSH TCP connections found."
    fi
else
    warn "lsof not found; skipped established connection check."
fi

sec "5. Mac sshd reachability"
if have nc; then
    if nc -vz -w "${TIMEOUT}" 127.0.0.1 22 >/dev/null 2>&1; then
        ok "127.0.0.1:22 is reachable. Mac Remote Login/sshd is available locally."
    else
        warn "127.0.0.1:22 is not reachable. Mac Remote Login/sshd may be off."
    fi

    if have ifconfig; then
        ips="$(ifconfig 2>/dev/null | awk '/inet / && $2 != "127.0.0.1" {print $2}' | sort -u)"
        if [[ -n "${ips}" ]]; then
            while IFS= read -r ip; do
                [[ -z "${ip}" ]] && continue
                if nc -vz -w 2 "${ip}" 22 >/dev/null 2>&1; then
                    ok "${ip}:22 is reachable on this Mac."
                else
                    info "${ip}:22 is not reachable."
                fi
            done <<< "${ips}"
        fi
    fi
else
    warn "nc not found; skipped Mac sshd reachability check."
fi

if [[ "${SKIP_VM}" -eq 1 ]]; then
    sec "6. VM checks"
    warn "Skipped VM checks by --skip-vm."
    exit 0
fi

sec "6. VM reverse port listener"
if vm_listener="$(run_ssh_vm "ss -tlnp | grep -E ':${VM_RPORT}\\b' || true" 2>/dev/null)"; then
    if [[ -n "${vm_listener}" ]]; then
        ok "VM has listener on port ${VM_RPORT}:"
        printf '%s\n' "${vm_listener}" | sed 's/^/    /'
    else
        warn "VM has no listener on port ${VM_RPORT}. Reverse tunnel is closed from VM side."
    fi
else
    bad "Cannot SSH to VM alias ${VM_ALIAS}; skipped VM listener check."
fi

sec "7. VM -> Mac alias test"
if vm_alias_config="$(run_ssh_vm "ssh -G ${MAC_BACK_ALIAS} 2>/dev/null | grep -E '^(host|hostname|port|user|identityfile|identitiesonly|serveralive)' || true" 2>/dev/null)"; then
    if [[ -n "${vm_alias_config}" ]]; then
        printf '%s\n' "${vm_alias_config}" | sed 's/^/    /'
    else
        warn "VM alias ${MAC_BACK_ALIAS} is not configured or cannot be expanded."
    fi
else
    bad "Cannot query VM alias ${MAC_BACK_ALIAS}."
fi

if run_ssh_vm "ssh -o BatchMode=yes -o ConnectTimeout=${TIMEOUT} ${MAC_BACK_ALIAS} 'hostname; whoami'" >/tmp/check-ssh-rtun.mac-test.$$ 2>/tmp/check-ssh-rtun.mac-test.err.$$; then
    ok "VM can SSH back to Mac via ${MAC_BACK_ALIAS}:"
    sed 's/^/    /' "/tmp/check-ssh-rtun.mac-test.$$"
else
    warn "VM cannot SSH back to Mac via ${MAC_BACK_ALIAS} right now."
    if [[ -s "/tmp/check-ssh-rtun.mac-test.err.$$" ]]; then
        sed 's/^/    /' "/tmp/check-ssh-rtun.mac-test.err.$$"
    fi
fi
rm -f "/tmp/check-ssh-rtun.mac-test.$$" "/tmp/check-ssh-rtun.mac-test.err.$$"

sec "8. VM atimes mounts"
if atimes_lines="$(run_ssh_vm "grep fuse.atimes /proc/mounts || true" 2>/dev/null)"; then
    if [[ -n "${atimes_lines}" ]]; then
        warn "VM currently has atimes FUSE mounts:"
        printf '%s\n' "${atimes_lines}" | sed 's/^/    /'
    else
        ok "No fuse.atimes mounts visible on VM."
    fi
else
    warn "Cannot check atimes mounts on VM."
fi

sec "Summary"
if [[ -n "${rtun_processes}" && -n "${vm_listener:-}" ]]; then
    warn "Reverse tunnel appears OPEN: VM port ${VM_RPORT} can route back to this Mac."
else
    ok "Reverse tunnel appears CLOSED: no local ${RTUN_ALIAS} process and/or no VM ${VM_RPORT} listener."
fi
info "Mac sshd reachability is separate: if port 22 is reachable on LAN/VPN IPs, peers on those networks may try SSH."
