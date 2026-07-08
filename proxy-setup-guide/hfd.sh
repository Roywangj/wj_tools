#!/usr/bin/env bash
# ============================================================================
# hfd.sh —— HuggingFace 高速下载器（aria2c 多连接，走 hf-mirror 镜像）
#
# 思路（和 hf-mirror 官方 hfd 一致）：
#   ① 调 /api 列出仓库所有文件（curl + python3 标准库解析，不需要 jq/git）
#   ② 每个文件用 aria2c 开 N 条连接并行拉，绕过国际链路「单连接限速」
#   ③ 断点续传：重跑同一命令会从已下载处接着下（aria2 -c）
# 只依赖：curl、python3(标准库)、aria2c（缺则提示用 conda 装，免 sudo）。
#
# 用法：
#   ./hfd.sh <repo_id> [选项]
#
# 示例：
#   ./hfd.sh Qwen/Qwen2.5-7B-Instruct                       # 下整个模型
#   ./hfd.sh Qwen/Qwen2.5-7B-Instruct --include "*.safetensors" "*.json"
#   ./hfd.sh wudongming/RAGNet --dataset -o /data1/users/wangjie01/RAGNet
#   ./hfd.sh meta-llama/Llama-3.1-8B --token hf_xxx -x 16
#
# 选项：
#   --dataset                下载数据集（默认模型）
#   --include  <pat> ...      仅下载匹配的文件（可跟多个，空格分隔）
#   --exclude  <pat> ...      排除匹配的文件（可跟多个，空格分隔）
#   -x, --threads <n>        每个文件的连接数（默认 8；想更猛可 16）
#   --revision <rev>         分支 / tag / commit（默认 main）
#   -o, --local-dir <dir>    保存目录（默认 ./<仓库名>）
#   --token <token>          HF 访问令牌（私有库；亦可用环境变量 HF_TOKEN）
#   --tool <aria2c|wget>     下载器（默认 aria2c；无 aria2c 时可 wget）
#   -p, --proxy              保留当前代理（默认直连镜像，不走代理）
#   --endpoint <url>         覆盖镜像地址（默认 https://hf-mirror.com）
#   -h, --help               显示帮助
# ============================================================================

set -uo pipefail

RED=$'\033[0;31m'; GRN=$'\033[0;32m'; YLW=$'\033[1;33m'; CYN=$'\033[0;36m'; NC=$'\033[0m'
trap 'printf "\n%s已中断。重跑同一命令可断点续传。%s\n" "$YLW" "$NC"; exit 130' INT

# ---------------------------------------------------------------------------
# 默认值
# ---------------------------------------------------------------------------
REPO_ID=""
DATASET=0
THREADS=8
REVISION="main"
LOCAL_DIR=""
HF_TOKEN="${HF_TOKEN:-}"
TOOL="aria2c"
KEEP_PROXY=0
HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"
declare -a INCLUDE=()
declare -a EXCLUDE=()

usage() { awk 'NR==1{next} /^[^#]/{exit} {sub(/^# ?/,""); print}' "$0"; }

# ---------------------------------------------------------------------------
# 解析参数（--include/--exclude 支持跟多个值，直到下一个 - 开头的选项）
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)        usage; exit 0 ;;
        --dataset)        DATASET=1; shift ;;
        -x|--threads)     THREADS="$2"; shift 2 ;;
        --revision)       REVISION="$2"; shift 2 ;;
        -o|--local-dir)   LOCAL_DIR="$2"; shift 2 ;;
        --token|--hf_token) HF_TOKEN="$2"; shift 2 ;;
        --tool)           TOOL="$2"; shift 2 ;;
        --endpoint)       HF_ENDPOINT="$2"; shift 2 ;;
        -p|--proxy)       KEEP_PROXY=1; shift ;;
        --include)        shift; while [[ $# -gt 0 && "$1" != -* ]]; do INCLUDE+=("$1"); shift; done ;;
        --exclude)        shift; while [[ $# -gt 0 && "$1" != -* ]]; do EXCLUDE+=("$1"); shift; done ;;
        -*)               echo "${RED}未知选项: $1${NC}" >&2; usage; exit 1 ;;
        *)                if [[ -z "$REPO_ID" ]]; then REPO_ID="$1"; else echo "${RED}多余参数: $1${NC}" >&2; exit 1; fi; shift ;;
    esac
done

if [[ -z "$REPO_ID" ]]; then
    echo "${RED}❌ 缺少 repo_id${NC}" >&2; echo ""; usage; exit 1
fi

# ---------------------------------------------------------------------------
# 环境：镜像端点 + 默认直连（仅本进程）
# ---------------------------------------------------------------------------
export HF_ENDPOINT
if [[ "$KEEP_PROXY" -eq 0 ]]; then
    unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
    export no_proxy="hf-mirror.com,${no_proxy:-localhost,127.0.0.1}"
    PROXY_MODE="直连"
else
    PROXY_MODE="保留代理 ${http_proxy:-未设置}"
fi

# ---------------------------------------------------------------------------
# 依赖检查
# ---------------------------------------------------------------------------
command -v curl    &>/dev/null || { echo "${RED}❌ 需要 curl${NC}" >&2; exit 1; }
command -v python3 &>/dev/null || { echo "${RED}❌ 需要 python3${NC}" >&2; exit 1; }
if [[ "$TOOL" == "aria2c" ]] && ! command -v aria2c &>/dev/null; then
    echo "${YLW}⚠️  未找到 aria2c。择一安装：${NC}" >&2
    echo "     conda install -c conda-forge aria2 -y     # 免 sudo（推荐）" >&2
    echo "     sudo apt update && sudo apt install -y aria2" >&2
    echo "   或临时退回 wget： $0 $REPO_ID --tool wget ..." >&2
    exit 1
fi
[[ "$TOOL" == "wget" ]] && { command -v wget &>/dev/null || { echo "${RED}❌ 需要 wget${NC}" >&2; exit 1; }; }

# ---------------------------------------------------------------------------
# URL 组装
# ---------------------------------------------------------------------------
if [[ "$DATASET" -eq 1 ]]; then
    API="${HF_ENDPOINT}/api/datasets/${REPO_ID}/revision/${REVISION}"
    RESOLVE="${HF_ENDPOINT}/datasets/${REPO_ID}/resolve/${REVISION}"
    KIND="数据集"
else
    API="${HF_ENDPOINT}/api/models/${REPO_ID}/revision/${REVISION}"
    RESOLVE="${HF_ENDPOINT}/${REPO_ID}/resolve/${REVISION}"
    KIND="模型"
fi
LOCAL_DIR="${LOCAL_DIR:-./${REPO_ID##*/}}"

echo "${CYN}════════════════════════════════════════════════════════════${NC}"
echo "  hfd —— ${KIND}：${REPO_ID}  (@${REVISION})"
echo "  镜像端点 : ${HF_ENDPOINT}   [${PROXY_MODE}]"
echo "  保存目录 : ${LOCAL_DIR}"
echo "  下载器   : ${TOOL}  ×${THREADS} 连接/文件"
echo "${CYN}════════════════════════════════════════════════════════════${NC}"

# ---------------------------------------------------------------------------
# 取文件清单（curl 拉 /api，python3 解析 siblings + 应用 include/exclude）
# ---------------------------------------------------------------------------
declare -a CURL_AUTH=()
[[ -n "$HF_TOKEN" ]] && CURL_AUTH=(-H "Authorization: Bearer ${HF_TOKEN}")

API_JSON="$(curl -fsSL -m 30 ${CURL_AUTH[@]+"${CURL_AUTH[@]}"} "$API" 2>/dev/null)" || {
    echo "${RED}❌ 拉取仓库信息失败：${API}${NC}" >&2
    echo "   检查：仓库名 / --revision 是否正确；私有库需 --token" >&2
    exit 1
}

export HFD_INCLUDE HFD_EXCLUDE
HFD_INCLUDE="$( [[ ${#INCLUDE[@]} -gt 0 ]] && printf '%s\n' "${INCLUDE[@]}" )"
HFD_EXCLUDE="$( [[ ${#EXCLUDE[@]} -gt 0 ]] && printf '%s\n' "${EXCLUDE[@]}" )"

FILES="$(printf '%s' "$API_JSON" | python3 -c '
import sys, json, os, fnmatch
try:
    data = json.load(sys.stdin)
except Exception as e:
    sys.stderr.write("解析 API JSON 失败: %s\n" % e); sys.exit(2)
sib = data.get("siblings", [])
inc = [p for p in os.environ.get("HFD_INCLUDE", "").splitlines() if p]
exc = [p for p in os.environ.get("HFD_EXCLUDE", "").splitlines() if p]
def keep(f):
    if inc and not any(fnmatch.fnmatch(f, p) for p in inc): return False
    if exc and any(fnmatch.fnmatch(f, p) for p in exc): return False
    return True
for s in sib:
    f = s.get("rfilename")
    if f and keep(f):
        print(f)
')" || { echo "${RED}❌ 解析文件清单失败${NC}" >&2; exit 1; }

if [[ -z "$FILES" ]]; then
    echo "${RED}❌ 没有匹配的文件（检查 --include / --exclude）${NC}" >&2; exit 1
fi
N="$(printf '%s\n' "$FILES" | grep -c .)"
echo "${GRN}📋 共 ${N} 个文件待下载${NC}"

mkdir -p "$LOCAL_DIR"

# ---------------------------------------------------------------------------
# 逐个文件下载
# ---------------------------------------------------------------------------
declare -a A_AUTH=()
[[ -n "$HF_TOKEN" ]] && A_AUTH=(--header "Authorization: Bearer ${HF_TOKEN}")

i=0; fail=0
while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    i=$((i + 1))
    url="${RESOLVE}/${f}"
    echo ""
    echo "${CYN}[$i/$N] ${f}${NC}"
    if [[ "$TOOL" == "wget" ]]; then
        mkdir -p "$LOCAL_DIR/$(dirname "$f")"
        wget -c -q --show-progress -O "$LOCAL_DIR/$f" \
             ${HF_TOKEN:+--header="Authorization: Bearer ${HF_TOKEN}"} "$url" || fail=$((fail + 1))
    else
        aria2c -c -x "$THREADS" -s "$THREADS" -k 1M \
               --max-tries=0 --retry-wait=3 --timeout=60 \
               --file-allocation=none --auto-file-renaming=false \
               --console-log-level=warn --summary-interval=10 \
               ${A_AUTH[@]+"${A_AUTH[@]}"} -d "$LOCAL_DIR" -o "$f" "$url" || fail=$((fail + 1))
    fi
done <<< "$FILES"

echo ""
if [[ "$fail" -eq 0 ]]; then
    echo "${GRN}🎉 全部完成：${REPO_ID} → ${LOCAL_DIR}${NC}"
    exit 0
else
    echo "${YLW}⚠️  有 ${fail}/${N} 个文件未完成；重跑同一命令会断点续传。${NC}" >&2
    exit 1
fi
