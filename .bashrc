#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# my aliases
alias lk='ls -AFBG --ignore='.*.swp' --color'
alias ll='lk -l'
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

# git stuff
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
