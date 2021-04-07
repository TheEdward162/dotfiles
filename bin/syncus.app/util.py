import re
import sys
import subprocess

OUTPUT_SEPARATOR = "\t"

def log(*args, **kwargs):
	print(*args, **kwargs, file = sys.stderr)

def build_host_string(args):
	if args.USER is None:
		return args.HOST
	else:
		return f"{args.USER}@{args.HOST}"

def build_rsync_common(args):
	result = []
	
	if "RECURSIVE" in args and args.RECURSIVE is True:
		result.append("--recursive")
	
	if "DRY_RUN" in args and args.DRY_RUN is True:
		result.append("--dry-run")

	return result + [
		"--exclude", "./git", "--filter", "dir-merge,- .gitignore",
		"--rsh", f"ssh -p {args.PORT} -T -o Compression=no -x",
	]

def run_command(command, stdout_line_cb = None, stdout_encoding = "utf-8"):
	log(f"Running command {command}")

	if stdout_line_cb is not None:
		with subprocess.Popen(command, stdout = subprocess.PIPE) as proc:
			for line in proc.stdout:
				str_line = line.decode(stdout_encoding, errors = "ignore").strip("\n")
				stdout_line_cb(str_line)
	else:
		subprocess.run(
			command,
			check = True
		)

def find(cb, items):
	it = filter(cb, items)
	try:
		return next(it)
	except:
		return None
