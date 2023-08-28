switch $system_preset
case macos
	function load_python
		set -l python_path_prefix '/opt/homebrew/opt/python@'
		set -l python_path_value "$argv[1]/libexec/bin"
		set -l python_path "$python_path_prefix$python_path_value"
		if test -e $python_path
			update_global_kv PATH $python_path_prefix $python_path_value
			set -l python_version (python3 --version | cut -d ' ' -f 2)
			update_global_kv prompt_tags python= $python_version
			return 0
		else
			printf 'Python version %s does not exist\n' $argv[1]
			update_global_kv PATH $python_path_prefix ""
			update_global_kv prompt_tags python= ""
			return 0
		end
	end
end
