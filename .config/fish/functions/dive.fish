# https://github.com/wagoodman/dive is kinda broken 🤷‍♀️
switch $system_preset
case macos
	function dive
		switch $argv[1]
			case 'localhost/*'
				false
			case '*'
				docker pull $argv[1]
		end
		docker save $argv[1] | pv --bytes --rate --name OCI | command dive docker-tar:///dev/stdin
	end
case linux
	function dive
		podman save $argv[1] | pv --bytes --rate --name OCI | command dive docker-tar:///dev/stdin
	end
end
