function fish_prompt
    set -l last_status $status
    
    printf '%s%s' (set_color yellow) (pwd)

    set_color cyan
    set -g __fish_git_prompt_showdirtystate
    fish_git_prompt

    if test $last_status -eq 0
        set_color --bold green
    else
        set_color --bold red
    end
    printf ' λ%s ' (set_color normal) 
end

function fish_right_prompt
    set -l last_status $status
    
    printf '[%s] ' $last_status
    set_color green
    date +'%H:%M:%S'
    set_color normal
end
