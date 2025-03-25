if status is-login
	switch $system_preset
	case macos
		fish_add_path /opt/homebrew/bin
		fish_add_path /Users/edward/.cargo/bin
		fish_add_path /Users/edward/.local/bin

		fish_add_path /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin
		fish_add_path /opt/homebrew/opt/fzf/bin
		fish_add_path /opt/homebrew/opt/openjdk@17/bin
	case linux
		fish_add_path "$HOME/.local/bin"
		fish_add_path "$HOME/.cargo/bin"

		set --export REQUESTS_CA_BUNDLE /etc/ssl/certs/ca-certificates.crt

		set -x XDG_RUNTIME_DIR "/tmp/$USER"
		muhsvc login
		if test $(tty) = '/dev/tty1'
			dbus-run-session sway
		end
	end
end
