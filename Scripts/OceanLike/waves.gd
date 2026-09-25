# ====================
# Class & Extend
# ====================
class_name WaveOcean
extends Node2D


# ====================
# Qualidade
# ====================
enum Quality { OFF, LOW, MEDIUM, HIGH }


# ====================
# Configs - Visual
# ====================
@export var debug_hitboxes := false
@export var terrain_layer : TerrainLayer
@export var wave_texture : Texture2D
@export var wave_size := Vector2(128, 32)
@export var lane_spacing := 32.0
@export var bob_amplitude := 3.0
@export var bob_speed := 1.5
@export var y_jitter_amplitude := 4.0
@export var excluded_ids : Array[StringName] = [&"beach"]
@export var min_speed := -30.0
@export var max_speed := 30.0
@export var back_z_index := -1
@export var front_z_indez := 1
@export var horizontal_hitbox_bonus := 16.0
@export var occlusion_samples := 3
@export var vertical_hitbox_size := 16.0     # altura da área testada, centrada no occlusion_offset
@export var vertical_samples := 2            # quantas linhas dentro dessa altura são checadas (mín. 1)

@export var background_texture : Texture2D


# ====================
# Configs - Performace
# ====================
@export var quality : Quality = Quality.LOW:
	set(value):
		quality = value
		_apply_quality()

@export var waves_move := true
@export var update_hz := 15.0
@export var occlusion_offset := 10.0
@export var active_margin_tiles := 2.0
@export var render_margin_screens := 1


# ====================
# Inner class
# ====================
class Lane:
	var base_y : float
	var speed : float
	var offset := 0.0
	var cache : Array = []
	var cache_valid := false
	var cache_left := 0.0
	var cache_right := 0.0

var _debug_boxes: Array = [] 

# ====================
# Variables
# ====================
var _lanes : Array[Lane] = []
var _pool : Array[Sprite2D] = []
var _camera : Camera2D
var _acc := 0.0
var _map_rect : Rect2
var _lane_step := 1
var _background : TextureRect
var _bg_layer : CanvasLayer


# ====================
# Process
# ====================
func _process(delta: float) -> void:
	if quality == Quality.OFF or terrain_layer == null or _lanes.is_empty():
		return
	
	_acc += delta
	var step := 1.0 / update_hz
	
	if _acc < step:
		return
	
	_acc -= step
	_simulate(step)


# ====================
# Step
# ====================
func setup(map_size: Vector2i, tile_size: Vector2i) -> void:
	_map_rect = Rect2(Vector2.ZERO, Vector2(map_size * tile_size))
	
	_lanes.clear()
	var y := 0.0
	
	while y < _map_rect.size.y:
		var lane := Lane.new()
		lane.base_y = y
		lane.speed = 0
		while lane.speed > -15 and lane.speed < 15:
			lane.speed = randf_range(min_speed, max_speed)
		lane.offset = randf_range(0.0, wave_size.x)
		_lanes.append(lane)
		y += lane_spacing
	
	_setup_background()
	_grow_pool(_estimate_pool_size())
	_apply_quality()


# ====================
# Brackground
# ====================
func _setup_background() -> void:
	if background_texture == null:
		return
	
	_bg_layer = CanvasLayer.new()
	_bg_layer.layer = -100
	add_child(_bg_layer)
	
	_background = TextureRect.new()
	_background.texture = background_texture
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_layer.add_child(_background)


# ====================
# Quality
# ====================
# --- apply quality ---
func _apply_quality() -> void:
	match quality:
		Quality.OFF:
			_hide_all()
		
		Quality.LOW:
			_lane_step = 3
		
		Quality.MEDIUM:
			_lane_step = 2
		
		Quality.HIGH:
			_lane_step = 1

# --- set waves move ---
func set_waves_move(enabled: bool) -> void:
	waves_move = enabled
	
	for lane in _lanes:
		lane.cache_valid = false

# --- hide all ---
func _hide_all() -> void:
	for sp in _pool:
		sp.visible = false


# ====================
# Sprite pool
# ====================
# --- grow pool ---
func _grow_pool(target: int) -> void:
	while _pool.size() < target:
		var sp := Sprite2D.new()
		sp.texture = wave_texture
		sp.visible = false
		sp.z_as_relative = true
		add_child(sp)
		_pool.append(sp)

# --- estimate pool size ---
func _estimate_pool_size() -> int:
	var vp := get_viewport().get_visible_rect().size
	var w := vp.x * (1.0 + render_margin_screens * 2.0)
	var h := vp.y * (1.0 + render_margin_screens * 2.0)
	var cols := int(w / wave_size.x) + 4
	var rows := int(h / lane_spacing) + 4
	return cols * rows


# ====================
# Simulation
# ====================
func _simulate(delta: float) -> void:
	if _camera == null:
		_camera = get_viewport().get_camera_2d()
		
		if _camera == null:
			return
	
	var active_rect := _get_rect(Vector2(wave_size.x, lane_spacing) * active_margin_tiles)
	var render_rect := _get_rect(get_viewport().get_visible_rect().size * render_margin_screens)
	var t := Time.get_ticks_msec() / 1000.0
	var used := 0
	
	if debug_hitboxes:
		_debug_boxes.clear()
	
	for i in range(0, _lanes.size(), _lane_step):
		var lane := _lanes[i]
		
		if lane.base_y < render_rect.position.y - wave_size.y or lane.base_y > render_rect.end.y + wave_size.y:
			continue
		
		var is_active := waves_move and lane.base_y >= active_rect.position.y - wave_size.y and lane.base_y <= active_rect.end.y + wave_size.y		
		
		if is_active:
			lane.offset = fmod(lane.offset + lane.speed * delta, wave_size.x)
			lane.cache_valid = false
		
		var columns : Array
		var cache_covers := lane.cache_left <= render_rect.position.x and lane.cache_right >= render_rect.end.x
		
		if is_active or not lane.cache_valid or not cache_covers:
			columns = _build_columns(lane, render_rect, i)	
			
			if not is_active:
				lane.cache = columns
				lane.cache_valid = true
				lane.cache_left = render_rect.position.x
				lane.cache_right = render_rect.end.x
		
		else:
			columns = lane.cache
		
		for col in columns:
			if used >= _pool.size():
				_grow_pool(used + 8)
			
			var sp := _pool[used]
			used += 1
			
			var bob := sin(t * bob_speed + col.x * 0.01) * bob_amplitude
			var pos := Vector2(col.x + wave_size.x * 0.5, lane.base_y + col.jitter + bob)
			sp.position = pos
			sp.visible = true
			sp.z_index = back_z_index if col.occluded else front_z_indez
			
			if debug_hitboxes:
				var hb := Rect2(
					col.x - horizontal_hitbox_bonus,
					lane.base_y + col.jitter + occlusion_offset - vertical_hitbox_size * 0.5,
					wave_size.x + horizontal_hitbox_bonus * 2.0,
					vertical_hitbox_size
				)
				var sprite_rect := Rect2(pos - wave_size * 0.5, wave_size)
				_debug_boxes.append({"hitbox": hb, "sprite": sprite_rect, "occluded": col.occluded})
	
	for j in range(used, _pool.size()):
		_pool[j].visible = false
	
	if debug_hitboxes:
		queue_redraw()


# ====================
# Build columns
# ====================
func _build_columns(lane: Lane, rect: Rect2, lane_i: int) -> Array:
	var out: Array = []
	var start_x : float = floor((rect.position.x - lane.offset) / wave_size.x) * wave_size.x + lane.offset
	var x := start_x
 	
	while x < rect.end.x:
		var jitter := sin(x * 0.041 + lane_i * 17.31) * y_jitter_amplitude
		var sample_y := lane.base_y + jitter + occlusion_offset
		var occluded := _is_occluded_area(x, sample_y)
		out.append({"x": x, "jitter": jitter, "occluded": occluded})
		x += wave_size.x
 	
	return out


# ====================
# Is occluded
# ====================
func _is_occluded(pos: Vector2) -> bool:
	var cell := terrain_layer.local_to_map(terrain_layer.to_local(pos))
	var id := terrain_layer.get_id_at(cell)
	
	if id == &"" or id in excluded_ids:
		return false
	
	return true


# ====================
# Occluded area (grade largura x altura)
# ====================
func _is_occluded_area(left_x: float, center_y: float) -> bool:
	var h_samples : float = max(occlusion_samples, 2)
	var v_samples : float = max(vertical_samples, 1)
	
	var span_x := wave_size.x + horizontal_hitbox_bonus * 2.0
	var step_x := span_x / float(h_samples - 1)
	var start_x := left_x - horizontal_hitbox_bonus
	
	var start_y := center_y
	var step_y := 0.0
	
	if v_samples > 1:
		start_y = center_y - vertical_hitbox_size * 0.5
		step_y = vertical_hitbox_size / float(v_samples - 1)
	
	for vy in v_samples:
		var y : float = start_y + step_y * vy
		
		for hx in h_samples:
			if _is_occluded(Vector2(start_x + step_x * hx, y)):
				return true
	
	return false

# ====================
# Get rect
# ====================
func _get_rect(margin: Vector2) -> Rect2:
	var vp_size := get_viewport().get_visible_rect().size / _camera.zoom
	var top_left := _camera.get_screen_center_position() - vp_size / 2.0 - margin
	return Rect2(top_left, vp_size + margin * 2.0)


# ====================
# Draw
# ====================
func _draw() -> void:
	if not debug_hitboxes:
		return
 
	for box in _debug_boxes:
		var hb: Rect2 = box.hitbox
		var sprite_rect: Rect2 = box.sprite
		var color := Color(1.0, 0.2, 0.2, 0.35) if box.occluded else Color(0.2, 1.0, 0.2, 0.25)
 
		draw_rect(hb, color, true)                       # área testada (com bônus)
		draw_rect(hb, color.lightened(0.4), false, 1.0)
		draw_rect(sprite_rect, Color.YELLOW, false, 1.0)  # tamanho visual do sprite, pra comparar
