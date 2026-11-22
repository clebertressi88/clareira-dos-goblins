extends RefCounted
## Validacao de padroes de crafting 2x2 e 3x3.
## Chamado pelos wrappers em main.gd para preservar o comportamento do jogo.

static func expand_basic_pattern(pattern: Array, row: int, col: int) -> Array:
	var expanded: Array = []
	expanded.resize(9)
	expanded.fill(-1)
	for i in range(4):
		expanded[(row + int(i / 2))*3 + col + i%2] = pattern[i]
	return expanded

static func matches_basic_recipe(craft_cells: Array[Vector2i], pattern: Array) -> bool:
	if craft_cells.size()==4:
		return matches_recipe(craft_cells, pattern)
	if craft_cells.size()!=9:
		return false
	for row in range(2):
		for col in range(2):
			if matches_recipe(craft_cells, expand_basic_pattern(pattern,row,col)):
				return true
	return false

static func matches_recipe(craft_cells: Array[Vector2i], pattern: Array) -> bool:
	if pattern.size()!=craft_cells.size():
		return false
	for i in range(pattern.size()):
		var expected: int = pattern[i]
		if expected==-1:
			if craft_cells[i].y!=0:
				return false
		elif craft_cells[i].x!=expected or craft_cells[i].y<1:
			return false
	return true
