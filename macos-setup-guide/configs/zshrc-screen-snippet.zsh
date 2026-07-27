# ─── paste / merge into server .zshrc ───
# Prefer the full template: configs/teleai-gpu.zshrc
# Pair with: configs/screenrc + configs/starship-screen.toml
# Full write-up: ../screen_bug.md
#
# Adjust DATA_WJ if assets live under $HOME instead of /data_wj.
#
# CRITICAL: never leave .zshrc truncated after the Starship block.
# Missing `compinit` → Tab completion broken in new screen windows.

: "${DATA_WJ:=/data_wj}"
export PATH="${DATA_WJ}/.local/bin:${HOME}/.local/bin:${PATH}"

# Persist history + completion dump on durable disk
export HISTFILE="${HISTFILE:-${DATA_WJ}/.zsh_history}"
export ZSH_COMPDUMP="${ZSH_COMPDUMP:-${DATA_WJ}/.cache/zsh/.zcompdump}"
mkdir -p "${DATA_WJ}/.cache/zsh"

# --- locale: only use locales that exist (`locale -a`) ---
# Many lab images have C.utf8 but NOT en_US.UTF-8. Missing locale → screen mojibake.
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export LC_CTYPE=C.UTF-8

# --- Starship: truecolor outside / 256-color twin inside GNU screen ---
if [[ -n "${STY:-}" || "${TERM:-}" == screen* ]]; then
  export STARSHIP_CONFIG="${DATA_WJ}/.config/starship-screen.toml"
  unset COLORTERM 2>/dev/null || true
else
  export STARSHIP_CONFIG="${STARSHIP_CONFIG:-${DATA_WJ}/.config/starship.toml}"
  export COLORTERM="${COLORTERM:-truecolor}"
fi
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi
alias screen='LANG=C.UTF-8 LC_ALL=C.UTF-8 screen -U'

# --- completion / plugins (required in EVERY interactive shell, including screen) ---
[ -f "$DATA_WJ/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
  source "$DATA_WJ/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

autoload -Uz compinit
compinit -d "${ZSH_COMPDUMP}"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
bindkey '^I' expand-or-complete

# --- history: screen shares the same HISTFILE ---
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE INC_APPEND_HISTORY

autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# syntax-highlighting last
[ -f "$DATA_WJ/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
  source "$DATA_WJ/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
