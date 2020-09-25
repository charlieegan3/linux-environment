# use vim as the system editor
export VISUAL=vim
export EDITOR="$VISUAL"

# use correct window size
shopt -s checkwinsize

# History
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=1000000
export HISTFILESIZE=100000
shopt -s histappend

# imclude 'modules' from config
source $HOME/.config/bash/aliases.sh
source $HOME/.config/bash/tools.sh
source $HOME/.config/bash/environment.sh

# set prompt, needs things set in aliases
COLOR_RESET="\[$(tput sgr0)\]" COLOR_CYAN="\[$(tput setaf 6)\]" COLOR_GREEN="\[$(tput setaf 2)\]" COLOR_YELLOW="\[$(tput setaf 3)\]"
export PS1="$COLOR_YELLOW\$(last_status_string)$COLOR_CYAN\$(relative_path_to_git_root)$COLOR_RESET $ "

# welcome
echo "hello."
