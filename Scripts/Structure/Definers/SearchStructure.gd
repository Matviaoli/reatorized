# ====================
# Class & Extend
# ====================
class_name SearchStructure
extends StructureTile


# ====================
# Data
# ====================
@export var sciencePointsMantissa := 0.0
@export var sciencePointsExport := 0.0


# ====================
# Wake up
# ====================
func _init() -> void:
	type = structureType.SEARCH


# ====================
# Get search
# ====================
func get_mah_heat() -> OverInfinity:
	return OverInfinity.to_load([sciencePointsMantissa, sciencePointsExport])
