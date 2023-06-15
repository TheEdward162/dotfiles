function fish_prompt
	set -g __fish_git_prompt_showdirtystate	1
	set -g __fish_git_prompt_showuntrackedfiles 1
	
	set -l last_status $status
	if test $last_status -eq 0
		set -f lambda_color 'green'
	else
		set -f lambda_color 'red'
	end

	set -f path_overrides (string join ',' $override_node_version $override_java_version)
	if test -n "$path_overrides"
		set -f path_overrides " {$path_overrides}"
	end

	printf '%s%s%s%s%s%s %sλ%s ' (set_color yellow) $PWD (set_color --bold white) "$(fish_git_prompt)" (set_color magenta) "$path_overrides" (set_color --bold green) (set_color normal)
end

function fish_right_prompt
	set -l last_status $status
	
	printf '[%s] ' $last_status
	set_color green
	date +'%H:%M:%S'
	set_color normal
end

