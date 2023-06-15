function fish_prompt
	set -l last_status $status

	set -g __fish_git_prompt_showdirtystate	1
	set -g __fish_git_prompt_showuntrackedfiles 1
	
	set -f lambda_colors green red
	if fish_is_root_user
		set -f lambda_colors magenta red
	end

	if test $last_status -eq 0
		set -f lambda_color $lambda_colors[1]
	else
		set -f lambda_color $lambda_colors[2]
	end

	set -f tags (string join ',' $prompt_tags)
	if test -n "$tags"
		set -f tags " {$tags}"
	end

	printf "$(set_color yellow)$PWD""$(set_color --bold white)$(fish_git_prompt)$(set_color normal)""$(set_color white)$tags$(set_color normal)""$(set_color --bold green) λ$(set_color normal) "
end

function fish_right_prompt
	set -l last_status $status
	
	printf '[%s] ' $last_status
	set_color green
	date +'%H:%M:%S'
	set_color normal
end

