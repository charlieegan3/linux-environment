#!/usr/bin/env bash

# these come first since they are used in the setting of the path
export GOROOT="/usr/local/go"
export GOPATH="$HOME/Code/go"

export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin"
export PATH="$GOPATH/bin:$PATH"
export PATH="$GOROOT/bin:$PATH"
export PATH="$HOME/.rvm/bin:$PATH"
export PATH="$HOME/.npm-packages/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.tfenv/bin:$PATH"
