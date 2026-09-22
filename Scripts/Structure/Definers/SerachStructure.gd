# ====================
# Class & Extend
# ====================
class_name SearchStructure
extends StructureTile


# ====================
# Data
# ====================
@export var sciencePoints := 0.0


# ====================
# Wake up
# ====================
func _init() -> void:
	type = structureType.SEARCH
