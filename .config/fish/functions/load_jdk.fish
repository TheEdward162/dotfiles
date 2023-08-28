switch $system_preset
case macos
	function load_jdk
		set -l java_path_prefix '/opt/homebrew/opt/openjdk@'
		set -l java_path_value "$argv[1]/bin"
		set -l java_path "$java_path_prefix$java_path_value"
		if test -e $java_path
			update_global_kv PATH $java_path_prefix $java_path_value
			set -l java_version (string match --regex --groups-only 'openjdk version "([^"]+)"' "$(java -version 2>&1)")
			update_global_kv prompt_tags jdk= $java_version
			return 0
		else
			printf 'OpenJDK version %s does not exist\n' $argv[1]
			update_global_kv PATH $java_path_prefix ""
			update_global_kv prompt_tags jdk= ""
			return 1
		end
	end
end
