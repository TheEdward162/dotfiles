if status is-login
	fish_add_path "$HOME/.local/bin"
	fish_add_path "$HOME/.cargo/bin"

	muhsvc login
	if test $(tty) = '/dev/tty1'
		dbus-run-session sway
	end
end
