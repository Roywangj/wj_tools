# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="cloud"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git
z
zsh-autosuggestions
zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# export PATH=/usr/local/cuda-11.3/bin${PATH:+:${PATH}}
# export LD_LIBRARY_PATH=/usr/local/cuda-11.3/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# export PATH="/data/users/wangying/cuda/cuda-11.8/bin:$PATH"
# export LD_LIBRARY_PATH="/data/users/wangying/cuda/cuda-11.8/lib64:/data/users/wangying/cuda/cuda-11.8/mylib/lib64:$LD_LIBRARY_PATH"

# export PATH=/usr/local/cuda-12.1/bin${PATH:+:${PATH}}
# export LD_LIBRARY_PATH=/usr/local/cuda-12.1/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

export CUDA_HOME=/usr/local/cuda-12.8
export PATH=/usr/local/cuda-12.8/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64:$LD_LIBRARY_PATH


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/data1/users/wangjie01/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
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

export HF_ENDPOINT="https://hf-mirror.com" 
export HF_HOME="/data1/users/wangjie01/.cache"
export HUGGINGFACE_HUB_CACHE="$HF_HOME/huggingface/hub"

# export CPLUS_INCLUDE_PATH=$(conda info --base)/envs/mamba3d/include:$CPLUS_INCLUDE_PATH

# ==================== 代理配置 ====================
# 第一步：两种切换入口（端口各自指定，避免与其他同学冲突）
function proxy_lab() {    # 走实验室代理机（LAN 固定网关）
    export PROXY_HOST="10.106.1.36"
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

    # 内网/本地地址直连，避免校园网认证等被拦
    export no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,*.local"

    echo "代理已切换到 $PROXY_URL"
}

function proxy_off() {
    unset http_proxy https_proxy all_proxy
    git config --global --unset http.proxy  2>/dev/null
    git config --global --unset https.proxy 2>/dev/null
    echo "代理已关闭"
}

# 同步代理配置到 VSCode/Cursor 的别名（被下方自动同步以及手动调用复用）
alias sync-proxy='~/wj_tools/proxy-setup-guide/sync-proxy-config.sh'
# 一键体检：打印当前终端代理变量 + 编辑器 settings.json 内容
alias echo-proxy='~/wj_tools/proxy-setup-guide/echo_proxy.sh'

# ---------------------------------------------------------------
# 第四步：默认登录时走哪条线路？（二选一，取消对应行前的 # 即可）
#
#   - proxy_lab   ：走实验室代理机（LAN 固定网关，断线不影响后台任务）
#   - proxy_local ：走本机代理（需本地 ~/.ssh/config 配 RemoteForward）
# ---------------------------------------------------------------
proxy_lab
# proxy_local

# 第五步：登录时自动同步代理到编辑器，并打印一次体检信息（不想要就注释掉）
sync-proxy >/dev/null
echo-proxy