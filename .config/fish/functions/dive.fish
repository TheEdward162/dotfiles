function dive
	# https://github.com/wagoodman/dive is kinda broken 🤷‍♀️
	docker save $argv[1] | command dive docker-tar:///dev/stdin
end
