# ====================
# Class & Extend
# ====================
class_name CloudPiece
extends  Node2D


# ====================
# Configs
# ====================
@export var string_length := 1280.0
@export var string_width := 1.0
@export var string_color := Color(0.92, 0.92, 0.95, 0.85)
@export var cloud_scale := 0.10

var sprite := Sprite2D.new()
var string := Line2D.new()

@export var sway_amount := 5.0      
@export var bob_amount := 2.0       
@export var sway_speed := 0.6      

var _base_pos := Vector2.ZERO
var _phase := 0.0
var _speed := 1.0

# ====================
# Setup
# ====================
func setup(tex: Texture2D, world_pos: Vector2) -> void:
	position = world_pos
	_base_pos = world_pos
	
	_phase = randf() * TAU
	_speed = randf_range(0.7, 1.3) * sway_speed
	
	sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.centered = true
	sprite.scale = Vector2.ONE * randf_range(0.85, 1.15) * cloud_scale
	sprite.rotation_degrees = randf_range(-8.0, 8.0)
	add_child(sprite)
	
	string = Line2D.new()
	string.width = string_width
	string.default_color = string_color
	string.antialiased = true
	string.points = PackedVector2Array([
		Vector2(0, -6),
		Vector2(randf_range(-4, 4), -string_length)
	])
	
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color(string_color.r, string_color.g, string_color.b, string_color.a),
		Color(string_color.r, string_color.g, string_color.b, 0.0)
	])
	string.gradient = grad
	add_child(string)
	move_child(string, 0)

# ====================
# Idle motion
# ====================
func _process(delta: float) -> void:
	_phase += delta * _speed
	
	var offset := Vector2(
		sin(_phase) * sway_amount,
		cos(_phase * 0.85) * bob_amount
	)
	position = _base_pos + offset


func stop_idle() -> void:
	set_process(false)
