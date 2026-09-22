# ====================
# Class & Extend
# ====================
class_name StructureLayer
extends BaseTileMapLayer

# ====================
# Variables
# ====================
var terrainLayer: TerrainLayer
var heat := {}  # Vector2i -> float


# ====================
# Can place
# ====================
func can_place(cell: Vector2i, id: StringName) -> bool:
	if not super.can_place(cell, id):
		return false

	var terrain := terrainLayer.get_definition_at(cell) as TerrainTile
	if terrain == null:
		return false

	var structure := definitions[id] as StructureTile
	if structure.allowedTerrains.is_empty():
		return terrain.buildable

	return terrain in structure.allowedTerrains


# ====================
# Heat bookkeeping
# ====================
func _apply_cell(cell: Vector2i, id: StringName) -> void:
	super._apply_cell(cell, id)
	heat[cell] = 0.0


func remove(cell: Vector2i) -> void:
	super.remove(cell)
	heat.erase(cell)


func clear_all() -> void:
	super.clear_all()
	heat.clear()
