alias has='emerge --search'
alias has-flags='equery uses'
alias has-files='equery files --tree'
alias need='doas emerge --ask --jobs --load-average 12.0 --quiet-build'
alias needu='need --update --deep --newuse --with-bdeps=y @world'
alias begone='doas emerge --ask --depclean'

alias legit='git'
alias legut='git'

alias ls='exa'
alias ll='exa -la'
alias laag='exa -laag'
alias yeet='rm -rf'
