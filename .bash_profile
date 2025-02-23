#
# ~/.bash_profile
#


# add my script dir to PATH
PATH=$PATH:$HOME/dev/scripts
# add my golang bin dir to PATH
PATH=$PATH:$HOME/dev/go/bin
# add python binaries to PATH
PATH=$PATH:$HOME/.local/bin

export PATH

export GOPATH=$HOME/dev/go
export ALGORAND_DATA=/var/lib/algorand_testnet
#export ALGORAND_DATA=/var/lib/algorand
export NODE_PATH=/usr/local/lib/node_modules

# Source bashr
if [ -f ~/.bashrc ]; then
    source "$HOME/.bashrc"
else
    echo 'No bashrc found'
fi

source "$HOME/.cargo/env"
