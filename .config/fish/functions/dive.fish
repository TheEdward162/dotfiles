function dive
	# https://github.com/wagoodman/dive is kinda broken 🤷‍♀️
	docker pull $argv[1] || true
	docker save $argv[1] | pv --bytes --rate --name OCI | command dive docker-tar:///dev/stdin
end
