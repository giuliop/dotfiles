# homebrew stuff
export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/share/python:$PATH

# virtualenv stuff
WORKON_HOME=$HOME/.virtualenvs
source /usr/local/share/python/virtualenvwrapper.sh

# my aliases
alias lk='ls -AFBG'
alias ll='lk -l'
alias l='ll'
alias tmux='TERM=screen-256color tmux'
alias g='git'
alias v='vim'
alias t='tmux'
alias ggmongod='mongod run --config /usr/local/Cellar/mongodb/2.0.0-x86_64/mongod.conf'
alias gwslinode='gws@@178.79.141.51'

# longer history
HISTFILESIZE=10000
HISTSIZE=1000

# no more need to type cd
#shopt -s globstar autocd

# add colors
PS1='\[\e[1;32m\][\u@\h \W]\$\[\e[0m\] '

# git stuff
source ~/.git-completion.bash

# make autojump work
if [ -f `brew --prefix`/etc/autojump ]; then
    . `brew --prefix`/etc/autojump
fi
