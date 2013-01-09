if [ -f ~/.bashrc ]; then
    source ~/.bashrc
else
    echo 'No bashrc found'
fi

if [ -f ~/dev/dotfiles/bash-prompt-git-status ]; then
    source ~/dev/dotfiles/bash-prompt-git-status
fi
