#!/bin/env python3

import os
import sys
import copy
import os.path
import argparse

import games_lib

GAMES_PATH = "/mnt/big/edward/Games"
PROTON_LAYER_PATH = os.path.join(GAMES_PATH, "proton_layer")
PRESETS_PATH = os.path.join(GAMES_PATH, "dot", "presets.yaml")

STEAM_CLIENT_PATH = "/home/edward/.local/share/Steam"
STEAM_COMMON_PATH = "/mnt/big/edward/Steam/steamapps/common"

DEFAULT_INFO = {
	"prefix": None,
	"runner": None,
	"command": ["explorer.exe"],
	"esync": None,
	"env": {},
	"dry_run": False
}

def prepare_layer(info):
	wine_prefix_path = os.path.join(PROTON_LAYER_PATH, "pfx")

	games_lib.run_command(
		[
			"ln",
			"--force",
			"--symbolic",
			"--no-target-directory",
			os.path.join(GAMES_PATH, info["prefix"]),
			wine_prefix_path
		],
		dry_run = info["dry_run"]
	)

	return wine_prefix_path

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

	prepare_layer(info)

	runner_path = os.path.join(STEAM_COMMON_PATH, info["runner"], "proton")

	base_env = {
		"STEAM_COMPAT_CLIENT_INSTALL_PATH": STEAM_CLIENT_PATH,
		"STEAM_COMPAT_DATA_PATH": PROTON_LAYER_PATH,
	}
	if info["esync"] is not None:
		base_env["PROTON_NO_ESYNC"] = int(not info["esync"])

	games_lib.run_command(
		[
			runner_path,
			"run"
		] + info["command"],
		env = games_lib.extend(
			base_env,
			info["env"]
		),
		dry_run = info["dry_run"]
	)

def run_raw(info):
	wine_prefix_path = prepare_layer(info)

	wine_bin_path = os.path.join(STEAM_COMMON_PATH, info["runner"], "dist", "bin")

	games_lib.run_command(
		[
			os.path.join(wine_bin_path, "wine")
		] + info["command"],
		env = games_lib.extend(
			{
				"WINEPREFIX": wine_prefix_path,
				"WINESERVER": os.path.join(wine_bin_path, "wineserver")
			},
			info["env"]
		),
		dry_run = info["dry_run"]
	)

def run_tricks(info):
	wine_prefix_path = prepare_layer(info)

	wine_bin_path = os.path.join(STEAM_COMMON_PATH, info["runner"], "dist", "bin")

	games_lib.run_command(
		[
			"winetricks"
		] + info["command"],
		env = games_lib.extend(
			{
				"WINEPREFIX": wine_prefix_path,
				"WINE": os.path.join(wine_bin_path, "wine"),
				"WINESERVER": os.path.join(wine_bin_path, "wineserver")
			},
			info["env"]
		),
		dry_run = info["dry_run"]
	)

def main():
	cli_parser = define_cli_parser()
	args = cli_parser.parse_args()

	print("Args:", args, file = sys.stderr)

	args.handler_func(args)

def resolve_info(args):
	info = copy.deepcopy(DEFAULT_INFO)

	if args.PRESET is not None:
		presets = games_lib.load_presets(PRESETS_PATH)
		if args.PRESET not in presets:
			print(f"Could not find preset {args.PRESET}", file = sys.stderr)
			exit(1)
		
		preset = presets[args.PRESET]
		print("Preset:", preset, file = sys.stderr, end = "\n\n")
		info = games_lib.extend(
			info,
			preset,
			overwrite_lists = True
		)

	arg_command = args.COMMAND
	if len(arg_command) == 0:
		arg_command = None
	info = games_lib.extend(
		info,
		{
			"prefix": args.PREFIX,
			"runner": args.RUNNER,
			"command": arg_command,
			"dry_run": args.DRY_RUN
		},
		overwrite_lists = True
	)

	# TODO: if something is still missing prompt for it

	print("Info:", info, file = sys.stderr, end = "\n\n")

	if info["prefix"] is None:
		print(f"Prefix not given in preset nor arguments", file = sys.stderr)
		exit(2)
	if info["runner"] is None:
		print(f"Runner not given in preset nor arguments", file = sys.stderr)
		exit(3)
	if info["command"] is None:
		print(f"Command not given in preset nor arguments", file = sys.stderr)
		exit(4)

	return info

def handler_normal(args):
	info = resolve_info(args)

	run_proton(info)

def handler_raw(args):
	info = resolve_info(args)

	run_raw(info)

def handler_tricks(args):
	info = resolve_info(args)

	run_tricks(info)

def handler_winekill(args):
	games_lib.run_command(
		[
			"pkill", "-f", "\.exe"
		]
	)

def define_cli_parser():
	parser = argparse.ArgumentParser(description = "Runs wine prefixes in proton")
	parser.add_argument(
		"-s", "--preset", dest = "PRESET",
		default = None, required = False,
		help = "Preset name to use"
	)
	parser.add_argument(
		"--prefix", dest = "PREFIX",
		default = None, required = False,
		help = "Relative or absolute path to a prefix to use"
	)
	parser.add_argument(
		"--runner", dest = "RUNNER",
		default = None, required = False,
		help = "Relative or absolute path to runner to user"
	)
	parser.add_argument(
		"--show", "--dry-run", dest = "DRY_RUN",
		default = False, action = "store_true", required = False,
		help = "Do not run the subprocess command, only show what would be run"
	)

	subparsers = parser.add_subparsers()

	# normal
	sub_normal = subparsers.add_parser(
		"run",
		help = "Run a preset in raw wine"
	)
	sub_normal.add_argument(
		"COMMAND",
		nargs = "*", 
		help = "Command to run"
	)
	sub_normal.set_defaults(handler_func = handler_normal)

	# raw
	sub_raw = subparsers.add_parser(
		"raw",
		help = "Run a preset in raw wine"
	)
	sub_raw.add_argument(
		"COMMAND",
		nargs = "*",
		help = "Command to run"
	)
	sub_raw.set_defaults(handler_func = handler_raw)

	# tricks
	sub_tricks = subparsers.add_parser(
		"tricks",
		help = "Run winetricks in a preset"
	)
	sub_tricks.add_argument(
		"COMMAND",
		nargs = "*",
		help = "Arguments to pass to winetricks"
	)
	sub_tricks.set_defaults(handler_func = handler_tricks)

	# winekill
	sub_winekill = subparsers.add_parser(
		"winekill",
		help = "Kill all runing wine instances"
	)
	sub_winekill.set_defaults(handler_func = handler_winekill)

	return parser

if __name__ == "__main__":
	main()
