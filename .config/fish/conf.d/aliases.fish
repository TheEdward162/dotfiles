alias legit='git'
alias legut='git'

alias ls='eza'
alias ll='eza -laag'
alias yeet='rm -rf'
alias bat='bat --theme ansi'

set --universal --export EDITOR nano

switch $system_preset
case macos
	alias need='brew install'
	alias begone='brew remove'
	alias has='brew search'

	alias code='codium'
case linux
	alias has='/sbin/apk search'
	alias need='doas /sbin/apk add'
	alias needu='doas sh -c \'apk update && apk upgrade\''
	alias begone='doas /sbin/apk del'

	alias code='code-oss'

	alias reboot='doas /sbin/reboot'
	alias poweroff='doas /sbin/poweroff'
	alias zzz='doas /usr/sbin/zzz'
end
