if test "$(uname)" = Darwin
	set --universal system_preset macos
else
	set --universal system_preset linux
end
