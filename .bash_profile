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
    PATH=/usr/local/share/python:$PATH

    # add golang system bin to PATH
    PATH=$PATH:/usr/local/Cellar/go/1.0.3/bin

    # virtualenv stuff
    export WORKON_HOME=$HOME/.virtualenvs
    source /usr/local/share/python/virtualenvwrapper.sh
else
    # virtualenv stuff
    #export WORKON_HOME=$HOME/.virtualenvs
    #source /usr/bin/virtualenvwrapper.sh

    # add golang system bin to PATH
    PATH=$PATH:/usr/lib/go/bin

    # add gae-go dir to PATH
    PATH=$PATH:~/dev/gae-go/google_appengine
fi

# add my script dir to PATH
PATH=$PATH:$HOME/dev/scripts
# add my golang bin dir
PATH=$PATH:$HOME/dev/go/bin

export PATH
export GOPATH=$HOME/dev/go/ext:$HOME/dev/go/mygo


# Source bashr
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
else
    echo 'No bashrc found'
fi

