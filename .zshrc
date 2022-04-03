# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="robbyrussell"

# Set automatic updates and frequency (days)
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Which plugins would you like to load?
# plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi


# Set personal aliases, overriding those provided by oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

alias g="git"
alias gg="git status"
alias sudo="sudo "  # make aliases work with sudo
alias s='eval "sudo $(fc -ln -1)"'
alias tmux="TERM=screen-256color tmux"
alias t="tmux"
alias v="nvim" 
alias vim="nvim"
alias realvim="vim"

# Other personal customizations

# use ctrl-p and ctrl-o to search history and not Return
bindkey "^p" history-beginning-search-backward
bindkey "^o" history-beginning-search-forward

# PATH adds
export PATH=$PATH:$HOME/dev/scripts     # my personal scripts
