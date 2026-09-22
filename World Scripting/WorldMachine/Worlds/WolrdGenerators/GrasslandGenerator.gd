# ====================
# Class & Extend
# ====================
class_name GrasslandGenerator
extends WorldGenerator


# ====================
# Data
# ====================
@export var terrainId: StringName = &"grass"
@export var oceanId: StringName = &"ocean"


# ====================
# Generator
# ====================
func generate(size: Vector2i) -> Dictionary:
	var cells := {}
	
	for x in size.x:
		for y in size.y:
			
			if y-x in range(-1, 1):
				cells[Vector2i(x, y)] = oceanId
			else:
				cells[Vector2i(x, y)] = terrainId
	
	return cells
