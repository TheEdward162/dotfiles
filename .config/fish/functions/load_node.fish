switch $system_preset
case macos
	function load_node
		set -l node_path "/opt/homebrew/opt/node@$argv[1]/bin"
		if test -e $node_path
			fish_add_path -P $node_path
			set -l node_version (string match --regex --groups-only 'v(.+)' "$(node -v)")
			add_prompt_tags "node=$node_version"
			return 0
		else
			printf 'Node version %s does not exist\n' $argv[1]
			return 1
		end
	end
end
