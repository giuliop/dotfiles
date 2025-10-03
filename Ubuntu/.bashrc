#
# ~/.bashrc
#

# --- env that's safe everywhere (login + interactive) ---
export LANG=en_US.UTF-8
export GOBIN=/home/gws/dev/go/bin

# PATH: put your bins first, keep system defaults after
PATH="$GOBIN:$HOME/.local/bin:$HOME/dev/scripts:$PATH"
PATH="$PATH:/usr/local/go/bin"
export PATH

export ALGORAND_DATA=/var/lib/algorand
export NODE_PATH=/usr/local/lib/node_modules

# Cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Use the systemd-managed ssh-agent socket
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.socket"

# Stop here for non-interactive shells
[[ $- != *i* ]] && return

# -------- interactive-only below --------

# Prompt
niceprompt='[\u@\h] \[\e[0;36m\]\W \$ \[\e[0m\]'
_git_prompt_file="$HOME/dev/dotfiles/Ubuntu/bash-prompt-git-status"
if [[ -f "$_git_prompt_file" ]]; then
    . "$_git_prompt_file"
    _prompt() { PS1=$'\n'"$(git_prompt)$niceprompt"; }
    PROMPT_COMMAND=_prompt
else
    PS1=$'\n'"$niceprompt"
fi

# Shell options
shopt -s globstar autocd histappend

# Bash completion
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# autojump (if installed)
[ -f /usr/share/autojump/autojump.sh ] && . /usr/share/autojump/autojump.sh

# Aliases
alias ls='ls --color=auto'
alias l="ls -AFBlh --group-directories-first --ignore='.*.swp'"
alias del='trash-put'
alias 'upd?'='/usr/lib/update-notifier/apt-check --human-readable'

alias e='emacs'
alias egrep='egrep --color=always'
alias fgrep='fgrep --color=always'
alias grep='grep --color=always'
alias g='git'
alias gg='git status'
alias less='less -R'
alias md='mkdir -p'

alias sudo="sudo "

# Re-run the last command as root, with your user config & aliases
sl() {
  local last
  last=$(fc -ln -1)
  sudo --preserve-env=HOME,XDG_CONFIG_HOME bash -i -c "$last"
}

# Run an arbitrary command as root, loading your aliases/config
s() {
  sudo --preserve-env=HOME,XDG_CONFIG_HOME bash -i -c "$*"
}

alias tmux='TERM=screen-256color tmux'
alias t='tmux'
alias v='nvim'
alias vim='nvim'
alias realvim='vim'
alias octave='octave-cli'
alias goals="sudo -u algorand -E goal"
alias python='python3'
alias claude="~/.claude/local/claude"

alias h='history -n'  # force re-read of bash history

# Git completion for 'g' shortcut
if [ -f /usr/share/bash-completion/completions/git ]; then
    . /usr/share/bash-completion/completions/git
    __git_complete g __git_main
fi

 #vim bindings, yeah!
#set -o vi
 #but need this to keep ESC . work normally and give you the last argument in bash
#bind -m vi-command ".":insert-last-argument

# History config
HISTFILESIZE=10001
HISTSIZE=1000
HISTCONTROL=ignoreboth
# Compose PROMPT_COMMAND safely (append history -a and keep existing)
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+;$PROMPT_COMMAND}"

# turn off Ctrl + s XOFF (XON is Ctrl + q)
stty ixany
stty ixoff -ixon
stty stop undef
stty start undef

# Find source file of bash functions
whichfunc () ( shopt -s extdebug; declare -F "$1"; )

# goal completion (if present)
[ -f "$HOME/dev/dotfiles/Ubuntu/bash-completions/goal" ] && . "$HOME/dev/dotfiles/Ubuntu/bash-completions/goal"

# asdf (if present)
[ -f "$HOME/.asdf/asdf.sh" ] && . "$HOME/.asdf/asdf.sh"
[ -f "$HOME/.asdf/completions/asdf.bash" ] && . "$HOME/.asdf/completions/asdf.bash"
