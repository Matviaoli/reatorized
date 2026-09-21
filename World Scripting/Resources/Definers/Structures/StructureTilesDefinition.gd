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
@export var maxHeat := -1.0  # -1 = nunca superaquece
@export var allowedTerrains: Array[TerrainTile]
