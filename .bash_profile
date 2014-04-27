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

    #bash completion
      if [ -f $(brew --prefix)/etc/bash_completion ]; then
          . $(brew --prefix)/etc/bash_completion
      fi

    # haskell
    PATH=~/.cabal/bin:$PATH

    # add golang system bin to PATH
    PATH=$PATH:/usr/local/Cellar/go/1.2.1/libexec/bin
else

    # add golang system bin to PATH
    PATH=$PATH:/usr/lib/go/bin

    # add gae-go dir to PATH
    PATH=$PATH:~/dev/gae-go/go_appengine
fi

# add my script dir to PATH
PATH=$PATH:$HOME/dev/scripts
# add my golang bin dir
PATH=$PATH:$HOME/dev/go/ext/bin:$HOME/dev/go/mygo/bin

export PATH
export GOPATH=$HOME/dev/go/ext:$HOME/dev/go/mygo


# Source bashr
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
else
    echo 'No bashrc found'
fi

