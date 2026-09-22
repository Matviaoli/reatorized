# ====================
# Class & Extend
# ====================
class_name GeneratorStructure
extends StructureTile


# ====================
# Data
# ====================
@export var heatConvert := 0.0


# ====================
# Wake up
# ====================
func _init() -> void:
	type = structureType.GENERATOR
