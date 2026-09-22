# ====================
# Class & Extend
# ====================
class_name TerrainLayer
extends BaseTileMapLayer


# ====================
# Can place
# ====================
# O terreno pode ser trocado por cima, só exige que o id exista
func can_place(_cell: Vector2i, id: StringName) -> bool:
	return definitions.has(id)
