#!/usr/bin/python3

import re
import sys
import os.path
import argparse

from dataclasses import dataclass

import fstree
from util import log, build_rsync_common, run_command, build_host_string, OUTPUT_SEPARATOR, find

DIFF_DOWN_PREFIX = "DOWN"
DIFF_UP_PREFIX = "UPLD"

# RE_DIFF_DELETING = re.compile("^\*deleting (.+?[^/])$")
RE_DIFF_SENDING = re.compile("^>f([^\s]{7,}) (.+)$")
RE_DIFF_RECEIVING = re.compile("^<f([^\s]{7,}) (.+)$")
def run_diff(args, outstream = sys.stdout):
	host_string = build_host_string(args)
	log(f"Running diff {host_string}:{args.PORT}:{args.REMOTE} and {args.LOCAL} ..", end = "\n\n")

	def cb_sending(line):
		match = RE_DIFF_SENDING.match(line)
		if match is not None:
			attributes = match.group(1)
			file = match.group(2)
			print(
				OUTPUT_SEPARATOR.join([DIFF_DOWN_PREFIX, attributes, file]), file = outstream
			)

			return True
		return False
	run_command(
		[
			"rsync", "--dry-run",
			"--itemize-changes", "--ignore-existing"
		] + build_rsync_common(args) + [
			f"{host_string}:{args.REMOTE}", args.LOCAL
		],
		cb_sending
	)
	
	def cb_receiving(line):
		match = RE_DIFF_RECEIVING.match(line)
		if match is not None:
			attributes = match.group(1)
			file = match.group(2)
			print(
				OUTPUT_SEPARATOR.join([DIFF_UP_PREFIX, attributes, file]), file = outstream
			)

			return True
		
		return False
	run_command(
		[
			"rsync", "--dry-run",
			"--itemize-changes", "--ignore-existing"
		] + build_rsync_common(args) + [
			args.LOCAL, f"{host_string}:{args.REMOTE}"
		],
		cb_receiving
	)

	def cb_existing(line):
		return cb_sending(line) or cb_receiving(line)
	run_command(
		[
			"rsync", "--dry-run",
			"--itemize-changes", "--existing"
		] + build_rsync_common(args) + [
			f"{host_string}:{args.REMOTE}", args.LOCAL
		],
		cb_existing
	)

@dataclass
class DiffEntry:
	path: list
	attributes: str

RE_DIFF_DOWN = re.compile(
	OUTPUT_SEPARATOR.join([DIFF_DOWN_PREFIX, "([^\s]{7,})", "(.+)"])
)
RE_DIFF_UP = re.compile(
	OUTPUT_SEPARATOR.join([DIFF_UP_PREFIX, "([^\s]{7,})", "(.+)"])
)
def parse_diff(path):
	down_entries = []
	up_entries = []
	with open(path, "r") as file:
		for line in file:
			down_match = RE_DIFF_DOWN.match(line)
			if down_match is not None:
				path = fstree.FileSystemNode.split_path(down_match.group(2))
				down_entries.append(DiffEntry(path, down_match.group(1)))
				continue
			
			up_match = RE_DIFF_UP.match(line)
			if up_match is not None:
				path = fstree.FileSystemNode.split_path(up_match.group(2))
				up_entries.append(DiffEntry(path, up_match.group(1)))
				continue
	
	return down_entries, up_entries

def filter_extensions(entries, extensions):
	return list(
		filter(
			lambda entry: os.path.splitext(entry.path[-1])[1] in extensions,
			entries
		)
	)

def is_subpath_similar(left, right):
	if len(left) > len(right):
		return is_subpath_similar(right, left)
	
	# similar name with number prefix inside any directory
	def normalize_filename(name):
		return name.lstrip("0123456789- ").lower()
	left_file = normalize_filename(left[-1])
	right_file = normalize_filename(right[-1])
	if left_file == right_file:
		return True
	
	return False

def dedudplicate_entries(entries, tree, common_parent_level_limit = 2, is_similar_cb = is_subpath_similar):
	"""
	Deduplicates list of entries with respect to the given tree.

	`common_parent_level_limit` - controls how many levels up the search can go to look for a similar file
	"""

	unique = []
	duplicates = []

	for entry in entries:
		# path is directly found
		if tree.get(entry.path) is not None:
			duplicates.append(entry)
			continue
		
		# some common parent is found
		common_parent, remaining_path = tree.get_partial(entry.path)
		
		# uphold the parent level limit
		if len(remaining_path) <= common_parent_level_limit:
			similar_child_path = find(
				lambda subpath: is_similar_cb(remaining_path, subpath),
				common_parent.walk()
			)
			if similar_child_path is not None:
				duplicates.append(entry)
				continue
		
		unique.append(entry)
	
	return unique, duplicates

def run_diff_dedup(args, outstream = sys.stdout):
	down_entries, up_entries = parse_diff(args.PATH)

	if args.EXTENSIONS is not None:
		down_entries = filter_extensions(down_entries, args.EXTENSIONS)
		up_entries = filter_extensions(up_entries, args.EXTENSIONS)

	down_tree = fstree.FileSystemNode.build_tree(map(lambda entry: entry.path, down_entries))
	up_tree = fstree.FileSystemNode.build_tree(map(lambda entry: entry.path, up_entries))

	down_unique, down_duplicates = dedudplicate_entries(down_entries, up_tree)
	up_unique, up_duplicates = dedudplicate_entries(up_entries, down_tree)

	for entry in down_unique:
		print(
			OUTPUT_SEPARATOR.join([DIFF_DOWN_PREFIX, entry.attributes, os.path.join(*entry.path)]),
			file = outstream
		)
	for entry in up_unique:
		print(
			OUTPUT_SEPARATOR.join([DIFF_UP_PREFIX, entry.attributes, os.path.join(*entry.path)]),
			file = outstream
		)
	
	if args.SHOW_DUPLICATES:
		print(file = outstream)
		for entry in down_duplicates:
			print(
				OUTPUT_SEPARATOR.join(["#" + DIFF_DOWN_PREFIX, entry.attributes, os.path.join(*entry.path)]),
				file = outstream
			)
		for entry in up_duplicates:
			print(
				OUTPUT_SEPARATOR.join(["#" + DIFF_UP_PREFIX, entry.attributes, os.path.join(*entry.path)]),
				file = outstream
			)

def run_diff_execute(args):
	down_entries, up_entries = parse_diff(args.PATH)

	host_string = build_host_string(args)
	log(f"Running diff execute {host_string}:{args.PORT}:{args.REMOTE} and {args.LOCAL} ..", end = "\n\n")

	if len(down_entries) > 0:
		download_args = [os.path.join(args.REMOTE, ".", *entry.path) for entry in down_entries]
		# quote the args, prepend :
		download_args = list(map(lambda x: f":\"{x}\"", download_args))
		# prepend host string to the first arg
		download_args[0] = host_string + download_args[0]

		run_command(
			[
				"rsync",
				"--archive", "--update",
				"--progress", "--stats",
				"--relative"
			] + build_rsync_common(args) + 
			download_args + [args.LOCAL]
		)

	if len(up_entries) > 0:
		upload_args = [os.path.join(args.LOCAL, ".", *entry.path) for entry in up_entries]
		run_command(
			[
				"rsync",
				"--archive", "--update",
				"--progress", "--stats",
				"--relative"
			] + build_rsync_common(args) +
			upload_args + [f"{host_string}:{args.REMOTE}"]
		)