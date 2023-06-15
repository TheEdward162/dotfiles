alias legit='git'
alias legut='git'

alias ls='exa'
alias ll='exa -laag'
alias yeet='rm -rf'

switch $system_preset
case macos
	alias need='brew install'
	alias begone='brew remove'
	alias has='brew search'

	alias code='codium'
case linux
	alias has='xbps-query -Rs'
	alias has-files='xbps-query --files'
	alias need='sudo xbps-install -S'
	alias needu='need -u'
	alias begone='sudo xbps-remove'

	alias code='code-oss'
end
