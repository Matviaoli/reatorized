# ====================
# Class & Extend
# ====================
class_name ReactorStructure
extends StructureTile


# ====================
# Data
# ====================
@export var energyProductionMantissa := 0.0
@export var energyProductionExponent := 0.0
@export var heatProductionMantissa := 0.0
@export var heatProductionExponent := 0.0
@export var passiveDissipationMantissa := 0.0
@export var passiveDissipationExponent := 0.0
@export var pollutionProduction := 0.0



# ====================
# Wake up
# ====================
func _init() -> void:
	type = structureType.REACTOR


# ====================
# Get Heat/Energy
# ====================
func get_energy_output(_daylight: float) -> OverInfinity:
	return OverInfinity.to_load([energyProductionMantissa, energyProductionExponent])

func get_heat_output(_daylight: float) -> OverInfinity:
	return OverInfinity.to_load([heatProductionMantissa, heatProductionExponent])

func get_heat_dissipation() -> OverInfinity:
	return OverInfinity.to_load([passiveDissipationMantissa, passiveDissipationExponent])
