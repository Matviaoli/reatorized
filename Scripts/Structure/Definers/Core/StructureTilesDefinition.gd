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
	DEBRIS,
	NONE
	
}


# ====================
# Data
# ====================
@export var type := structureType.NONE
@export var purchasable := true
@export var priceMantissa := 0.0
@export var priceExponent := 0
@export var blastResistance := 1.0
@export var explosionPower := -1.0
@export var maxHeatMantissa = -1 # -1 = nunca superaquece
@export var maxHeatExponent := 0
@export var allowedTerrains: Array[TerrainTile]
@export var unlocked := false


# ====================
# Rotors
# ====================
@export var rotor_texture: Texture2D
@export var rotor_offset := Vector2.ZERO
@export var rotor_speed := 20.0


# ====================
# Get max heat 
# ====================
func get_max_heat() -> OverInfinity:
	return OverInfinity.to_load([maxHeatMantissa, maxHeatExponent])


# ====================
# Get price
# ====================
func get_price() -> OverInfinity:
	return OverInfinity.to_load([priceMantissa, priceExponent])


# ====================
# Set rotor speed
# ====================
func set_rotor_speed(newspeed: float) -> void:
	rotor_speed = newspeed
