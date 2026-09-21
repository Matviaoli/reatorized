# ====================
# Class & Extend
# ====================
class_name BaseTileMapLayer
extends TileMapLayer


# ====================
# Consts
# ====================
# Source ID
const SOURCE_ID := 0 

# Data
var data := {}


# ====================
# Sobresescrever
# ====================
# Atlas Coords
func _atlas_coords(_type: int) -> Vector2i:
	return Vector2i.ZERO

# Can Place
func can_place(cell: Vector2i, id: StringName) -> bool:
	return not data.has(cell)


# ====================
# Comum Behaviour
# ====================
# Place
func place(cell: Vector2i, id: StringName) -> bool:
	if not can_place(cell, id):
		return false
		
	_apply_cell(cell, id)
	return true

# Apply cell
func _apply_cell(cell: Vector2i, type: int) -> void:
	data[cell] = type
	set_cell(cell, SOURCE_ID, _atlas_coords(type))

# Remove
func remove(cell: Vector2i) -> void:
	data.erase(cell)
	erase_cell(cell)

# Clear all
func clear_all() -> void:
	data.clear()
	clear()

# To save data
func to_save_data() -> Array:
	var out := []
	for cell in data:
		out.append([cell.x, cell.y, data[cell]])
	return out

# From save data
func from_save_data(entries: Array) -> void:
	clear_all()
	for e in entries:
		_apply_cell(Vector2i(int(e[0]), int(e[1])), int(e[2]))
