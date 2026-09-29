# ====================
# Class & Extend
# ====================
class_name CloudLayer
extends Node2D


# ====================
# Signal
# ====================
signal reveal_finished(region_id: StringName)


# ====================
# Export
# ====================
@export var regionsManager: RegionsManager
@export_dir var clouds_folder: String = "res://Visual/Paper/Clouds"
@export var clouds_per_region_min := 25
@export var clouds_per_region_max := 100
@export var pull_duration := 1.2
@export var pull_height := 400.0
@export var tileSize := Vector2i(16, 16)
@export var stagger := 0.08 



# ====================
# State
# ====================
var terrain : TerrainLayer
var _clouds_textures: Array[Texture2D] = []
var _region_clouds: Dictionary = {}
var _busy := false


# ====================
# Setup
# ====================
func setup() -> void:
	_load_cloud_textures()
	
	if regionsManager:
		regionsManager.region_changed.connect(_rebuild_all)
		regionsManager.region_unlocked.connect(_on_region_unlocked)
		_rebuild_all()


# ====================
# Load textures
# ====================
func _load_cloud_textures() -> void:
	_clouds_textures.clear()
	
	if clouds_folder.is_empty():
		push_warning("A pasta de nuvens está vazia ou não condigurada!")
		return
	
	for file in DirAccess.get_files_at(clouds_folder):
		var fname := file.trim_suffix(".remap")
		var low := fname.to_lower()
		
		if not (low.ends_with(".png") or low.ends_with(".svg") or low.ends_with(".webp")):
			continue
		
		var tex := load(clouds_folder.path_join(fname)) as Texture2D
		
		if tex:
			_clouds_textures.append(tex)
	
	if _clouds_textures.is_empty():
		push_warning("A pasta de nuvens não contém imagens validas ou não foi configurada!")


# ====================
# Rebuild all
# ====================
func _rebuild_all() -> void:
	for id in _region_clouds.keys():
		_clear_region_clouds(id)
	
	_region_clouds.clear()
	
	if regionsManager == null:
		return
	
	for region in regionsManager.get_locked_regions():
		_spawn_clouds(region)


# ====================
# Spawn clouds
# ====================
func _spawn_clouds(region: Regions) -> void:
	if region == null or _clouds_textures.is_empty():
		return
	
	var cells := region.get_all_cells()
	var count := mini(randi_range(clouds_per_region_min, clouds_per_region_max), cells.size())
	cells.shuffle()
	var pieces: Array[CloudPiece] = []
	
	for i in count:
		var cell: Vector2i = cells[i]
		var world_pos: Vector2
		if terrain:
			world_pos = terrain.to_global(terrain.map_to_local(cell))
		else:
			world_pos = Vector2(cell * tileSize) + Vector2(tileSize) * 0.5
		
		var piece := CloudPiece.new()
		var tex: Texture2D = _clouds_textures[randi() % _clouds_textures.size()]
		piece.setup(tex, world_pos)
		add_child(piece)
		pieces.append(piece)
	
	_region_clouds[region.id] = pieces


# ====================
# Clear region clouds
# ====================
func _clear_region_clouds(region_id: StringName) -> void:
	if not _region_clouds.has(region_id):
		return
	
	for piece in _region_clouds[region_id]:
		if is_instance_valid(piece):
			piece.queue_free()
	
	_region_clouds.erase(region_id)


# ====================
# Unlock animation
# ====================
func _on_region_unlocked(region_id: StringName) -> void:
	reveal_region(region_id)

func reveal_region(region_id: StringName) -> void:
	if not _region_clouds.has(region_id):
		reveal_finished.emit(region_id)
		return
	
	_busy = true
	var pieces: Array = _region_clouds[region_id].duplicate()
	pieces.shuffle()
	
	if pieces.is_empty():
		_busy = false
		reveal_finished.emit(region_id)
		return
	
	
	var tween := create_tween()
	
	for i in pieces.size():
		var piece: CloudPiece = pieces[i]
		if not is_instance_valid(piece):
			continue
		
		if piece.has_method("stop_idle"):
			piece.stop_idle()
		
		var delay := i * stagger
		var target_y := piece.position.y - pull_height - randf_range(0.0, 80.0)
		var target_x := piece.position.x + randf_range(-20.0, 20.0)
		
		tween.parallel().tween_property(
			piece, "position", Vector2(target_x, target_y), pull_duration
		).set_delay(delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		
		tween.parallel().tween_property(
			piece, "modulate:a", 0.0, pull_duration
		).set_delay(delay).set_ease(Tween.EASE_IN)
	
	var total_time := ((pieces.size() - 1) * stagger) + pull_duration
	tween.parallel().tween_interval(total_time)
	
	tween.finished.connect(func():
		_clear_region_clouds(region_id)
		_busy = false
		reveal_finished.emit(region_id)
	)


func is_busy() -> bool:
	return _busy
