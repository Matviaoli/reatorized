# ====================
# Class & Extend
# ====================
class_name OfficeStructure
extends StructureTile


# ====================
# Data
# ====================
@export var energyConvert := 0.0


# ====================
# Wake up
# ====================
func _init() -> void:
	type = structureType.OFFICE
