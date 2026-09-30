# ====================
# Class & Extend
# ====================
class_name SlidePanel
extends PanelContainer


# ====================
# Signals
# ====================
signal opened
signal closed


# ====================
# Side
# ====================
enum Side {LEFT, RIGHT}


# ====================
# Variables
# ====================
@export var side := Side.RIGHT
@export var duration := 0.35
@export var start_open := false

var is_open := false

var _open_left := 0.0
var _open_right := 0.0
var _closed_left := 0.0
var _closed_right := 0.0
var _tween: Tween


# ====================
# Wake (the fuck) up
# ====================
func _ready() -> void:
	
	var width := offset_right - offset_left
	var dir := 1.0 if side == Side.RIGHT else -1.0
	
	_open_left = offset_left
	_open_right = offset_right
	_closed_left = _open_left + width * dir
	_closed_right = _open_right + width * dir
	
	offset_left = _closed_left
	offset_right = _closed_right
	
	if start_open:
		is_open = true
		offset_left = _open_left
		offset_right = _open_right
		visible = true
	else:
		offset_left = _closed_left
		offset_right = _closed_right
		visible = false


# ====================
# Open
# ====================
func open() -> void:
	if is_open:
		return
	
	is_open = true
	_slide(_open_left, _open_right)
	opened.emit()


# ====================
# Close
# ====================
func close() -> void:
	if not is_open:
		return
	
	is_open = false
	_slide(_closed_left ,_closed_right)
	closed.emit()


# ====================
# Toggle
# ====================
func toggle() -> void:
	if is_open:
		close()
	else:
		open()


# ====================
# Slide
# ====================
func _slide(target_left: float, target_right: float) -> void:
	if _tween:
		_tween.kill()
	
	visible = true
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_OUT if is_open else Tween.EASE_IN)
	_tween.tween_property(self, "offset_left", target_left, duration)
	_tween.tween_property(self, "offset_right", target_right, duration)
	
	if not is_open:
		_tween.chain().tween_callback(func() -> void: visible = false)
