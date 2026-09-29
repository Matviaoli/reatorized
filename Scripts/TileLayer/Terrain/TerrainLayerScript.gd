# ====================
# Class & Extend
# ====================
class_name TerrainLayer
extends BaseTileMapLayer


# ====================
# Can place
# ====================
func can_place(_cell: Vector2i, id: StringName) -> bool:
	return definitions.has(id)
