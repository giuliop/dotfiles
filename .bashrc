#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# my aliases
alias lk='ls -AFBG --color'
alias tmux='TERM=screen-256color tmux'
alias ls='ls --color=auto'

# add colors
PS1='\[\e[1;32m\][\u@\h \W]\$\[\e[0m\] '

# git stuff
source ~/.git-completion.bash

# virtualenvwrapper stuff
export WORKON_HOME=~/.virtualenvs
source /usr/bin/virtualenvwrapper.sh
