# ====================
# Class & Extend
# ====================
class_name WorldCamera
extends Camera2D


# ====================
# Signal & Consts
# ====================
signal tapped(world_position: Vector2i)

const TAP_MAX_DRAG := 12.0 # Basicamente, quantos pixel a pessoa tem que mover para um 'toque' virar 'arrasto'
const MIN_ZOOM := 0.5
const MAX_ZOOM := 6.0
const ZOOM_FACTOR := 1.1


# ====================
# Variables
# ====================
var _pressed := false
var _dragged := 0.0


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
	if event is InputEventMouseButton:
		match event.button_index:
			
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_pressed = true
					_dragged = 0.0
				
				else:
					if _pressed and _dragged < TAP_MAX_DRAG:
						tapped.emit(get_global_mouse_position())
					_pressed = false
			
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_zoom_by(ZOOM_FACTOR)
			
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_zoom_by(1.0 / ZOOM_FACTOR)
	
	elif event is InputEventMouseMotion and _pressed:
		_dragged += event.relative.length()
		position -= event.relative / zoom
	
	elif event is InputEventMagnifyGesture:
		_zoom_by(event.factor)
