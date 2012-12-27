#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Detect os
os=$(uname)
if [[ $os == 'Darwin' ]]; then
    os='Mac'
fi

# Mac vs Linux stuff
if [[ $os == 'Mac' ]]; then
    # homebrew stuff
    export PATH=/usr/local/bin:$PATH
    export PATH=/usr/local/share/python:$PATH
else
    # no more need to type cd
    shopt -s globstar autocd

    # add node modules dir to PATH
    PATH=$PATH:/usr/local/node_modules/.bin
    export PATH
fi

# virtualenv stuff
export WORKON_HOME=$HOME/.virtualenvs
if [[ $os == 'Mac' ]]; then
    source /usr/local/share/python/virtualenvwrapper.sh
else
    source /usr/bin/virtualenvwrapper.sh
fi

# make autojump work
if [[ $os == 'Mac' ]]; then
    [[ -s `brew --prefix`/etc/autojump.sh ]] && . `brew --prefix`/etc/autojump.sh
else
    source /etc/profile
fi

# my aliases
export gwslinode=gws@178.79.141.51
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
alias ll='lk -l'
alias l='ll'
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
HISTFILESIZE=10000
HISTSIZE=1000

# add colors
PS1='\[\e[1;32m\][\u@\h \W]\$\[\e[0m\] '

# git stuff
source ~/.git-completion.bash

# add my script dir to PATH
PATH=$PATH:$HOME/dev/scripts/
export PATH

# turn off Ctrl + s XOFF (XON is Ctrl + q)
stty ixany
stty ixoff -ixon
stty stop undef
stty start undef

# ssh-agent up and running on Linux
if [[ $os == 'Linux;' ]]; then
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
