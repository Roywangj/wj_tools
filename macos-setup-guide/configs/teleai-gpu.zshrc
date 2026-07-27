#!/bin/zsh
# ═══ teleai-gpu shell: assets under /data_wj ═══
# Canonical copy of /data_wj/.zshrc (2026-07, post screen/completion fix).
# Install:
#   cp configs/teleai-gpu.zshrc /data_wj/.zshrc
#   echo '[ -f /data_wj/.zshrc ] && source /data_wj/.zshrc' > /root/.zshrc
#
# Docs: ../screen_bug.md

export DATA_WJ="/data_wj"
export PATH="$DATA_WJ/.local/bin:$HOME/.local/bin:$PATH"

# Persist shell state under /data_wj (not ephemeral /root)
export HISTFILE="/data_wj/.zsh_history"
export ZSH_COMPDUMP="/data_wj/.cache/zsh/.zcompdump"
mkdir -p /data_wj/.cache/zsh

# UTF-8 locale: image only has C.utf8 (no en_US.UTF-8)
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export LC_CTYPE=C.UTF-8

# CUDA 12.8 toolkit
export CUDA_HOME=/usr/local/cuda-12.8
export PATH="$CUDA_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$CUDA_HOME/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# HuggingFace 镜像
export HF_ENDPOINT="https://hf-mirror.com"
export HF_HOME="/data_wj/.cache"
export HUGGINGFACE_HUB_CACHE="$HF_HOME/huggingface/hub"
mkdir -p "$HUGGINGFACE_HUB_CACHE"

# >>> conda initialize >>>
if [ -f "/data_wj/miniconda3/etc/profile.d/conda.sh" ]; then
    . "/data_wj/miniconda3/etc/profile.d/conda.sh"
fi
# <<< conda initialize <<<

# Starship: truecolor outside / 256-color twin inside GNU screen
if [[ -n "${STY:-}" || "${TERM:-}" == screen* ]]; then
  export STARSHIP_CONFIG="${DATA_WJ}/.config/starship-screen.toml"
  unset COLORTERM 2>/dev/null || true
else
  export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$DATA_WJ/.config/starship.toml}"
  export COLORTERM="${COLORTERM:-truecolor}"
fi
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# Always start screen in UTF-8 mode
alias screen='LANG=C.UTF-8 LC_ALL=C.UTF-8 screen -U'

# 自动补全建议
[ -f "$DATA_WJ/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
    source "$DATA_WJ/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

# 补全系统（screen 新窗口也必须跑 compinit，否则 Tab 无菜单补全）
autoload -Uz compinit
if [[ -n "${ZSH_COMPDUMP:-}" ]]; then
  compinit -d "${ZSH_COMPDUMP}"
else
  compinit
fi
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
bindkey '^I' expand-or-complete

# 历史（screen 内外共用同一文件）
HISTSIZE=50000
SAVEHIST=50000
# HISTFILE set above -> /data_wj/.zsh_history
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE INC_APPEND_HISTORY

# ↑/↓ 前缀搜索
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# HTTP proxy (teleai-gpu outbound)
export http_proxy=http://10.127.48.4:3128
export https_proxy=http://10.127.48.4:3128
export HTTP_PROXY=$http_proxy
export HTTPS_PROXY=$https_proxy
export no_proxy=localhost,127.0.0.1,10.0.0.0/8
export NO_PROXY=$no_proxy

# zsh-syntax-highlighting 必须在最后
[ -f "$DATA_WJ/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
    source "$DATA_WJ/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
