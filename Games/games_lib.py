import sys
import yaml
import subprocess

def run_command(command, env = {}, dry_run = False):
	# first join command elements and quote them
	string_command = " ".join(
		map(
			lambda c: f"'{c}'",
			command
		)
	)

	# prepend env
	for key in env.keys():
		if env[key] is None:
			continue
		
		env_string = f"{key}='{env[key]}' "
		string_command = env_string + string_command

	print("Running command:", string_command)
	if not dry_run:
		subprocess.Popen(string_command, shell = True)

def load_presets(path):
	presets = {}
	try:
		with open(path, "r") as file:
			presets = yaml.safe_load(file)
	except IOException as e:
		print(f"Could not load presets file: {e}", file = sys.stderr)
		return {}

	return presets

def save_presets(path, presets):
	try:
		with open(path, "w") as file:
			yaml.dump(presets, file)
	except IOException as e:
		print(f"Could not save presets file: {e}", file = sys.stderr)

def extend(
	base,
	overlay,
	none_overlay = False,
	overwrite_lists = False
):
	"""
	Extends `base` with `overlay` recursively.

	`none_overlay` controls whether `None` in `overlay` should overwrite a value in `base`.
	`overwrite_lists` controls whether nested lists are overwritten instead of extended.
	"""
	def extend_dict(base, overlay):
		keys = overlay.keys()

		for key in keys:
			if key in base:
				base[key] = extend(base[key], overlay[key], none_overlay = none_overlay, overwrite_lists = overwrite_lists)
			else:
				base[key] = overlay[key]
		
		return base
	
	def extend_list(base, overlay):
		if overwrite_lists:
			return overlay
		else:
			return base + overlay

	def extend_other(base, overlay):
		if none_overlay or overlay is not None:
			return overlay
		else:
			return base
	
	if isinstance(base, dict) and isinstance(overlay, dict):
		return extend_dict(base, overlay)
	elif isinstance(base, list) and isinstance(overlay, list):
		return extend_list(base, overlay)
	else:
		return extend_other(base, overlay)
