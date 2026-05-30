#!/bin/zsh
# ═══ 1) Starship + 插件主体(新)═══

# 用户级 bin 优先(让 ~/.local/bin 里的 starship/eza/delta 等生效)
export PATH="$HOME/.local/bin:$PATH"

# Starship 提示符
command -v starship &>/dev/null && eval "$(starship init zsh)"

# 自动补全建议
[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# 补全系统
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# 历史
HISTSIZE=50000; SAVEHIST=50000; HISTFILE=~/.zsh_history
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE INC_APPEND_HISTORY

# ↑/↓ 前缀搜索
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search; zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# fzf
command -v fzf &>/dev/null && eval "$(fzf --zsh 2>/dev/null)"
command -v fd &>/dev/null && export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# zoxide(智能 cd)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# modern CLI 别名(命令存在才设)
command -v eza   &>/dev/null && alias ls='eza --icons --group-directories-first' ll='eza -la --icons --group-directories-first' lt='eza --tree --icons --level=2'
command -v bat   &>/dev/null && alias cat='bat'
command -v rg    &>/dev/null && alias grep='rg'
command -v btop  &>/dev/null && alias top='btop'
command -v lazygit &>/dev/null && alias lg='lazygit'

# ═══════════════════════════════════════════════════════════
# ═══ 2) 个人配置(从旧 .zshrc 原样搬过来,保持启用)═══
# ═══════════════════════════════════════════════════════════

# CUDA
# export PATH=/usr/local/cuda-11.3/bin${PATH:+:${PATH}}
# export LD_LIBRARY_PATH=/usr/local/cuda-11.3/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# export PATH="/data/users/wangying/cuda/cuda-11.8/bin:$PATH"
# export LD_LIBRARY_PATH="/data/users/wangying/cuda/cuda-11.8/lib64:/data/users/wangying/cuda/cuda-11.8/mylib/lib64:$LD_LIBRARY_PATH"

# export PATH=/usr/local/cuda-12.1/bin${PATH:+:${PATH}}
# export LD_LIBRARY_PATH=/usr/local/cuda-12.1/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

export CUDA_HOME=/usr/local/cuda-12.8
export PATH=/usr/local/cuda-12.8/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64:$LD_LIBRARY_PATH

# >>> conda initialize >>>            ← 整块照搬
__conda_setup="$('/data1/users/wangjie01/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/data1/users/wangjie01/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/data1/users/wangjie01/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/data1/users/wangjie01/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# conda / CUDA 别名
alias ca='conda activate'
alias cda='conda deactivate'
alias cvd0='CUDA_VISIBLE_DEVICES=0'
alias cvd1='CUDA_VISIBLE_DEVICES=1'
alias cvd2='CUDA_VISIBLE_DEVICES=2'
alias cvd3='CUDA_VISIBLE_DEVICES=3'
alias cvd4='CUDA_VISIBLE_DEVICES=4'
alias cvd5='CUDA_VISIBLE_DEVICES=5'
alias cvd6='CUDA_VISIBLE_DEVICES=6'
alias cvd7='CUDA_VISIBLE_DEVICES=7'

# HuggingFace 镜像
export HF_ENDPOINT="https://hf-mirror.com"
export HF_HOME="/data1/users/wangjie01/.cache"
export HUGGINGFACE_HUB_CACHE="$HF_HOME/huggingface/hub"

# ==================== 代理配置(整段照搬,保持多行形式)====================
# 第一步：两种切换入口（端口各自指定，避免与其他同学冲突）
function proxy_lab() {    # 走实验室代理机（LAN 固定网关）
    export PROXY_HOST="10.106.1.36"                  # 修改为您的 LAN 代理地址
    # export PROXY_HOST="10.62.249.209"                  # 修改为您的 LAN 代理地址
    export PROXY_PORT="7897"                         # 实验室代理机监听端口
    export PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
    _proxy_apply
}

function proxy_local() {  # 走本机代理（经 SSH RemoteForward 隧道）
    export PROXY_HOST="127.0.0.1"
    export PROXY_PORT="5140"                         # 服务器端隧道监听端口，避让公共 7897
    export PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
    _proxy_apply
}

# 第三步：内部函数，实际下发环境变量 / Git 配置 / no_proxy
function _proxy_apply() {
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    export all_proxy="socks5://${PROXY_HOST}:${PROXY_PORT}"

    # Git 全局代理
    git config --global http.proxy  "$PROXY_URL"
    git config --global https.proxy "$PROXY_URL"

    # 内网/本地地址直连（避免校园网认证等被代理拦截）
    export no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,*.local"

    echo "代理已切换到 $PROXY_URL"
}

function proxy_off() {
    unset http_proxy https_proxy all_proxy
    git config --global --unset http.proxy  2>/dev/null
    git config --global --unset https.proxy 2>/dev/null
    echo "代理已关闭"
}

# 第三步半：代理链路三段式自检
#   1) SSH RemoteForward 服务器端是否在监听
#   2) 服务器能否直连 127.0.0.1:$PROXY_PORT 的本地 Clash
#   3) 当前 shell 的 http_proxy 环境变量是否能打通外网
function proxy_test() {
    echo "==== [1/3] 隧道监听检测 ($PROXY_HOST:$PROXY_PORT) ===="
    if [[ "$PROXY_HOST" == "127.0.0.1" ]]; then
        ss -tln 2>/dev/null | grep -E "[:.]${PROXY_PORT}\b" \
            && echo "✅ 端口 $PROXY_PORT 正在监听" \
            || echo "❌ 端口 $PROXY_PORT 未监听（检查本地 ~/.ssh/config 的 RemoteForward 是否生效）"
    else
        echo "↪ 非本地转发模式，跳过隧道检测"
    fi

    echo "==== [2/3] 代理点对点可达 ===="
    curl -x "http://${PROXY_HOST}:${PROXY_PORT}" -sS -o /dev/null -m 8 \
         -w "HTTP %{http_code}  耗时 %{time_total}s\n" https://www.google.com \
         && echo "✅ 代理能打通 Google" || echo "❌ 代理无法访问外网"

    echo "==== [3/3] 当前 shell 环境变量 ===="
    if [[ -n "$http_proxy" ]]; then
        curl -sS -o /dev/null -m 8 \
             -w "HTTP %{http_code}  出口 IP 检测见下行\n" https://www.google.com \
             && curl -sS -m 8 https://ipinfo.io/ip && echo
    else
        echo "⚠ 当前 shell 未设置 http_proxy，可先执行 proxy_lab / proxy_local"
    fi
}

# 同步代理配置到 VSCode/Cursor 的别名（被自动同步以及手动调用复用）
alias sync-proxy='~/wj_tools/proxy-setup-guide/sync-proxy-config.sh'
# 一键体检：打印当前终端代理变量 + 编辑器 settings.json 内容
alias echo-proxy='~/wj_tools/proxy-setup-guide/echo_proxy.sh'

# 第四步：默认登录时走哪条线路？（二选一，取消对应行前的 # 即可）
#   - proxy_lab   ：走实验室代理机（LAN 固定网关，断线不影响后台任务）
#   - proxy_local ：走本机代理（需本地 ~/.ssh/config 配 RemoteForward）
# proxy_lab
proxy_local

# proxy_test
# proxy_off

# 第五步：登录时自动同步代理到编辑器，并打印一次体检信息（不想要就注释掉）
sync-proxy >/dev/null
echo-proxy

# 其他 PATH
export PATH=/data1/users/wangjie01/.opencode/bin:$PATH
export PATH="/data1/users/wangjie01/coding_tools/node-v24.14.0-linux-x64/bin:$PATH"

# ═══════════════════════════════════════════════════════════
# ═══ 3) zsh-syntax-highlighting(必须在最后)═══
# ═══════════════════════════════════════════════════════════
[ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
    source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ═══════════════════════════════════════════════════════════
# ═══ 4) 旧 Oh My Zsh 配置(注释保留,可回退)═══
# 想切回 OMZ:注释掉上面 Starship 那段,取消下面注释。
# ═══════════════════════════════════════════════════════════
# export ZSH="$HOME/.oh-my-zsh"
# ZSH_THEME="cloud"
# HIST_STAMPS="mm/dd/yyyy"
# plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)
# source $ZSH/oh-my-zsh.sh