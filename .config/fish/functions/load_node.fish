switch $system_preset
case macos
	function load_node
		set -l node_path_prefix '/opt/homebrew/opt/node@'
		set -l node_path_value "$argv[1]/bin"
		set -l node_path "$node_path_prefix$node_path_value"
		if test -e $node_path
			update_global_kv PATH $node_path_prefix $node_path_value
			set -l node_version (string match --regex --groups-only 'v(.+)' "$(node -v)")
			update_global_kv prompt_tags node= $node_version
			return 0
		else
			printf 'Node version %s does not exist\n' $argv[1]
			update_global_kv PATH $node_path_prefix ""
			update_global_kv prompt_tags node= ""
			return 1
		end
	end
end
