#!/usr/bin/env bash
# ============================================================================
# hf-download.sh —— 通过 hf-mirror.com 镜像稳定下载 HuggingFace 模型 / 数据集
#
# 为什么需要它？
#   hf-mirror.com 是「国内镜像」，应当【直连】访问，不要走国外代理。
#   一旦把请求经 proxy_lab / proxy_local 的国外出口代理转出去，
#   镜像站反而会超时 / 被拦 / 极慢——这正是「开了代理却下不动」的根因。
#   本脚本在【下载期间临时关闭代理】（只影响脚本自身进程，不动你的 shell），
#   强制 HF_ENDPOINT=https://hf-mirror.com，并自动补齐 CLI 依赖。
#
# 用法：
#   ./hf-download.sh <repo_id> [文件模式...] [选项]
#
# 示例：
#   # 1) 下载整个模型到 HF 缓存
#   ./hf-download.sh Qwen/Qwen2.5-7B-Instruct
#
#   # 2) 下载模型到指定目录，只要 safetensors 和配置，跳过 .bin
#   ./hf-download.sh Qwen/Qwen2.5-7B-Instruct -o ./Qwen2.5-7B \
#       -i "*.safetensors" -i "*.json" -e "*.bin"
#
#   # 3) 下载数据集
#   ./hf-download.sh -d HuggingFaceH4/ultrachat_200k -o ./ultrachat
#
#   # 4) 私有库 / 需要鉴权（也可用环境变量 HF_TOKEN）
#   ./hf-download.sh meta-llama/Llama-3.1-8B -t hf_xxx
#
#   # 5) 开启 hf_transfer 高速多线程下载
#   ./hf-download.sh Qwen/Qwen2.5-7B-Instruct -x
#
#   # 6) 镜像直连通但很慢时——aria2c 16 连接硬抢带宽（需要 aria2c）
#   ./hf-download.sh -d wudongming/RAGNet --aria2 -o ./RAGNet
#
# 推荐别名（加进 ~/.zshrc，之后直接 `hfd Qwen/Qwen2.5-7B-Instruct`）：
#   alias hfd='~/wj_tools/proxy-setup-guide/hf-download.sh'
#
# 定位：本脚本是 proxy-setup-guide 的补充，专治「HF 镜像站下不动」。
#   关键点——hf-mirror.com 是国内镜像要直连，不能走 proxy_lab/proxy_local
#   的国外出口代理；脚本下载期间会临时关代理（仅本进程，不影响你的 shell）。
# ============================================================================

set -uo pipefail

# ---------------------------------------------------------------------------
# 0) 默认参数
# ---------------------------------------------------------------------------
HF_ENDPOINT_DEFAULT="https://hf-mirror.com"
REPO_TYPE="model"          # model | dataset
LOCAL_DIR=""
REVISION=""
TOKEN="${HF_TOKEN:-}"
USE_HF_TRANSFER=0
USE_ARIA2=0               # --aria2：用 aria2c 多连接高速下载（绕过国际链路单/少连接限速）
ARIA2_CONN=16             # aria2 每个文件的连接数（-x/-s）
KEEP_PROXY=0               # 默认直连镜像；置 1 时保留当前 shell 的代理
MAX_RETRY=5               # 断点续传重试次数（hf 自带续传，掉线后重跑即可接上）
declare -a INCLUDE=()
declare -a EXCLUDE=()
declare -a POSITIONAL=()

# ---------------------------------------------------------------------------
# 1) 帮助
# ---------------------------------------------------------------------------
usage() {
    cat <<'EOF'
hf-download.sh —— 通过 hf-mirror.com 镜像稳定下载 HuggingFace 模型 / 数据集

hf-mirror.com 是国内镜像，应当【直连】访问；走国外出口代理反而会超时/被拦。
本脚本下载期间临时关代理（仅影响自身进程），强制走镜像并自动补齐 CLI 依赖。

用法：
  ./hf-download.sh <repo_id> [文件模式...] [选项]

示例：
  ./hf-download.sh Qwen/Qwen2.5-7B-Instruct
  ./hf-download.sh Qwen/Qwen2.5-7B-Instruct -o ./Qwen2.5-7B -i "*.safetensors" -e "*.bin"
  ./hf-download.sh -d HuggingFaceH4/ultrachat_200k -o ./ultrachat
  ./hf-download.sh meta-llama/Llama-3.1-8B -t hf_xxx
  ./hf-download.sh Qwen/Qwen2.5-7B-Instruct -x

选项：
  -d, --dataset            下载数据集（默认下载模型）
  -o, --local-dir <dir>    下载到指定目录（默认进 HF 缓存 $HF_HOME）
  -i, --include <pattern>  仅下载匹配的文件，可重复，如 -i "*.safetensors"
  -e, --exclude <pattern>  排除匹配的文件，可重复，如 -e "*.bin"
  -r, --revision <rev>     指定分支 / tag / commit
  -t, --token <token>      HF 访问令牌（私有库；亦可用环境变量 HF_TOKEN）
  -x, --hf-transfer        启用 hf_transfer 高速下载（自动 pip 安装）
      --aria2              用 aria2c 多连接高速下载（最猛，绕过国际链路限速）
  -j, --conn <n>           aria2 每文件连接数（默认 16，配合 --aria2）
  -p, --proxy              下载时【保留】当前代理（默认直连镜像，不走代理）
      --endpoint <url>     覆盖镜像地址（默认 https://hf-mirror.com）
  -n, --retry <n>          掉线重试次数（默认 5）
  -h, --help               显示本帮助
EOF
}

# ---------------------------------------------------------------------------
# 2) 解析参数
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dataset)      REPO_TYPE="dataset"; shift ;;
        -o|--local-dir)    LOCAL_DIR="$2"; shift 2 ;;
        -i|--include)      INCLUDE+=("$2"); shift 2 ;;
        -e|--exclude)      EXCLUDE+=("$2"); shift 2 ;;
        -r|--revision)     REVISION="$2"; shift 2 ;;
        -t|--token)        TOKEN="$2"; shift 2 ;;
        -x|--hf-transfer)  USE_HF_TRANSFER=1; shift ;;
        --aria2)           USE_ARIA2=1; shift ;;
        -j|--conn)         ARIA2_CONN="$2"; shift 2 ;;
        -p|--proxy)        KEEP_PROXY=1; shift ;;
        --endpoint)        HF_ENDPOINT_DEFAULT="$2"; shift 2 ;;
        -n|--retry)        MAX_RETRY="$2"; shift 2 ;;
        -h|--help)         usage; exit 0 ;;
        --)                shift; while [[ $# -gt 0 ]]; do POSITIONAL+=("$1"); shift; done ;;
        -*)                echo "❌ 未知选项: $1" >&2; usage; exit 1 ;;
        *)                 POSITIONAL+=("$1"); shift ;;
    esac
done

if [[ ${#POSITIONAL[@]} -lt 1 ]]; then
    echo "❌ 缺少 repo_id（如 Qwen/Qwen2.5-7B-Instruct）" >&2
    echo ""
    usage
    exit 1
fi

REPO_ID="${POSITIONAL[0]}"
FILES=("${POSITIONAL[@]:1}")   # 余下的位置参数当作「指定文件」传给 hf download

# ---------------------------------------------------------------------------
# 3) 环境：强制镜像端点；默认临时关代理（仅影响本进程）
# ---------------------------------------------------------------------------
export HF_ENDPOINT="$HF_ENDPOINT_DEFAULT"
# 沿用你 .zshrc 里的缓存目录（若已设则不覆盖）
export HF_HOME="${HF_HOME:-/data1/users/wangjie01/.cache}"

if [[ "$KEEP_PROXY" -eq 0 ]]; then
    # 直连镜像：清掉本进程的代理变量，并把镜像域名塞进 no_proxy 兜底
    unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
    export no_proxy="hf-mirror.com,${no_proxy:-localhost,127.0.0.1}"
    export NO_PROXY="$no_proxy"
    PROXY_MODE="直连（已临时关闭代理）"
else
    PROXY_MODE="保留当前代理 ${http_proxy:-未设置}"
fi

if [[ "$TOKEN" != "" ]]; then
    export HF_TOKEN="$TOKEN"
fi

# ---------------------------------------------------------------------------
# 4) 依赖检查：优先用新版 `hf`，回退老版 `huggingface-cli`，缺则自动安装
# ---------------------------------------------------------------------------
detect_cli() {
    if command -v hf &>/dev/null; then
        HF_CLI="hf"
    elif command -v huggingface-cli &>/dev/null; then
        HF_CLI="huggingface-cli"
    else
        HF_CLI=""
    fi
}

detect_cli
if [[ -z "$HF_CLI" ]]; then
    echo "ℹ️  未检测到 huggingface CLI，正在安装 huggingface_hub[cli] ..."
    pip install -U "huggingface_hub[cli]" || {
        echo "❌ 安装失败。请手动执行：pip install -U \"huggingface_hub[cli]\"" >&2
        exit 1
    }
    detect_cli
    [[ -z "$HF_CLI" ]] && { echo "❌ 仍未找到 hf / huggingface-cli，请检查 PATH" >&2; exit 1; }
fi

if [[ "$USE_HF_TRANSFER" -eq 1 ]]; then
    if ! python -c "import hf_transfer" &>/dev/null; then
        echo "ℹ️  正在安装 hf_transfer（高速下载后端）..."
        pip install -U hf_transfer || echo "⚠️  hf_transfer 安装失败，回退普通下载"
    fi
    export HF_HUB_ENABLE_HF_TRANSFER=1
fi

# ---------------------------------------------------------------------------
# 4.5) aria2c 高速下载（--aria2）：用 huggingface_hub 列文件，逐个多连接拉
#      适合「镜像直连通但很慢」的场景（国际链路被整形，多连接硬抢带宽）
# ---------------------------------------------------------------------------
download_aria2() {
    if ! command -v aria2c &>/dev/null; then
        echo "❌ 未找到 aria2c。择一安装后重试：" >&2
        echo "     conda install -c conda-forge aria2 -y      # 免 sudo（你有 conda，推荐）" >&2
        echo "     sudo apt update && sudo apt install -y aria2" >&2
        return 1
    fi
    local rev="${REVISION:-main}"
    local outdir="${LOCAL_DIR:-./${REPO_ID##*/}}"
    mkdir -p "$outdir"

    # 镜像直链前缀（数据集多一段 /datasets）
    local base
    if [[ "$REPO_TYPE" == "dataset" ]]; then
        base="${HF_ENDPOINT}/datasets/${REPO_ID}/resolve/${rev}"
    else
        base="${HF_ENDPOINT}/${REPO_ID}/resolve/${rev}"
    fi

    # 用 huggingface_hub 列出仓库文件，并应用 include/exclude
    export HFD_INCLUDE HFD_EXCLUDE
    HFD_INCLUDE="$( [[ ${#INCLUDE[@]} -gt 0 ]] && printf '%s\n' "${INCLUDE[@]}" )"
    HFD_EXCLUDE="$( [[ ${#EXCLUDE[@]} -gt 0 ]] && printf '%s\n' "${EXCLUDE[@]}" )"
    local files
    files="$(python - "$REPO_ID" "$REPO_TYPE" "$rev" <<'PY'
import os, sys, fnmatch
from huggingface_hub import HfApi
repo, rtype, rev = sys.argv[1], sys.argv[2], sys.argv[3]
inc = [p for p in os.environ.get("HFD_INCLUDE", "").splitlines() if p]
exc = [p for p in os.environ.get("HFD_EXCLUDE", "").splitlines() if p]
tok = os.environ.get("HF_TOKEN") or None
api = HfApi(endpoint=os.environ.get("HF_ENDPOINT"))
try:
    files = api.list_repo_files(repo, repo_type=rtype, revision=rev, token=tok)
except Exception as e:
    sys.stderr.write("列举文件失败: %s\n" % e); sys.exit(2)
def keep(f):
    if inc and not any(fnmatch.fnmatch(f, p) for p in inc): return False
    if exc and any(fnmatch.fnmatch(f, p) for p in exc): return False
    return True
for f in files:
    if keep(f): print(f)
PY
)" || { echo "❌ 获取文件列表失败（私有库记得 -t <token>）" >&2; return 1; }

    if [[ -z "$files" ]]; then
        echo "❌ 没有匹配的文件（检查 repo / --include / --exclude）" >&2
        return 1
    fi
    local n; n="$(printf '%s\n' "$files" | grep -c .)"
    echo "🚀 aria2c 高速模式：${n} 个文件 → ${outdir}（每文件 ${ARIA2_CONN} 连接）"

    local -a auth=()
    [[ -n "$TOKEN" ]] && auth=(--header "Authorization: Bearer ${TOKEN}")

    local f rc_all=0
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        echo ""
        echo "—— ${f} ——"
        aria2c -c -x "$ARIA2_CONN" -s "$ARIA2_CONN" -k 1M \
               --max-tries=0 --retry-wait=3 --timeout=60 \
               --file-allocation=none --auto-file-renaming=false \
               --console-log-level=warn --summary-interval=10 \
               ${auth[@]+"${auth[@]}"} -d "$outdir" -o "$f" "${base}/${f}" || rc_all=1
    done <<< "$files"

    if [[ "$rc_all" -eq 0 ]]; then
        echo ""
        echo "🎉 aria2 下载完成：${REPO_ID} → ${outdir}"
    else
        echo "⚠️  有文件未完成；重跑同一命令会用 aria2 -c 断点续传。" >&2
    fi
    return "$rc_all"
}

# ---------------------------------------------------------------------------
# 5) 连通性自检（直连模式下确认镜像可达）
# ---------------------------------------------------------------------------
echo "════════════════════════════════════════════════════════════"
echo "  仓库      : $REPO_ID  (${REPO_TYPE})"
echo "  镜像端点  : $HF_ENDPOINT"
echo "  代理模式  : $PROXY_MODE"
echo "  缓存/目录 : ${LOCAL_DIR:-$HF_HOME}"
echo "  CLI       : $HF_CLI"
echo "════════════════════════════════════════════════════════════"

code="$(curl -sS -m 10 -o /dev/null -w '%{http_code}' "$HF_ENDPOINT" 2>/dev/null)"
code="${code:-000}"
if [[ "$code" == "000" ]]; then
    echo "⚠️  无法连通 ${HF_ENDPOINT} 。"
    if [[ "$KEEP_PROXY" -eq 0 ]]; then
        echo "    直连不通时可尝试：① 确认服务器能上外网；② 加 -p 让本次走代理。"
    else
        echo "    代理模式不通时可去掉 -p 改直连，或检查 proxy_lab/proxy_local 是否生效。"
    fi
else
    echo "✅ 镜像可达（HTTP ${code}），开始下载..."
fi

# aria2 高速档：绕过 hf CLI 的单/少连接，直接多连接拉，下完即退
if [[ "$USE_ARIA2" -eq 1 ]]; then
    download_aria2
    exit $?
fi

# ---------------------------------------------------------------------------
# 6) 组装下载命令
# ---------------------------------------------------------------------------
build_cmd() {
    DL_CMD=("$HF_CLI" download "$REPO_ID")
    [[ ${#FILES[@]} -gt 0 ]] && DL_CMD+=("${FILES[@]}")
    DL_CMD+=(--repo-type "$REPO_TYPE")
    [[ -n "$LOCAL_DIR" ]] && DL_CMD+=(--local-dir "$LOCAL_DIR")
    [[ -n "$REVISION" ]]  && DL_CMD+=(--revision "$REVISION")
    [[ -n "$TOKEN" ]]     && DL_CMD+=(--token "$TOKEN")
    local p
    if [[ ${#INCLUDE[@]} -gt 0 ]]; then
        for p in "${INCLUDE[@]}"; do DL_CMD+=(--include "$p"); done
    fi
    if [[ ${#EXCLUDE[@]} -gt 0 ]]; then
        for p in "${EXCLUDE[@]}"; do DL_CMD+=(--exclude "$p"); done
    fi
}
build_cmd

# ---------------------------------------------------------------------------
# 7) 带重试的下载循环（hf 自带断点续传，掉线后重跑会从已下载处继续）
# ---------------------------------------------------------------------------
attempt=1
while true; do
    echo ""
    echo "—— 第 ${attempt}/${MAX_RETRY} 次尝试 ——"
    if "${DL_CMD[@]}"; then
        echo ""
        echo "🎉 下载完成：${REPO_ID}"
        echo "   位置：${LOCAL_DIR:-$HF_HOME}"
        exit 0
    else
        rc=$?
    fi
    if [[ "$attempt" -ge "$MAX_RETRY" ]]; then
        echo "❌ 已重试 ${MAX_RETRY} 次仍失败（退出码 ${rc}）。" >&2
        echo "   排查建议：" >&2
        echo "     • 私有库需 -t <token> 或先 \`$HF_CLI login\`" >&2
        echo "     • 直连不稳可加 -x 启用 hf_transfer，或加 -p 走代理" >&2
        echo "     • 确认仓库名 / --revision 是否正确" >&2
        exit "$rc"
    fi
    wait_s=$(( attempt * 3 ))
    echo "⚠️  本次失败（退出码 ${rc}），${wait_s}s 后续传重试..."
    sleep "$wait_s"
    attempt=$(( attempt + 1 ))
done
