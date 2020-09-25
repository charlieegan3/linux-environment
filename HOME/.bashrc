# use vim as the system editor
export VISUAL=vim
export EDITOR="$VISUAL"

# use correct window size
shopt -s checkwinsize

# aliases & functions
alias ls='ls --color=always --file-type'
alias pbcopy='wl-copy'
alias pbpaste='wl-paste'

jj() {
  cd $(j -l | awk '{ print $2 }' | fzf)
}
replace_in_folder() {
  find $PWD -type f -not -iwholename '*.git*' -exec sed -i "s/$1/$2/g" {} \;
}
serve() {
  firefox http://localhost:8000 && ruby -run -ehttpd "$1" -p8000
}
kns() {
  local ns=$(kubectl get ns --output=custom-columns=name:.metadata.name --no-headers=true | fzf)
  kubens $ns && echo $ns > ~/.kube/namespace
}
heic_jpg() {
  for f in *.heic; do heif-convert $f $f.jpg; done
}
last_status_string() {
  last_exit="$?"
  if [ "$last_exit" != "0" ]; then echo -n "[$last_exit]"; fi
}
relative_path_to_git_root() {
  path1=$(git root) path2=$(pwd)
  common=$(printf '%s\x0%s' "${path1}" "${path2}" | sed 's/\(.*\).*\x0\1.*/\1/')
  relative_path="${path2/$common/}"
  if  [ $path1 == "$HOME" ]; then
    echo -n "${PWD##*/}";
  elif [ "${#relative_path}" == "0" ]; then
    echo -n "${PWD##*/}";
  else
    if [ ${#relative_path} -ge 20 ]; then
      relative_path="...$(echo $relative_path | rev | cut -c 1-20 | rev)"
    fi
    echo -n "$relative_path";
  fi
}
permissions() {
  sudo find . -type d -exec chmod 0755 {} \;
  sudo find . -type f -exec chmod 0644 {} \;
  sudo find . -type f -iname "*.sh" -exec chmod +x {} \;
}
morning() {
  new_date="$(ruby -e "require 'time'; secs = ((Time.now.hour.to_f / 24) * 120 * 60).to_i;   puts (Time.parse(Time.now.strftime('%Y-%m-%d') + ' 07:00:00 +0100') + secs).strftime('%a %d %b %Y 07:19:43 %Z');")"
  GIT_COMMITTER_DATE=$new_date git commit --date "$new_date"
}
envrc() {
  sudo cat .envrc
  sudo chattr -i .envrc
  vi .envrc
  direnv allow
  sudo chattr +i .envrc
}
gitcd() {
  cd $(git rev-parse --show-toplevel)
}
dropbox() {
  ruby /etc/scripts/dropbox_explorer.rb
}
# TODO find a nicer place for these
alias gitb="git branch | grep '^\*' | cut -d' ' -f2 | tr -d '\n'"
bran() {
  echo "Current: " $(gitb)
  git checkout $(git b | sed -e 's/^..//' | fzf)
}

# Environments
export GOROOT="/usr/local/go"
export GOPATH="$HOME/Code/go"

export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin"
export PATH="$GOPATH/bin:$PATH"
export PATH="$GOROOT/bin:$PATH"
export PATH="$HOME/.rvm/bin:$PATH"
export PATH="$HOME/.npm-packages/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.tfenv/bin:$PATH"
[[ -e $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm

# Tools
[ -f /usr/share/fzf/shell/key-bindings.bash ] && source /usr/share/fzf/shell/key-bindings.bash
export _Z_CMD=j
source $HOME/.local/bin/zed.sh
if [ -f "$(which direnv || true)" ]; then
  eval "$(direnv hook bash)"
fi
if [ -d "/usr/share/google-cloud-sdk" ]; then
  source /usr/share/google-cloud-sdk/completion.bash.inc
fi
if [ -d "$HOME/google-cloud-sdk" ]; then
  source "$HOME/google-cloud-sdk/path.bash.inc"
  source "$HOME/google-cloud-sdk/completion.bash.inc"
fi
if [ -e "$(which kubectl 2>/dev/null)" ]; then
  source <(kubectl completion bash)
fi

# History
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=1000000
export HISTFILESIZE=100000
shopt -s histappend

# GPG
export GPG_TTY=`tty`
export GPG_AGENT_INFO

# set prompt
COLOR_RESET="\[$(tput sgr0)\]" COLOR_CYAN="\[$(tput setaf 6)\]" COLOR_GREEN="\[$(tput setaf 2)\]" COLOR_YELLOW="\[$(tput setaf 3)\]"
export PS1="$COLOR_YELLOW\$(last_status_string)$COLOR_CYAN\$(relative_path_to_git_root)$COLOR_RESET $ "

# welcome
echo "hello."
