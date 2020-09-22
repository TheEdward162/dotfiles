# The following lines were added by compinstall

zstyle ':completion:*' completer _complete _ignored
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'l:|=* r:|=*'
zstyle :compinstall filename '/home/rasbpi/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
# Lines configured by zsh-newuser-install
HISTFILE=/dev/null
HISTSIZE=10
SAVEHIST=0
bindkey -e
# End of lines configured by zsh-newuser-install

alias need='sudo apk add --interactive'
alias begone='sudo apk del --interactive'
alias has='apk search'

alias laag='exa -laag'

$HOME/bin/initscripts xdg_dir
export XDG_RUNTIME_DIR="/tmp/$(id -u)-runtime-dir"

PROMPT='%F{yellow}%2~%f %B%#%b '
RPROMPT='%F{green}%*'
