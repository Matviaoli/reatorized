# ====================
# Class & Extend
# ====================
class_name StructureLayer
extends BaseTileMapLayer

# ====================
# Variables
# ====================
var terrainLayer: TerrainLayer
var heat := {}


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
