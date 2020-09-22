export PATH="$HOME/bin:$PATH"
export ENV="$HOME/.ashrc"

if [ "$(tty)" = '/dev/console' ]; then
	amixer set PCM 100%
	hive
fi
