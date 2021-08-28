# LEFT PROMPT
local return_color="%(?.%{$fg_bold[green]%}.%{$fg_bold[red]%})"

PROMPT="${return_color}λ%{$reset_color%} "

if [[ -n $SSH_CONNECTION ]]; then
	PROMPT="%{$fg[black]%}%m ${PROMPT}"
fi

# RIGHT PROMPT
local time="${return_color}%*%{$reset_color%}"
RPROMPT="%~ $time"

# NVM version
# if which nvm &> /dev/null; then
# 	local nvm_version=$(nvm current)
# 	RPROMPT="nvm:$nvm_version $RPROMPT"
# else
# 	RPROMPT="$(nvm current) $RPROMPT"
# fi

# git
local git_info='$(git_prompt_status)%{$reset_color%}$(git_prompt_info)%{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}✚ "
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[blue]%}✹ "
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}✖ "
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[magenta]%}➜ "
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[yellow]%}═ "
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%}✭ "

RPROMPT="$git_info $RPROMPT"

DISABLE_LS_COLORS=true
