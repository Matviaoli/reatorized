# ====================
# Class & Extend
# ====================
class_name GeneratorStructure
extends StructureTile


# ====================
# Data
# ====================
@export var heatConvertMantissa := 0.0
@export var heatConvertExponent := 0


# ====================
# Wake up
# ====================
func _init() -> void:
	type = structureType.GENERATOR


# ====================
# Get heat convert
# ====================
func get_heat_convert() -> OverInfinity:
	return OverInfinity.to_load([heatConvertMantissa, heatConvertExponent])
