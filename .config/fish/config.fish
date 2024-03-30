if status is-interactive
	# Commands to run in interactive sessions can go here
end

function fish_greeting
	fortune | cowsay -f moose.cow | lolcat
end

direnv hook fish | source
