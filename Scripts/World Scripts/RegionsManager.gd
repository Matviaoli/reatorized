# ====================
# Class & Extend
# ====================
class_name RegionsManager
extends Node


# ====================
# Signals
# ====================
signal region_unlocked(region_id: StringName)
signal region_changed()


# ====================
# Exports
# ====================
@export var regions: Array[Regions] = []
@export_dir var world_folder: String


# ====================
# State
# ====================
var unlocked: Array[StringName] = []


# ====================
# Setup
# ====================
func setup() -> void:
	if world_folder.is_empty():
		push_warning("World_folder não foi configurado")
		return
	
	_load_regions_from_folder(world_folder)
	_initialize_unlocked()


# ====================
# Load Regions
# ====================
func _load_regions_from_folder(folder: String) -> void:
	for file in DirAccess.get_files_at(folder):
		var fname := file.trim_suffix(".remap")
		
		if not fname.ends_with(".tres"):
			continue
		
		var path := folder.path_join(fname)
		var def := load(path) as Regions
		
		if def == null:
			continue
		
		if def.id == &"":
			push_warning("Definição de região sem ID: " + path)
			continue
		
		for existing in regions:
			if existing and existing.id == def.id:
				push_warning("Duas regiões dividem o mesmo ID '%s' (%s e %s)" % [def.id, existing.region_name, def.region_name])
				continue
		
		regions.append(def)
	
	for sub in DirAccess.get_directories_at(folder):
		_load_regions_from_folder(folder.path_join(sub))

# ====================
# Initialize Unlocked
# ====================
func _initialize_unlocked() -> void:
	unlocked.clear()
	
	for region in regions:
		if region == null:
			continue
		
		if region.unlocked_by_default:
			unlocked.append(region.id) 
	
	region_changed.emit()

# ====================
# Is cell unlocked
# ====================
func is_cell_unlocked(cell: Vector2i) -> bool:
	for region in regions:
		if region == null:
			continue
		
		if region.contains_cell(cell):
			return region.id in unlocked
	
	return true

# ====================
# Get region at
# ====================
func get_region_at(cell: Vector2i) -> Regions:
	for region in regions:
		if region and region.contains_cell(cell):
			return region
	
	return null

# ====================
# Is region unlocked
# ====================
func is_region_unlocked(region_id: StringName) -> bool:
	return region_id in unlocked

# ====================
# Get unlocked regions
# ====================
func get_unlocked_regions() -> Array[StringName]:
	return unlocked.duplicate()

# ====================
# Get locked regions
# ====================
func get_locked_regions() -> Array[Regions]:
	var locked: Array[Regions] = []
	
	for region in regions:
		if region and region.id not in unlocked:
			locked.append(region)
	
	return locked

# ====================
# Unlock logic
# ====================
func can_unlock(region: Regions, money: OverInfinity) -> bool:
	if region == null:
		return false
	
	return region.can_unlock(unlocked, money)

func try_unlock(region_id: StringName, money: OverInfinity) -> bool:
	var region := _find_region(region_id)
	
	if region == null:
		return false
	
	if not can_unlock(region, money):
		return false
	
	unlocked.append(region.id)
	region_unlocked.emit(region.id)
	region_changed.emit()
	return true

# ====================
# Find region
# ====================
func _find_region(region_id: StringName) -> Regions:
	for region in regions:
		if region and region.id == region_id:
			return region
	
	return null

# ====================
# Get all locked cells
# ====================
func get_all_locked_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	
	for region in regions:
		if region == null or region.id in unlocked:
			continue
		
		cells.append_array(region.get_all_cells())
	
	return cells
