# ====================
# Class & Extend
# ====================
class_name SolarBasedReactorStructure
extends ReactorStructure


# ====================
# Type
# ====================
enum ProductionType {
	SOLAR,
	LUNAR,
	TWILIGHTER,
	STABLE
}

# ====================
# Data
# ====================
@export var productionType := ProductionType.STABLE


# ====================
# Wake up
# ====================
func _init() -> void:
	super()
	type = structureType.REACTOR


# ====================
# Heat/Energy output
# ====================
# --- heat ---
func get_heat_output(daylight: float) -> OverInfinity:
	match productionType:
		ProductionType.STABLE:
			return OverInfinity.to_load([heatProductionMantissa, heatProductionExponent])
		
		ProductionType.SOLAR:
			return OverInfinity.to_load([heatProductionMantissa, heatProductionExponent]).multiply_scalar(maxf(0.0, daylight))
		
		ProductionType.LUNAR:
			return OverInfinity.to_load([heatProductionMantissa, heatProductionExponent]).multiply_scalar(maxf(0.0, -daylight))
		
		ProductionType.TWILIGHTER:
			return OverInfinity.to_load([heatProductionMantissa, heatProductionExponent]).multiply_scalar(maxf(0.0,(1.0 - abs(daylight * 5)) / 5))
		
		_:
			return OverInfinity.to_load([heatProductionMantissa, heatProductionExponent])

# --- energy ---
func get_energy_output(daylight: float) -> OverInfinity:
	match productionType:
		ProductionType.STABLE:
			return OverInfinity.to_load([energyProductionMantissa, energyProductionExponent])
		
		ProductionType.SOLAR:
			return OverInfinity.to_load([energyProductionMantissa, energyProductionExponent]).multiply_scalar(maxf(0.0, daylight))
		
		ProductionType.LUNAR:
			return OverInfinity.to_load([energyProductionMantissa, energyProductionExponent]).multiply_scalar(maxf(0.0, -daylight))
		
		ProductionType.TWILIGHTER:
			return OverInfinity.to_load([energyProductionMantissa, energyProductionExponent]).multiply_scalar(maxf(0.0,(1.0 - abs(daylight * 5)) / 5))
		
		_:
			return OverInfinity.to_load([energyProductionMantissa, energyProductionExponent])
