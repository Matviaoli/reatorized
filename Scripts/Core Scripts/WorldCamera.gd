# ====================
# Class & Extend
# ====================
class_name WorldCamera
extends Camera2D

# ====================
# Signal & Consts
# ====================
signal tapped(world_position: Vector2i)
const TAP_MAX_DRAG := 4.0
const MIN_ZOOM := 0.5
const MAX_ZOOM := 6.0
const ZOOM_FACTOR := 1.1

# ====================
# Variables
# ====================
var _pressed := false
var _dragged := 0.0
var input_enabled := true

# Para touch (índice do dedo que está arrastando)
var _touch_index: int = -1
var _world_rect := Rect2i()

# ====================
# Bounds
# ====================
func set_bounds(rect: Rect2i) -> void:
	_world_rect = rect
	position = Vector2(rect.get_center())
	_update_limits()


# ====================
# Zoom
# ====================
func _zoom_by(factor: float) -> void:
	var z := clampf(zoom.x * factor, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(z, z)
	_update_limits()

func _update_limits() -> void:
	if _world_rect.size == Vector2i.ZERO:
		limit_enabled = false
		return
	
	var view := get_viewport_rect().size / zoom
	var world := Vector2(_world_rect.size)
	var center := Vector2(_world_rect.get_center())
	
	limit_enabled = true
	
	# Eixo X
	if view.x >= world.x:
		# Visão maior que o mundo → trava no centro
		limit_left = int(center.x)
		limit_right = int(center.x)
	else:
		limit_left = _world_rect.position.x
		limit_right = _world_rect.end.x
	
	# Eixo Y
	if view.y >= world.y:
		limit_top = int(center.y)
		limit_bottom = int(center.y)
	else:
		limit_top = _world_rect.position.y
		limit_bottom = _world_rect.end.y
# ====================
# Input
# ====================
func _unhandled_input(event: InputEvent) -> void:
	# Zoom continua funcionando mesmo com input_enabled = false
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_zoom_by(ZOOM_FACTOR)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_zoom_by(1.0 / ZOOM_FACTOR)
			MOUSE_BUTTON_LEFT:
				if not input_enabled:
					return
				if event.pressed:
					_start_drag()
				else:
					_end_drag()
	
	elif event is InputEventMouseMotion and _pressed and input_enabled:
		_do_drag(event.relative)
	
	# === TOUCH (celular) ===
	elif event is InputEventScreenTouch:
		if not input_enabled:
			return
		if event.pressed:
			# Só começa a arrastar se ainda não tiver nenhum dedo
			if _touch_index == -1:
				_touch_index = event.index
				_start_drag()
		else:
			if event.index == _touch_index:
				_touch_index = -1
				_end_drag()
	
	elif event is InputEventScreenDrag:
		if not input_enabled:
			return
		# Só arrasta com o dedo que iniciou o gesto
		if event.index == _touch_index and _pressed:
			_do_drag(event.relative)
	
	# Pinch (já existia)
	elif event is InputEventMagnifyGesture:
		_zoom_by(event.factor)


func _start_drag() -> void:
	_pressed = true
	_dragged = 0.0


func _end_drag() -> void:
	if _pressed and _dragged < TAP_MAX_DRAG:
		tapped.emit(Vector2i(get_global_mouse_position()))
	_pressed = false


func _do_drag(relative: Vector2) -> void:
	_dragged += relative.length()
	position -= relative / zoom
