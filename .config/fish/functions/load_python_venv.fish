function load_python_venv
	set -l local_venv "$HOME/.local/share/local-venv"
	if test ! -d $local_venv
		python3 -m venv $local_venv
	end
	source "$local_venv/bin/activate.fish"
end
