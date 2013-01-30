#
# ~/.bashrc
#

echo ''
echo '*** reading bashrc ***'
echo ''

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Detect os
os=$(uname)
if [[ $os == 'Darwin' ]]; then
    os='Mac'
fi

# add colors
PS1='\[\e[0;36m\][\u@\h \W]\$\[\e[0m\] '

# Add git info in status bar
if [[ -f ~/dev/dotfiles/bash-prompt-git-status ]]; then
    . ~/dev/dotfiles/bash-prompt-git-status
fi

# Set autocd on Linux
if [[ $os == 'Linux' ]]; then
    # no more need to type cd
    shopt -s globstar autocd
fi

# make autojump work
if [[ $os == 'Mac' ]]; then
    [[ -s `brew --prefix`/etc/autojump.sh ]] && . `brew --prefix`/etc/autojump.sh
else
    . /usr/share/autojump/autojump.sh
fi

# my aliases
if [[ $os == 'Mac' ]]; then
    alias ggmongod='mongod run --config /usr/local/Cellar/mongodb/2.0.4-x86_64/mongod.conf'
    alias vim='mvim -v'
    alias v='mvim -v'
    alias lk='ls -AFBG'
else
    alias ls='ls --color=auto'
    alias lk="ls -AFBG --ignore='.*.swp'"
    alias v='vim'
fi

alias sudo="sudo "
alias s='eval "sudo $(fc -ln -1)"'
alias ll='lk -l'
alias l='ll'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias tmux='TERM=screen-256color tmux'
alias g='git'
alias gs='git status'
alias t='tmux'
alias h='history -n'
# last one to force re-read of bash history

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
if [[ -f ~/.git-completion.bash ]]; then
    . ~/.git-completion.bash
fi

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

