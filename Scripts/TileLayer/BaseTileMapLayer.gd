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

const CUSTOM_ID := "def_id"
const CUSTOM_STATE := "state"


# ====================
# Inner Class
# ====================
class TileVisual:
	var source_id : int
	var coords : Vector2i
	
	func _init(p_source_id : int, p_coords : Vector2i) -> void:
		source_id = p_source_id
		coords = p_coords


# ====================
# Data
# ====================
@export_dir var definitions_folder: String

var definitions:= {}
var data := {}

var states := {}
var _visuals:= {}


# ====================
# Wake up
# ====================
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	if definitions_folder.is_empty():
		push_warning("%s: definitions_folder não foi configurada" % name)
		return
	
	_load_definitions(definitions_folder)
	_build_visual_index()

# ====================
# Load definitions
# ====================
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
# Visual index
# ====================
func _build_visual_index() -> void:
	_visuals.clear()
	
	if tile_set == null:
		print("SEM TILE_SET")
		return
	
	var id_layer := tile_set.get_custom_data_layer_by_name(CUSTOM_ID)
	print("indice da camada def_id: ", id_layer)
	
	if id_layer == -1:
		return
	
	var has_state := tile_set.get_custom_data_layer_by_name(CUSTOM_STATE) != -1
	
	for i in tile_set.get_source_count():
		var source_id := tile_set.get_source_id(i)
		var atlas := tile_set.get_source(source_id) as TileSetAtlasSource
		
		if atlas == null:
			continue
		
		print("fonte ", source_id, " tem ", atlas.get_tiles_count(), " tiles")
		
		for t in atlas.get_tiles_count():
			var coords := atlas.get_tile_id(t)
			var tile_data := atlas.get_tile_data(coords, 0)
			var id := StringName(tile_data.get_custom_data(CUSTOM_ID))
			print("  tile ", coords, " def_id='", id, "'")
			
			if id == &"":
				continue
			
			if not definitions.has(id):
				push_warning("Tile %s (fonte %d) usa id '%s', que não tem definição" % [coords, source_id, id])
				continue
			
			var state := TileDefinition.DEFAULT_STATE
			
			if has_state:
				var raw := StringName(tile_data.get_custom_data(CUSTOM_STATE))
				
				if raw != &"":
					state = raw
			
			if not _visuals.has(id):
				_visuals[id] = {}
			
			if not _visuals[id].has(state):
				_visuals[id][state] = []
			
			_visuals[id][state].append(TileVisual.new(source_id, coords))

	


# ====================
# Consults
# ====================
func get_id_at(cell: Vector2i) -> StringName:
	return data.get(cell, &"")
 
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
# --- Place ---
func place(cell: Vector2i, id: StringName) -> bool:
	if not can_place(cell, id):
		return false
	
	_apply_cell(cell, id)
	return true
 
# --- Applye cell ---
func _apply_cell(cell: Vector2i, id: StringName) -> void:
	_register(cell, id)
	_paint(cell, id, TileDefinition.DEFAULT_STATE)

# --- Register ---
func _register(cell: Vector2i, id: StringName) -> void:
	data[cell] = id

# --- Paint ---
func _paint(cell: Vector2i, id: StringName, state: StringName) -> void:
	var visual := _pick_visual(cell, id, state)
	set_cell(cell, visual.source_id, visual.coords)

# --- Remove ---
func remove(cell: Vector2i) -> void:
	data.erase(cell)
	erase_cell(cell)

# --- Clear all ---
func clear_all() -> void:
	data.clear()
	clear()


# ====================
# Pick visual
# ====================
func _pick_visual(cell: Vector2i, id: StringName, state: StringName) -> TileVisual:
	var by_state : Dictionary = _visuals.get(id, {})
	
	var options: Array = by_state.get(state, [])
	
	if options.is_empty():
		options = by_state.get(TileDefinition.DEFAULT_STATE, [])
	
	if options.is_empty() and not by_state.is_empty():
		options = by_state.values()[0]
	
	if options.is_empty():
		return TileVisual.new(SOURCE_ID, definitions[id].atlas_coords)
		
	return options[posmod(hash(cell), options.size())]


# ====================
# Visual State
# ====================
func refresh_visual_states(daylight: float) -> void:
	var by_id := {}
	
	for cell in data:
		var id : StringName = data[cell]
		
		if not by_id.has(id):
			by_id[id] = definitions[id].get_visual_state(daylight)
		
		var state: StringName = by_id[id]
		
		if states.get(cell, TileDefinition.DEFAULT_STATE) == state:
			continue
		
		states[cell] = state
		_paint(cell, id, state)


# ====================
# Visual State
# ====================
func import_painted_cells() -> void:
	if tile_set == null or tile_set.get_custom_data_layer_by_name(CUSTOM_ID) == -1:
		return
	
	for cell in get_used_cells():
		var id : StringName = &""
		var tile_data := get_cell_tile_data(cell)
		
		if tile_data:
			id = StringName(tile_data.get_custom_data(CUSTOM_ID))
		
		if not definitions.has(id):
			push_warning("%s: o tile pintado em %s não tem um def_id válido" % [name, cell])
			continue
		
		_register(cell, id)


# ====================
# Save/Load
# ====================
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
