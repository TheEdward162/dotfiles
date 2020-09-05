#!/bin/env python3

import os
import sys
import yaml
import os.path
import argparse
import subprocess

GAMES_PATH = "/mnt/storage/edward/Games"
RUNNERS_PATH = f"{GAMES_PATH}/lutris-wines"
PRESETS_FILE = "presets.yaml"
PROTON_LAYER = f"{GAMES_PATH}/proton_layer"

## LISTING ##

def list_runners():
	runners = []
	
	for entry in os.listdir(RUNNERS_PATH):
		full_path = os.path.join(RUNNERS_PATH, entry)
		if os.path.isdir(full_path):
			runners.append(entry)

	def runner_key(runner):
		split = runner.split("-")
		if len(split) < 3:
			return (runner,)
		
		arch = split.pop()

		# version
		version = split.pop()
		version_patch = 0

		if version.find('.') == -1:
			try:
				version_patch = int(version)
			except:
				pass
			version = split.pop()

		name = '-'.join(split)
		try:
			version = version.split(".")
			version_major = int(version[0])
			version_minor = int(version[1])

			return (arch, version_major, version_minor, version_patch, name)
		except:
			return (arch, version, 0, version_patch, name)
	
	return sorted(runners, key = runner_key, reverse = True)

def list_wineprefixes():
	prefixes = []

	for entry in os.listdir(GAMES_PATH):
		full_path = os.path.join(GAMES_PATH, entry)
		system_reg_path = os.path.join(full_path, "system.reg")
		windows_path = os.path.join(full_path, "drive_c", "windows")

		if os.path.isdir(full_path) and os.path.isfile(system_reg_path) and os.path.isdir(windows_path):
			prefixes.append(entry)
	
	return prefixes

## INPUT ##

def show_selection(array, intro_text = "Available:", input_text = "Select", default = None):
	result = None
	if default is not None:
		input_text = "{} ({}): ".format(input_text, default)
	else:
		input_text = "{}: ".format(input_text)

	while True:
		print(intro_text)
		for i in range(0, len(array)):
			print("\t{}: {}".format(i, array[i]))
		
		selected = input(input_text)
		if selected == "" and default is not None:
			selected = default

		if selected in array:
			result = array[array.index(selected)]
			break
		else:
			try:
				index = int(selected)
				result = array[index]
				break
			except:
				pass
	
	return result

def load_presets():
	presets = {}
	try:
		with open(PRESETS_FILE, "r") as file:
			presets = yaml.safe_load(file)
	except:
		return {}

	return presets

def save_presets(presets):
	try:
		with open(PRESETS_FILE, "w") as file:
			yaml.dump(presets, file)
	except IOException as e:
		print("Could not save presets file: {}".format(e), file = sys.stderr)

def pick_generic(value, preset, key, values, intro_text, selection_text):
	if value is None:
		if preset is not None and key in preset:
			value = preset[key]
		else:
			return show_selection(
				values,
				intro_text,
				selection_text,
				default = 0
			)
	
	if value not in values:
		value = show_selection(
			values,
			intro_text,
			selection_text,
			default = 0
		)

	return value

def pick_prefix(prefix, preset = None):
	return pick_generic(prefix, preset, "prefix", list_wineprefixes(), "Available prefixes:", "Select a prefix")

def pick_runner(runner, preset = None):
	return pick_generic(runner, preset, "runner", list_runners(), "Available runners:", "Select a runner")

## COMMANDS ##

def finalize_command(prefix, runner, command, info):
	if info["preset"] is not None and info["save_preset"] is True:
		presets = load_presets()

		prst = {
			"prefix": info["prefix"],
			"runner": info["runner"],
			"command": info["command"]
		}
		if info["arch"] is not None:
			prst["arch"] = info["arch"]
		if info["esync"] is not None:
			prst["esync"] = info["esync"]
		if len(info["env"]) > 0:
			prst["env"] = info["env"]


		presets[info["preset"]] = prst
		save_presets(presets)
	
	cmd = ""

	if info["esync"] is not None:
		cmd = "WINEESYNC={} ".format(int(info["esync"]))
	if info["arch"] is not None:
		cmd = "{}WINEARCH={} ".format(cmd, info["arch"])
	if len(info["env"]) > 0:
		cmd = "{}{} ".format(cmd, " ".join(info["env"]))
	
	cmd = "{}WINEPREFIX='{}' {} ".format(cmd, prefix, runner)
	if command is not None:
		cmd += " ".join(map(
			lambda c: f"'{c}'",
			command
		))

	return cmd

def run_command(command):
	print("Running command", command)
	subprocess.Popen(command, shell = True)

def create_new(info):
	full_prefix = os.path.join(GAMES_PATH, info["prefix"])

	try:
		os.mkdir(full_prefix)
	except FileExistsError:
		print("Error, folder {} already exists.".format(full_prefix), file = sys.stderr)
		return False
	
	info["runner"] = pick_runner(info["runner"])
	full_runner = os.path.join(RUNNERS_PATH, info["runner"], "bin", "wineboot")

	command = finalize_command(full_prefix, full_runner, info["command"], info)

	run_command(command)
	return True

def run_trick(info):
	info["prefix"] = pick_prefix(info["prefix"])
	info["runner"] = pick_runner(info["runner"])

	full_prefix = os.path.join(GAMES_PATH, info["prefix"])
	full_runner = os.path.join(RUNNERS_PATH, info["runner"], "bin", "wine")

	command = finalize_command(
		full_prefix,
		"WINE='{}' winetricks".format(full_runner),
		info["command"],
		info
	)

	run_command(command)
	return True

def run(info):
	info["prefix"] = pick_prefix(info["prefix"])
	info["runner"] = pick_runner(info["runner"])

	full_prefix = os.path.join(GAMES_PATH, info["prefix"])
	full_runner = os.path.join(RUNNERS_PATH, info["runner"], "bin", "wine")

	command = finalize_command(
		full_prefix,
		full_runner,
		info["command"],
		info
	)

	run_command(command)
	return True

def run_proton(info):
	## Wine debug logging
	# "WINEDEBUG": "+timestamp,+pid,+tid,+seh,+debugstr,+loaddll,+mscoree"
	
	## DXVK debug logging
	# "DXVK_LOG_LEVEL": "info"
	
	## vkd3d debug logging
	# "VKD3D_DEBUG": "warn"

	## wine-mono debug logging (Wine's .NET replacement)
	# "WINE_MONO_TRACE": "E:System.NotImplementedException"
	# "MONO_LOG_LEVEL": "info"

	## Enable DXVK's HUD
	# "DXVK_HUD": "devinfo,fps"

	## Use OpenGL-based wined3d for d3d11 and d3d10 instead of Vulkan-based DXVK
	# "PROTON_USE_WINED3D": "1"

	## Use Vulkan-based D9VK instead of OpenGL-based wined3d for d3d9.
	# "PROTON_USE_D9VK": "1"

	## Disable d3d11 entirely
	# "PROTON_NO_D3D11": "1"

	## Disable eventfd-based in-process synchronization primitives
	# "PROTON_NO_ESYNC": "1"

	## Disable futex-based in-process synchronization primitives
	# "PROTON_NO_FSYNC": "1"

	pfx_path = os.path.join(PROTON_LAYER, "pfx")
	prefix_path = os.path.join(GAMES_PATH, info["prefix"])
	run_command(f"ln --force --symbolic --no-target-directory '{prefix_path}' '{pfx_path}'")

	runner_path = os.path.join(info["runner"], "proton")

	command = ""
	if info["esync"] is not None:
		command = "PROTON_NO_ESYNC={} ".format(int(not info["esync"]))
	if len(info["env"]) > 0:
		command = "{}{} ".format(command, " ".join(info["env"]))

	command = command + f"STEAM_COMPAT_DATA_PATH={PROTON_LAYER} '{runner_path}' run "
	command += " ".join(map(
		lambda c: f"'{c}'",
		info["command"]
	))

	run_command(command)
	return True

## CLI AND ORCHESTRATION ##

# games.py [--new] [--tricks] [--prefix PREFIX] [--runner RUNNER] [--arch ARCH] [--esync ESYNC] [--preset PRESET] [--save-preset] [--proton] [COMMAND]
def define_cli_parser():
	parser = argparse.ArgumentParser(description = "Runs wine prefixes")

	parser.add_argument(
		"-n", "--new", dest = "NEW",
		default = None, required = False,
		help = "Create a new prefix in the game directory."
	)

	parser.add_argument(
		"-p", "--prefix", dest = "PREFIX",
		default = None, required = False,
		help = "Name of the prefix to use, relative to the game directory."
	)

	parser.add_argument(
		"-r", "--runner", dest = "RUNNER",
		default = None, required = False,
		help = "Runner to use."
	)

	parser.add_argument(
		"-t", "--tricks", dest = "TRICKS",
		default = False, required = False,
		action = "store_const", const = True,
		help = "Use winetricks with provided command instead of wine."
	)

	parser.add_argument(
		"-a", "--arch", dest = "ARCH",
		default = None, required = False,
		choices = ["win32", "win64"],
		help = "Architecture to use."
	)

	parser.add_argument(
		"-e", "--esync", dest = "ESYNC",
		default = None, required = False,
		choices = [True, False], type = bool,
		help = "Set whether or not to use esync (if available)."
	)

	parser.add_argument(
		"-s", "--preset", dest = "PRESET",
		default = None, required = False,
		help = "Preset to use, if it exists."
	)

	parser.add_argument(
		"--save-preset", dest = "SAVE_PRESET",
		default = False, required = False,
		action = "store_const", const = True,
		help = "Save preset before launching."
	)

	parser.add_argument(
		"--proton", dest = "PROTON",
		default = None, required = False,
		choices = [True, False], type = bool,
		help = "Use proton to execute command. Note that runner needs to be specified manually right now."
	)

	parser.add_argument(
		"COMMAND",
		nargs = "*",
		help = "Command to run in the prefix (default explorer.exe)."
	)

	return parser

def extend_info(info, preset, keys, overwrite = False):
	def is_empty(v):
		if v is None:
			return True

		if isinstance(v, list) and len(v) == 0:
			return True
		
		return False
	
	for key in keys:
		if key in preset and preset[key] is not None and (overwrite or is_empty(info[key])):
			info[key] = preset[key]

def main():
	cli_parser = define_cli_parser()
	args = cli_parser.parse_args()
	if args.COMMAND == []:
		args.COMMAND = None

	print("Args:", args, file = sys.stderr)

	info = {
		"prefix": args.PREFIX,
		"runner": args.RUNNER,
		"command": args.COMMAND,

		"arch": args.ARCH,
		"esync": args.ESYNC,

		"preset": args.PRESET,
		"save_preset": args.SAVE_PRESET,
		"env": []
	}
	if args.PRESET is not None:
		presets = load_presets()
		if args.PRESET in presets:
			preset = presets[args.PRESET]

			extend_info(info, preset, ["prefix", "runner", "command", "arch", "esync", "env"])
		else:
			print(f"Warning, could not find preset {args.PRESET}", file = sys.stderr)
	
	if info["command"] is None:
		info["command"] = ["explorer.exe"]
	elif not isinstance(info["command"], list):
		info["command"] = [info["command"]]

	print("Info:", info, file = sys.stderr, end = "\n\n")

	if args.NEW is not None:
		info["prefix"] = args.NEW
		return create_new(info)
	elif args.TRICKS is True:
		return run_trick(info)
	elif args.PROTON is True:
		return run_proton(info)
	else:
		return run(info)

main()

