from util import log, build_rsync_common, run_command, build_host_string

def run_list(args):
	host_string = build_host_string(args)
	log(f"Running list {host_string}:{args.PORT}:{args.PATH} with depth {args.DEPTH} ..", end = "\n\n")

	if args.FIND is True:
		cut_start = len(args.PATH) + 2
		run_command(
			[
				"ssh", "-p", args.PORT, host_string,
				f"find {args.PATH} -maxdepth {args.DEPTH} | cut -c {cut_start}-"
			]
		)
	else:
		color = "never"
		if args.COLOR is True:
			color = "always"
		run_command(
			[
				"ssh", "-p", args.PORT, host_string,
				f"exa --recurse --level {args.DEPTH} --long --all --all --git --color {color} {args.PATH}"
			]
		)

def run_download(args):
	host_string = build_host_string(args)
	log(f"Running download {host_string}:{args.PORT}:{args.SOURCE} to {args.DESTINATION} ..")

	run_command(
		[
			"rsync",
			"--archive", "--update",
			"--progress", "--stats"
		] + build_rsync_common(args) + [
			f"{host_string}:{source}" for source in args.SOURCE
		] + [args.DESTINATION]
	)

def run_upload(args):
	host_string = build_host_string(args)
	log(f"Running upload {args.SOURCE} to {host_string}:{args.PORT}:{args.DESTINATION} ..")

	run_command(
		[
			"rsync",
			"--archive", "--update",
			"--progress", "--stats"
		] + build_rsync_common(args) +
		args.SOURCE + [f"{host_string}:{args.DESTINATION}"]
	)

def run_sync(args):
	host_string = build_host_string(args)
	log(f"Running sync {host_string}:{args.PORT}:{args.REMOTE} and {args.LOCAL} ..")

	print("\nDOWN")
	run_command(
		[
			"rsync",
			"--itemize-changes", "--update"
		] + build_rsync_common(args) + [
			f"{host_string}:{args.REMOTE}", args.LOCAL
		]
	)

	print("\nUPLD")
	run_command(
		[
			"rsync",
			"--itemize-changes", "--update"
		] + build_rsync_common(args) + [
			args.LOCAL, f"{host_string}:{args.REMOTE}"
		]
	)
