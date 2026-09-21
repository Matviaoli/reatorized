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


# ====================
# Data
# ====================
@export_dir var definitions_folder: String

var definitions:= {}
var data := {}


# ====================
# Wake up
# ====================
func _ready() -> void:
	if definitions_folder.is_empty():
		push_warning("%s: definitions_folder não foi configurada" % name)
		return
	
	_load_definitions(definitions_folder)

# --- load definitions ---
func _load_definitions(folder: String) -> void:
	for file in DirAccess.get_files_at(folder):
		var fname := file.trim_suffix(".remap")
		
		if not fname.ends_with(".tres"):
			continue
		
		var path := folder.path_join(fname)
		var def := load(path) as TileDefinition
		
		if def == null:
			continue
		
		if def.id == &"":
			push_warning("Definição sem ID: " + path)
			continue
		
		if definitions.has(def.id):
			push_warning("Id repetido '%s': %s" % [def.id, path])
			continue
		
		definitions[def.id] = def
	
	for sub in DirAccess.get_directories_at(folder):
		_load_definitions(folder.path_join(sub))


# ====================
# Consults
# ====================
func get_definition(id: StringName) -> TileDefinition:
	return definitions.get(id)

func get_definition_at(cell: Vector2i) -> TileDefinition:
	return definitions.get(data.get(cell))


# ====================
# Overwrite
# ====================
func can_place(cell: Vector2i, id: StringName) -> bool:
	return definitions.has(id) and not data.has(cell)


# ====================
# Comum behaviour
# ====================
func place(cell: Vector2i, id: StringName) -> bool:
	if not can_place(cell, id):
		return false
	
	_apply_cell(cell, id)
	return true

func _apply_cell(cell: Vector2i, id: StringName) -> void:
	data[cell] = id
	set_cell(cell, SOURCE_ID, definitions[id].atlas_coords)

func remove(cell: Vector2i) -> void:
	data.erase(cell)
	erase_cell(cell)

func clear_all() -> void:
	data.clear()
	clear()

func to_save_data() -> Array:
	var out := []
	for cell in data:
		out.append([cell.x, cell.y, String(data[cell])])
	return out

func from_save_data(entries: Array) -> void:
	clear_all()
	for e in entries:
		var id := StringName(str(e[2]))
		if definitions.has(id):  
			_apply_cell(Vector2i(int(e[0]), int(e[1])), id)
