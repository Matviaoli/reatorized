# ====================
# Class & Extend
# ====================
class_name Regions
extends Resource


# ====================
# Data
# ====================
@export var id: StringName
@export var region_name: String
@export_multiline var description: String
@export_group("Unlock")
@export var unlocked_by_default := true
@export var mantissaPrice := 0.0
@export var exponentPrice := 0
@export var needed_regions : Array[Regions]
# @export var needed_achiviments : Array[Achiviments]
# Mais tarde adicionar conquistas para desbloquear certas regiões
@export_group("Area")
@export var region_area : Array[Rect2i]
var price := OverInfinity.zero()


# ====================
# Wake up
# ====================
func _init() -> void:
	price.mantissa = mantissaPrice
	price.exponent = exponentPrice


# ====================
# Helpers
# ====================
# --- Contains cell ---
func contains_cell(cell: Vector2i) -> bool:
	for rect in region_area:
		if rect.has_point(cell):
			
			return true
	return false

# --- Get all cells ---
func get_all_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	
	for rect in region_area:
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			for y in range(rect.position.y, rect.position.y + rect.size.y):
				
				cells.append(Vector2i(x, y))
	
	return cells

# --- Can unlock ---
func can_unlock(current_unlocked: Array[StringName], money: OverInfinity) -> bool:
	if unlocked_by_default:
		return true
	
	if id in current_unlocked:
		return false
	
	if money.less_than(price):
		return false
	
	for needed in needed_regions:
		if needed == null:
			continue
		
		if needed.id not in current_unlocked:
			return false
	
	return true
