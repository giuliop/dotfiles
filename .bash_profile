#
# ~/.bash_profile
#

echo ''
echo '*** reading bash_profile ***'
echo ''

# Detect os
os=$(uname)
if [[ $os == 'Darwin' ]]; then
    os='Mac'
fi

# Set environment variables

#Mac vs Linux stuff
if [[ $os == 'Mac' ]]; then
    # homebrew stuff
    export PATH=/usr/local/bin:$PATH
    export PATH=/usr/local/share/python:$PATH

    # virtualenv stuff
    export WORKON_HOME=$HOME/.virtualenvs
    source /usr/local/share/python/virtualenvwrapper.sh

    # add golang system bin to PATH
    # ****** add proper PATH ****************************************************
else
    # virtualenv stuff
    #export WORKON_HOME=$HOME/.virtualenvs
    #source /usr/bin/virtualenvwrapper.sh

    # add golang system bin to PATH
    PATH=$PATH:/usr/lib/go/bin
fi

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

