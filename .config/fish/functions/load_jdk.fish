switch $system_preset
case macos
	function load_jdk
		set -l java_path "/opt/homebrew/opt/openjdk@$argv[1]/bin"
		if test -e $java_path
			fish_add_path -P $java_path
			set -l java_version (string match --regex --groups-only 'openjdk version "([^"]+)"' "$(java -version 2>&1)")
			add_prompt_tags "jdk=$java_version"
			return 0
		else
			printf 'OpenJDK version %s does not exist\n' $argv[1]
			return 1
		end
	end
end
