if test "$(uname)" = Darwin
	set -u system_preset macos
else
	set -u system_preset linux
end

if status is-interactive
	# Commands to run in interactive sessions can go here
end

function fish_greeting
	
end
