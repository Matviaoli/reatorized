# ====================
# Class & Extend
# ====================
class_name TerrainLayer
extends BaseTileMapLayer


# ====================
# Tiles types
# ====================
enum TerrainTypes{
	GRASS,
	SAND,
	STONE,
	OCEAN,
	BETA
}

# ====================
# Consts
# ====================
const ATLAS := {
	
	TerrainTypes.GRASS: Vector2i(0, 0),
	TerrainTypes.SAND: Vector2i(1, 0),
	TerrainTypes.STONE: Vector2i(0, 1),
	TerrainTypes.OCEAN: Vector2i(1, 1),
	TerrainTypes.BETA: Vector2i(2, 0)
	
}


# ====================
# Atlas Coords
# ====================
func _atlas_coords(type: int) -> Vector2i:
	return ATLAS[type]


# ====================
# Can place
# ====================
func can_place(cell: Vector2i, type: int) -> bool:
	return true
