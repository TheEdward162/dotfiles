import os.path

class FileSystemNode:
	@staticmethod
	def split_path(path):
		entries = []

		while True:
			head, tail = os.path.split(path)

			if tail == "":
				if head != "":
					entries.append(head)
				break
			entries.append(tail)
			
			path = head
		
		entries.reverse()
		return entries
	
	@staticmethod
	def build_tree(split_paths):
		root = FileSystemNode("", True)

		for split_path in split_paths:
			root.add(split_path)
		
		return root
	
	def __init__(self, name, is_directory = False):
		self.name = name

		if is_directory:
			self.children = []
		else:
			self.children = None

	def is_file(self):
		return self.children is None
	
	def __repr__(self):
		return self.fmt()

	def fmt(self, depth = 0):
		ident_prefix = "  " * depth
		if self.children is None:
			return f"{ident_prefix}{self.name}\n"
		
		base = f"{ident_prefix}{self.name}/\n"
		for child in self.children:
			base += child.fmt(depth + 1)
		
		return base
	
	def add(self, split_path):
		if self.is_file():
			raise RuntimeError("Cannot add subpath to file node")

		if len(split_path) == 0:
			raise RuntimeError("Cannot add empty subpath")

		child = self._get_direct_child(split_path[0])

		# file leaf node
		if len(split_path) == 1:
			if child is None:
				child = FileSystemNode(split_path[0])
				self.children.append(child)
			elif not child.is_file():
				raise RuntimeError("Cannot add file child that would overwrite a directory")

			return child

		# directory 
		if child is None:
			child = FileSystemNode(split_path[0], True)
			self.children.append(child)

		return child.add(split_path[1:])

	def _get_direct_child(self, name):
		for child in self.children:
			if child.name == name:
				return child

		return None

	def get_partial(self, split_path):
		if len(split_path) == 0:
			return self, split_path
		
		if self.is_file():
			raise RuntimeError("Cannot get subpath from file node")
		
		for child in self.children:
			if child.name == split_path[0]:
				return child.get_partial(split_path[1:])
		
		return self, split_path

	def get(self, split_path):
		node, remaining = self.get_partial(split_path)
		
		if len(remaining) == 0:
			return node
		else:
			return None
	
	def walk(self, dirs = False):
		if self.is_file():
			yield [self.name]
			return
		
		if dirs:
			yield [self.name]
		for child in self.children:
			for child_walk in child.walk():
				yield [self.name] + child_walk