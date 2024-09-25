if status is-interactive
	# Commands to run in interactive sessions can go here
end

function fish_greeting
	set joke (curl --silent --max-time 1 -H "Accept: text/plain" https://icanhazdadjoke.com/ || fortune)
	echo $joke | cowsay -f moose.cow | lolcat
end

direnv hook fish | source
