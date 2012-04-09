#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# make autojump work
source /etc/profile

# my aliases
alias lk="ls -AFBG --ignore='.*.swp'"
alias ll='lk -l'
alias l='ll'
alias tmux='TERM=screen-256color tmux'
alias ls='ls --color=auto'
alias g='git'
alias v='vim'

# add colors
PS1='\[\e[1;32m\][\u@\h \W]\$\[\e[0m\] '

# longer history
HISTFILESIZE=10000
HISTSIZE=10000

# no more need to type cd
shopt -s globstar autocd

# git auto-completion
source ~/.git-completion.bash

# virtualenvwrapper stuff
export WORKON_HOME=~/.virtualenvs
source /usr/bin/virtualenvwrapper.sh

# add my script dir to PATH
PATH=$PATH:/home/gws/dev/scripts/
export PATH

# add node modules dir to PATH
PATH=$PATH:/usr/local/node_modules/.bin
export PATH

# ssh-agent up and running
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
     #ps ${SSH_AGENT_PID} doesn't work under cywgin
     ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
         start_agent;
     }
else
     start_agent;
fi
