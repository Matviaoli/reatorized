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

# ====================
# Bounds
# ====================
func set_bounds(rect: Rect2i) -> void:
	limit_left = rect.position.x
	limit_top = rect.position.y
	limit_right = rect.end.x
	limit_bottom = rect.end.y
	position = Vector2(rect.get_center())

# ====================
# Zoom
# ====================
func _zoom_by(factor: float) -> void:
	var z := clampf(zoom.x * factor, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(z, z)

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
