# ====================
# Class & Extend
# ====================
class_name OfficeStructure
extends StructureTile


# ====================
# Data
# ====================
@export var energyConvertMantissa := 0
@export var energyCovertExponent := 0


# ====================
# Wake up
# ====================
func _init() -> void:
	type = structureType.OFFICE


# ====================
# Get energy convert
# ====================
func get_energy_convert() -> OverInfinity:
	return OverInfinity.to_load([energyConvertMantissa, energyCovertExponent])
