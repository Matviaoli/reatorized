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
	type = structureType.REACTOR


# ====================
# Heat/Energy output
# ====================
# --- heat ---
func get_heat_output(daylight: float) -> float:
	match productionType:
		ProductionType.STABLE:
			return heatProduction
		
		ProductionType.SOLAR:
			return heatProduction * maxf(0.0, daylight)
		
		ProductionType.LUNAR:
			return heatProduction * maxf(0.0, -daylight)
		
		ProductionType.TWILIGHTER:
			return heatProduction * (1.0 - abs(daylight * 5)) 
		
		_:
			return heatProduction

# --- energy ---
func get_energy_output(daylight: float) -> float:
	match productionType:
		ProductionType.STABLE:
			return energyProduction
		
		ProductionType.SOLAR:
			return energyProduction * maxf(0.0, daylight)
		
		ProductionType.LUNAR:
			return energyProduction * maxf(0.0, -daylight)
		
		ProductionType.TWILIGHTER:
			return energyProduction * maxf(0.0,(1.0 - abs(daylight * 5)))
		
		_:
			return energyProduction
