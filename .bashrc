#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# prepare prompt
niceprompt='[\u@\h] \[\e[0;36m\]\W \$ \[\e[0m\]'

function _prompt() {
    PS1="\n$(git_prompt)$niceprompt"
}

# Add git info in status bar if available
if [[ -f ~/dev/dotfiles/bash-prompt-git-status ]]; then
    . ~/dev/dotfiles/bash-prompt-git-status
    PROMPT_COMMAND=_prompt
else
    PS1="\n$niceprompt"
fi

# Set autocd
# no more need to type cd
shopt -s globstar autocd

# Source bash_completion
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# make autojump work
. /usr/share/autojump/autojump.sh

# my aliases
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
alias s='eval "sudo $(fc -ln -1)"'
se() {
    sudo -E bash -i -c "$*"
}
alias tmux='TERM=screen-256color tmux'
alias t='tmux'
alias v='nvim'
alias vim='nvim'
alias realvim='vim'
alias octave='octave-cli'
alias goals="sudo -u algorand -E goal"
alias python='python3'

alias h='history -n'
# last one to force re-read of bash history

# bash completion for g as git
if [ -f /usr/share/bash-completion/completions/git ]; then
    source /usr/share/bash-completion/completions/git
fi
__git_complete g __git_main

 #vim bindings, yeah!
#set -o vi
 #but need this to keep ESC . work normally and give you the last argument in bash
#bind -m vi-command ".":insert-last-argument

# longer history
HISTFILESIZE=10001
HISTSIZE=1000

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# immediately add command to history
export PROMPT_COMMAND="history -a;"$PROMPT_COMMAND

# turn off Ctrl + s XOFF (XON is Ctrl + q)
stty ixany
stty ixoff -ixon
stty stop undef
stty start undef

# function to get source file of bash functions
whichfunc () ( shopt -s extdebug; declare -F "$1"; )

# make sure ssh-agent is up and running
# File to store SSH agent variables
SSH_ENV="$HOME/.ssh/agent-environment"

function start_agent {
     echo "Initializing new SSH agent..."
     /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
     chmod 600 "${SSH_ENV}"
     # shellcheck source=/dev/null
     . "${SSH_ENV}" > /dev/null
     /usr/bin/ssh-add
     echo "SSH agent initialized successfully."
}

# Source SSH settings if applicable
if [ -f "${SSH_ENV}" ]; then
     # shellcheck source=/dev/null
     . "${SSH_ENV}" > /dev/null
     # Check if SSH_AGENT_PID is defined and running
     if [ -z "$SSH_AGENT_PID" ] || ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
         start_agent
     fi
else
     start_agent
fi

# souce goal completion
. ~/dev/dotfiles/bash-completions/goal

# souce asdf
. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"
