# ====================
# Class & Extend
# ====================
class_name StructureTile
extends TileDefinition

# ====================
# Type enum
# ====================
enum structureType{
	
	SUPPORT,
	REACTOR,
	SEARCH,
	POLLUTION,
	OFFICE,
	BATTERY,
	GENERATOR,
	NONE
	
}


# ====================
# Data
# ====================
@export var type := structureType.NONE
@export var purchasable := true
@export var price := 0.0
@export var blastResistance := 1.0
@export var explosionPower := -1.0
@export var maxHeatMantissa = -1 # -1 = nunca superaquece
@export var maxHeatExponent := 1
@export var allowedTerrains: Array[TerrainTile]


# ====================
# Get max heat 
# ====================
func get_mah_heat() -> OverInfinity:
	return OverInfinity.to_load([maxHeatMantissa, maxHeatExponent])
