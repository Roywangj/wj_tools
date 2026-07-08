#!/usr/bin/env bash
# ============================================================================
# net-doctor.sh —— 网络体检 & 排障（专治 HF 镜像 / 代理导致的「下不动」）
#
# 它分层定位问题出在哪一环，并给出可直接复制的修复命令：
#   [1] 基础网络   网卡 IP / 默认网关 / DNS 配置
#   [2] DNS 解析   国内 / 国外 / HF 镜像域名能否解析
#   [3] 直连连通   绕过代理直连 百度 / hf-mirror / google
#   [4] 代理体检   当前代理变量、代理端口可达性、经代理访问外网
#   [5] HF 专项    直连镜像 vs 经代理镜像，给出下载建议
#   [6] 诊断结论   一句话定位 + 一键修复命令
#
# 用法：
#   ./net-doctor.sh            # 只体检，不改任何东西（默认）
#   ./net-doctor.sh --fix      # 体检 + 清理：解除可能拖累镜像的 git 全局代理
#   ./net-doctor.sh -h         # 帮助
#
# 说明：环境变量（http_proxy 等）属于「当前 shell」，子进程脚本改不了它，
#   所以 --fix 只会清理 git 全局代理（落在文件里、可持久），
#   终端代理变量请按结论里的提示执行 `proxy_off` 或 `unset ...`。
# ============================================================================

set -uo pipefail

# ---------------------------------------------------------------------------
# 选项
# ---------------------------------------------------------------------------
FIX=0
TIMEOUT=8
for a in "$@"; do
    case "$a" in
        --fix|--clean) FIX=1 ;;
        -h|--help)
            awk 'NR==1{next} /^[^#]/{exit} {sub(/^# ?/,""); print}' "$0"
            exit 0 ;;
        *) echo "未知选项: $a（试试 -h）" >&2; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# 小工具
# ---------------------------------------------------------------------------
have() { command -v "$1" &>/dev/null; }
ok()   { echo "  ✅ $*"; }
bad()  { echo "  ❌ $*"; }
warn() { echo "  ⚠️  $*"; }
info() { echo "  •  $*"; }
hr()   { echo "════════════════════════════════════════════════════════════"; }
sec()  { echo; echo "──── $* ────"; }

# 取 HTTP 状态码；$2 给代理 URL 则走代理，否则强制直连（--noproxy '*'）
http_code() {
    local url="$1" px="${2:-}" code
    if [[ -z "$px" ]]; then
        code="$(curl --noproxy '*' -sS -m "$TIMEOUT" -o /dev/null -w '%{http_code}' "$url" 2>/dev/null)"
    else
        code="$(curl -x "$px" -sS -m "$TIMEOUT" -o /dev/null -w '%{http_code}' "$url" 2>/dev/null)"
    fi
    echo "${code:-000}"
}

# 域名解析出首个 IPv4（多后端兜底）
resolve() {
    local h="$1"
    if have getent;   then getent ahostsv4 "$h" 2>/dev/null | awk 'NR==1{print $1}'; return; fi
    if have nslookup; then nslookup "$h" 2>/dev/null | awk '/^Address: /{print $2; exit}'; return; fi
    if have host;     then host "$h" 2>/dev/null | awk '/has address/{print $4; exit}'; return; fi
    if have python3;  then python3 -c 'import socket,sys;print(socket.gethostbyname(sys.argv[1]))' "$h" 2>/dev/null; return; fi
}

# TCP 端口是否可连（nc 优先，回退 bash /dev/tcp，带超时）
port_open() {
    local h="$1" p="$2"
    if have nc; then nc -z -w 3 "$h" "$p" &>/dev/null; return $?; fi
    if have timeout; then
        timeout 3 bash -c "exec 3<>/dev/tcp/$h/$p" &>/dev/null
    else
        (exec 3<>"/dev/tcp/$h/$p") &>/dev/null
    fi
}

# ===========================================================================
hr; echo "  net-doctor —— 网络体检（$( [[ $FIX -eq 1 ]] && echo '修复模式' || echo '只读体检' )）"; hr

# ---------------------------------------------------------------------------
# [1] 基础网络
# ---------------------------------------------------------------------------
sec "[1/6] 基础网络"
info "主机名: $(hostname 2>/dev/null)"
if have ip; then
    info "本机 IP: $(ip -br addr 2>/dev/null | awk '$2=="UP"||$1!="lo"{print $1"="$3}' | tr '\n' ' ')"
    GW="$(ip route 2>/dev/null | awk '/^default/{print $3; exit}')"
elif have ifconfig; then
    info "本机 IP: $(ifconfig 2>/dev/null | awk '/inet /{print $2}' | tr '\n' ' ')"
    GW="$(route -n get default 2>/dev/null | awk '/gateway:/{print $2; exit}')"
    [[ -z "${GW:-}" ]] && GW="$(netstat -rn 2>/dev/null | awk '/^default/{print $2; exit}')"
else
    GW=""
fi
[[ -n "${GW:-}" ]] && info "默认网关: $GW" || warn "未识别默认网关"
if [[ -f /etc/resolv.conf ]]; then
    info "DNS 服务器: $(awk '/^nameserver/{print $2}' /etc/resolv.conf | tr '\n' ' ')"
fi

# ---------------------------------------------------------------------------
# [2] DNS 解析
# ---------------------------------------------------------------------------
sec "[2/6] DNS 解析"
DNS_OK_DOMESTIC=0
for d in www.baidu.com hf-mirror.com huggingface.co www.google.com; do
    ip="$(resolve "$d")"
    if [[ -n "$ip" ]]; then
        ok "$d → $ip"
        [[ "$d" == "hf-mirror.com" || "$d" == "www.baidu.com" ]] && DNS_OK_DOMESTIC=1
    else
        bad "$d 解析失败"
    fi
done

# ---------------------------------------------------------------------------
# [3] 直连连通（强制绕过代理）
# ---------------------------------------------------------------------------
sec "[3/6] 直连连通（绕过代理）"
C_BAIDU="$(http_code https://www.baidu.com)"
C_HFM="$(http_code https://hf-mirror.com)"
C_GOOG="$(http_code https://www.google.com)"
[[ "$C_BAIDU" != "000" ]] && ok "百度    HTTP $C_BAIDU（国内基准，通）" || bad "百度 不通（服务器可能没外网 / DNS 故障）"
[[ "$C_HFM"  != "000" ]] && ok "hf-mirror HTTP $C_HFM（镜像直连，通）" || bad "hf-mirror 直连不通"
[[ "$C_GOOG" != "000" ]] && ok "google  HTTP $C_GOOG（直连竟然通）" || info "google 直连不通（国内直连本就如此，正常）"

# ---------------------------------------------------------------------------
# [4] 代理体检
# ---------------------------------------------------------------------------
sec "[4/6] 代理体检"
PX="${http_proxy:-${https_proxy:-${all_proxy:-}}}"
info "http_proxy : ${http_proxy:-<空>}"
info "https_proxy: ${https_proxy:-<空>}"
info "all_proxy  : ${all_proxy:-<空>}"
info "no_proxy   : ${no_proxy:-<空>}"
info "HF_ENDPOINT: ${HF_ENDPOINT:-<空>}"
info "git http.proxy: $(git config --global --get http.proxy 2>/dev/null || echo '<空>')"

PROXY_HFM="N/A"; PROXY_GOOG="N/A"
if [[ -n "$PX" ]]; then
    hp="${PX#*://}"; hp="${hp%/}"
    phost="${hp%%:*}"; pport="${hp##*:}"
    if port_open "$phost" "$pport"; then
        ok "代理端口 $phost:$pport 可连"
    else
        bad "代理端口 $phost:$pport 不可连（代理机/隧道没起来，或端口写错）"
    fi
    PROXY_GOOG="$(http_code https://www.google.com "$PX")"
    PROXY_HFM="$(http_code https://hf-mirror.com "$PX")"
    [[ "$PROXY_GOOG" != "000" ]] && ok "经代理访问 google HTTP $PROXY_GOOG（代理通外网）" || bad "经代理访问 google 失败（代理无效）"
    [[ "$PROXY_HFM"  != "000" ]] && info "经代理访问 hf-mirror HTTP $PROXY_HFM" || warn "经代理访问 hf-mirror 失败（代理把镜像流量带偏了）"
else
    info "当前 shell 未设置代理（直连模式）"
fi

# ---------------------------------------------------------------------------
# [5] HF 镜像专项
# ---------------------------------------------------------------------------
sec "[5/6] HF 镜像专项"
if [[ "$C_HFM" != "000" ]]; then
    ok "镜像直连可用 → 下载请走直连（proxy_off 后用 hf-download.sh）"
elif [[ "$PX" != "" && "$PROXY_HFM" != "000" ]]; then
    warn "镜像直连不通、但经代理可达 → 下载时给 hf-download.sh 加 -p"
else
    bad "镜像两条路都不通 → 见下方结论"
fi

# ---------------------------------------------------------------------------
# [6] 诊断结论 + 修复
# ---------------------------------------------------------------------------
sec "[6/6] 诊断结论"
if [[ "$C_BAIDU" == "000" && "$DNS_OK_DOMESTIC" -eq 0 ]]; then
    echo "  🔴 服务器疑似【没有外网或 DNS 故障】：国内站点都连不上。"
    echo "     建议：① 联系管理员确认服务器出网；② 检查 /etc/resolv.conf 的 nameserver"
    echo "           ③ 临时换 DNS：  echo 'nameserver 223.5.5.5' | sudo tee /etc/resolv.conf"
elif [[ "$C_HFM" != "000" ]]; then
    echo "  🟢 网络正常，镜像【直连可用】。之前下不动，基本就是代理把镜像流量带偏了。"
    echo "     ▶ 一键修复（在当前终端执行）："
    echo "         proxy_off                                  # 关代理 + 清 git 代理"
    echo "         ~/wj_tools/proxy-setup-guide/hf-download.sh <repo_id>"
    echo "     或仅清环境变量： unset http_proxy https_proxy all_proxy"
elif [[ "$PX" != "" && "$PROXY_HFM" != "000" ]]; then
    echo "  🟡 镜像直连不通、经代理能到。可让下载走代理："
    echo "         ~/wj_tools/proxy-setup-guide/hf-download.sh <repo_id> -p"
elif [[ "$PX" != "" && "$PROXY_GOOG" == "000" ]]; then
    echo "  🟠 代理本身失效（连 google 都打不通）。先修代理或直接关掉它走直连："
    echo "         proxy_lab   # 或 proxy_local，重新建立代理"
    echo "         proxy_test  # 再用你 .zshrc 里的三段式自检复查"
else
    echo "  🟠 镜像两条路都不通，但国内基准通——多半是 hf-mirror 临时抖动 / 被限速。"
    echo "     建议：稍后重试；或给 hf-download.sh 加 -x 启用 hf_transfer 重试。"
fi

# --fix：清理可能拖累镜像的 git 全局代理（落在文件里，子进程可持久修改）
if [[ "$FIX" -eq 1 ]]; then
    sec "[修复] 清理 git 全局代理"
    gp="$(git config --global --get http.proxy 2>/dev/null || true)"
    if [[ -n "$gp" ]]; then
        git config --global --unset http.proxy  2>/dev/null || true
        git config --global --unset https.proxy 2>/dev/null || true
        ok "已清除 git 全局代理（原值 $gp）"
    else
        info "git 全局代理本就为空，无需清理"
    fi
    warn "终端代理变量子进程改不了，请在当前 shell 执行： proxy_off"
fi

echo
hr
echo "  体检完成。把上面 [3]/[4]/[6] 三段贴给我，可进一步判读。"
hr
