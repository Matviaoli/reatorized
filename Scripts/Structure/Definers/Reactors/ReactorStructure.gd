# ====================
# Class & Extend
# ====================
class_name ReactorStructure
extends StructureTile


# ====================
# Data
# ====================
@export var energyProduction := 0.0
@export var heatProduction := 0.0
@export var pollutionProduction := 0.0
@export var passiveDissipation := 0.0


# ====================
# Wake up
# ====================
func _init() -> void:
	type = structureType.REACTOR


# ====================
# Get Heat/Energy
# ====================
func get_energy_output(daylight: float) -> float:
	return energyProduction

func get_heat_output(daylight: float) -> float:
	return heatProduction
