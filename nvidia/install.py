#!/bin/env python3

import os
import re
import sys
import json
import subprocess

RE_PKGNAME = re.compile(r"^([a-zA-Z1-9_.+-]+?)-([0-9._-]+)\s")

PACKAGES = ["nvidia", "nvidia-libs", "nvidia-libs-32bit"]
PACKAGE_REQUIREMENTS_CACHE = "requirements_cache.json"

ROOTDIR = "/opt/nvidia/fakeroot"
PLIST_PATH = "var/db/xbps/pkgdb-0.38.plist"

FILE_HEADER="""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
"""

def run_install(dry=False, sync_only=False, yes=False, force=False):
	command = [
		"xbps-install",
		"--rootdir", ROOTDIR,
		"--repository", "https://alpha.de.repo.voidlinux.org/current",
		"--repository", "https://alpha.de.repo.voidlinux.org/current/nonfree",
		"--repository", "https://alpha.de.repo.voidlinux.org/current/multilib",
		"--repository", "https://alpha.de.repo.voidlinux.org/current/multilib/nonfree"
	]

	if dry:
		command.append("--dry-run")

	if yes:
		command.append("--yes")

	if force:
		command.append("--force")
	
	command.append("--sync")
	if not sync_only:
		for package in PACKAGES:
			command.append(package)

	result = subprocess.run(command, universal_newlines=True, stdout=subprocess.PIPE)
	return result


def get_shlib(package):
	print("Obtaining shlib-requires and -provides for", package)

	command = ["xbps-query", "-R", package]
	result = subprocess.run(command, universal_newlines=True, stdout=subprocess.PIPE)

	if result.returncode != 0:
		return None
	
	shlib_provides = []
	shlib_provides_going = False

	shlib_requires = []
	shlib_requires_going = False

	lines = result.stdout.splitlines()
	for line in lines:
		if shlib_provides_going and not line[0].isspace():
			shlib_provides_going = False
		elif shlib_requires_going and not line[0].isspace():
			shlib_requires_going = False

		if shlib_provides_going:
			shlib_provides.append(line.strip())
		elif shlib_requires_going:
			shlib_requires.append(line.strip())

		if (not shlib_provides_going and not shlib_requires_going) and line.find("shlib-provides") > -1:
			shlib_provides_going = True
		elif (not shlib_provides_going and not shlib_requires_going) and line.find("shlib-requires") > -1:
			shlib_requires_going = True
	
	return shlib_provides, shlib_requires

def parse_requires(lines, packages=None):
	if packages is None:
		packages = {}

	for line in lines:
		line = line.strip()
		match = RE_PKGNAME.match(line)
		if match is None:
			raise RuntimeError("line doesn't match regex {}".format(line))
		
		pkg_name = match.group(1)
		pkg_ver = match.group(2)

		if pkg_name in PACKAGES:
			continue

		if pkg_name not in packages or packages[pkg_name]["version"] != pkg_ver:
			shlib_provides, shlib_requires = get_shlib(pkg_name)
			
			packages[pkg_name] = {
				"version": pkg_ver,
				"shlib-provides": shlib_provides,
				"shlib-requires": shlib_requires
			}
	
	return packages

def get_requires(requires_cache_path, force=False):
	print("Obtaining list of install requirements")
	dry_result = run_install(dry=True, force=force)
	if dry_result.returncode != 0:
		raise RuntimeError("install dryrun returned {}\nstdout:\n{}".format(dry_result.returncode, dry_result.stdout))
	lines = dry_result.stdout.splitlines()

	print("Attempting to load requirements cache")
	packages = None
	try:
		with open(requires_cache_path, "r") as file:
			packages = json.load(file)
	except json.JSONDecodeError:
		print("Load failed, file is not a valid json file")
	except FileNotFoundError:
		print("Load failes, file not found")

	print("Parsing install requirements..")
	packages = parse_requires(lines, packages)

	print("Saving requirements cache")
	with open(requires_cache_path, "w") as file:
		json.dump(packages, file)

	return packages


def generate_plist(requires, file):
	for pkg_name in requires:
		req = requires[pkg_name]

		print("\t<key>{}</key>".format(pkg_name), file=file)
		print("\t<dict>", file=file)

		print("\t\t<key>pkgver</key>", file=file)
		print("\t\t<string>{}-{}</string>".format(pkg_name, req["version"]), file=file)

		if len(req["shlib-provides"]) > 0:
			print("\t\t<key>shlib-provides</key>", file=file)
			print("\t\t<array>", file=file)

			for sh_prov in req["shlib-provides"]:
				print("\t\t\t<string>{}</string>".format(sh_prov), file=file)

			print("\t\t</array>", file=file)

		if len(req["shlib-requires"]) > 0:
			print("\t\t<key>shlib-requires</key>", file=file)
			print("\t\t<array>", file=file)

			for sh_req in req["shlib-requires"]:
				print("\t\t\t<string>{}</string>".format(sh_req), file=file)

			print("\t\t</array>", file=file)

		print("\t\t<key>state</key>", file=file)
		print("\t\t<string>installed</string>", file=file)

		print("\t</dict>", file=file)

def output_plist(path, requires):
	with open(path, "w") as file:
		print(FILE_HEADER, file=file, end="")
		print("<plist version=\"1.0\"><dict>", file=file)

		generate_plist(requires, file)

		print("</dict></plist>", file=file)


def prepare(force=False):
	print("Preparing..")

	os.makedirs(ROOTDIR, exist_ok=True)
	
	lib_path = os.path.join(ROOTDIR, "usr/lib")
	lib32_path = os.path.join(ROOTDIR, "usr/lib32")
	os.makedirs(lib_path, exist_ok=True)
	os.makedirs(lib32_path, exist_ok=True)
		
	try:
		os.symlink(lib_path, os.path.join(ROOTDIR, "lib"))
	except FileExistsError:
		pass
	try:
		os.symlink(lib32_path, os.path.join(ROOTDIR, "lib32"))
	except FileExistsError:
		pass

	run_install(sync_only=True)

	requires = get_requires(PACKAGE_REQUIREMENTS_CACHE, force=force)

	print("Creating plist")
	plist_path = os.path.join(ROOTDIR, PLIST_PATH)
	os.makedirs(os.path.dirname(plist_path), exist_ok=True)
	output_plist(plist_path, requires)

def install(force=False):
	print("Installing..")

	result = run_install(yes=True, force=force)

	print("Installation ended with code", result.returncode)
	print("Installation stdout:")
	print(result.stdout)

def main():
	force = False
	if len(sys.argv) > 1 and sys.argv[1] == "force":
		force = True

	prepare(force=force)
	install(force=force)

main()
