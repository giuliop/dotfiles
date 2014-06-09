#
# ~/.bashrc
#

#echo '*** reading bashrc ***'

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Detect os
os=$(uname)
if [[ $os == 'Darwin' ]]; then
    os='Mac'
fi

# prepare prompt
niceprompt='[\u@\h] \[\e[0;36m\]\W \$ \[\e[0m\]'

function _prompt() {
    PS1="\n`git_prompt`"$niceprompt
}

# Add git info in status bar if available
if [[ -f ~/dev/dotfiles/bash-prompt-git-status ]]; then
    . ~/dev/dotfiles/bash-prompt-git-status
    PROMPT_COMMAND=_prompt
else
    PS1="\n$niceprompt"
fi

# Set autocd on Linux
if [[ $os == 'Linux' ]]; then
    # no more need to type cd
    shopt -s globstar autocd
fi

# Source bash_completion
if [[ $os == 'Mac' ]]; then
    if [ -f $(brew --prefix)/etc/bash_completion ]; then
        . $(brew --prefix)/etc/bash_completion
    fi
else
    if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
        . /etc/bash_completion
    fi
fi

# make autojump work
if [[ $os == 'Mac' ]]; then
    [[ -s `brew --prefix`/etc/autojump.sh ]] && . `brew --prefix`/etc/autojump.sh
else
    . /usr/share/autojump/autojump.sh
fi

# my aliases
if [[ $os == 'Mac' ]]; then
    alias lk='ls -AFBG'
else
    alias ls='ls --color=auto'
    alias lk="ls -AFBG --group-directories-first --ignore='.*.swp'"
fi
alias v='vim'
alias md='mkdir'
alias sudo="sudo "
alias s='eval "sudo $(fc -ln -1)"'
alias ll='lk -l'
alias l='ll'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias tmux='TERM=screen-256color tmux'
alias g='git'
alias gg='git status'
alias t='tmux'
alias h='history -n'
# last one to force re-read of bash history

# bash completion for g as git
complete -o bashdefault -o default -o nospace -F _git g 2>/dev/null \
        || complete -o default -o nospace -F _git g

# vim bindings, yeah!
set -o vi
bind -m vi-insert '"kj": vi-movement-mode' # 'kj' mapped to ESC

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

# git stuff
#if [[ -f ~/.git-completion.bash ]]; then
    #. ~/.git-completion.bash
#fi

# turn off Ctrl + s XOFF (XON is Ctrl + q)
stty ixany
stty ixoff -ixon
stty stop undef
stty start undef

# ssh-agent up and running on Linux
if [[ $os == 'Linux' ]]; then
    SSH_ENV="$HOME/.ssh/environment"

    function start_agent {
         echo "Initialising new SSH agent..."
         /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
         echo succeeded
         chmod 600 "${SSH_ENV}"
         . "${SSH_ENV}" > /dev/null
         /usr/bin/ssh-add;
    }

    # Source SSH settings, if applicable

    if [ -f "${SSH_ENV}" ]; then
         . "${SSH_ENV}" > /dev/null
         ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
             start_agent;
         }
    else
         start_agent;

    fi
fi
