# Exit early for non-interactive shells
[[ $- != *i* ]] && return

typeset -U path fpath

# ---- PATH helper ------------------------------------------------------------
path_append_if_exists () {
  [[ -d "$1" ]] && path+=("$1")
}

path_prepend_if_exists () {
  [[ -d "$1" ]] && path=("$1" $path)
}

# ---- History ----------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY

# ---- Editor -----------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"

# ---- Environment ------------------------------------------------------------
export GPG_TTY=$(tty)
export PIPENV_MAX_DEPTH=4

# ---- PATH additions ---------------------------------------------------------
path_append_if_exists "$HOME/dev/scripts"
path_append_if_exists "$HOME/go/bin"
path_prepend_if_exists "$HOME/dev/algorand/node"
path_append_if_exists "$HOME/Library/Python/3.9/bin"
path_append_if_exists "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
path_append_if_exists "$HOME/.local/bin"

# ---- Completion -------------------------------------------------------------
[[ -d "$HOME/dev/dotfiles/Mac/zsh-completions" ]] && \
  fpath=("$HOME/dev/dotfiles/Mac/zsh-completions" $fpath)

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

autoload -Uz compinit
compinit

# ---- Tools ------------------------------------------------------------------
eval "$(zoxide init zsh)"
export STARSHIP_CONFIG="$HOME/dev/dotfiles/Mac/starship.toml"
eval "$(starship init zsh)"
[[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"

# ---- Aliases ----------------------------------------------------------------
alias g="git"
alias gg="git status"

alias ..="cd .."
alias md="mkdir -p"

alias j="z"
alias jj="zi"

alias t="tmux"

alias v="nvim"
alias vim="nvim"
alias realvim="vim"

alias python="python3"

alias l="eza -la --icons --git"
alias ll="eza -la"
alias lt="eza --tree --level=2"
alias sudo="sudo "

# ---- History navigation -----------------------------------------------------
bindkey "^p" history-beginning-search-backward
bindkey "^o" history-beginning-search-forward

# ---- Optional tool completions ---------------------------------------------
[[ -f "$HOME/.config/algokit/.algokit-completions.zsh" ]] && \
  . "$HOME/.config/algokit/.algokit-completions.zsh"
