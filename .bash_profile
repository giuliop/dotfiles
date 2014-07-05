#
# ~/.bash_profile
#

#echo '*** reading bash_profile ***'

# Detect os
os=$(uname)
if [[ $os == 'Darwin' ]]; then
    os='Mac'
fi

# Set environment variables

#Mac vs Linux stuff
if [[ $os == 'Mac' ]]; then
    # homebrew stuff
    PATH=/usr/local/bin:$PATH

    # add golang system bin to PATH
    PATH=$PATH:/usr/local/Cellar/go/1.2.1/libexec/bin
else
    # add golang system bin to PATH
    PATH=$PATH:/usr/local/go/bin
fi

# add haskell executables to path
PATH=~/.cabal/bin:$PATH

# add my script dir to PATH
PATH=$PATH:$HOME/dev/scripts
# add my golang bin dir
PATH=$PATH:$HOME/dev/go/bin

export PATH
export GOPATH=$HOME/dev/go

# Source bashr
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
else
    echo 'No bashrc found'
fi

