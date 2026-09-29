# ====================
# Class & Extend
# ====================
class_name PollutionStructure
extends StructureTile


# ====================
# Data
# ====================
@export var pollutionConvert := 0.0


# ====================
# Wake up
# ====================
func _init() -> void:
	type = structureType.POLLUTION
