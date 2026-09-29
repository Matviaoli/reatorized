# ====================
# Class & Extend
# ====================
class_name SearchStructure
extends StructureTile


# ====================
# Data
# ====================
@export var sciencePointsMantissa := 0.0
@export var sciencePointsExponent := 0


# ====================
# Wake up
# ====================
func _init() -> void:
	type = structureType.SEARCH


# ====================
# Get search
# ====================
func get_science_points() -> OverInfinity:
	return OverInfinity.to_load([sciencePointsMantissa, sciencePointsExponent])
