# ====================
# Class & Extend
# ====================
class_name StructureLayer
extends BaseTileMapLayer

# ====================
# Variables
# ====================
var terrainLayer: TerrainLayer
var heat := {}  # Vector2i -> OverInfinity

var _rotor_layer: Node2D
var _rotors := {} # Vector2i -> Sprite2D


# ====================
# Wake up
# ====================
func _ready() -> void:
	super._ready()
	_rotor_layer = Node2D.new()
	add_child(_rotor_layer)


# ====================
# Process
# ====================
func _process(delta: float) -> void:
	for sprite in _rotors.values():
		sprite.rotation += deg_to_rad(sprite.get_meta("speed")) * delta


# ====================
# Rotor bookkeeping
# ====================
# --- spawn rotor ---
func _spawn_rotor(cell: Vector2i, id: StringName) -> void:
	var def := definitions.get(id) as StructureTile
	if def == null or def.rotor_texture == null:
		return

	var sprite := Sprite2D.new()
	sprite.texture = def.rotor_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = map_to_local(cell) + def.rotor_offset
	sprite.set_meta("speed", def.rotor_speed)
	_rotor_layer.add_child(sprite)
	_rotors[cell] = sprite

# --- despawn rotor ---
func _despawn_rotor(cell: Vector2i) -> void:
	if not _rotors.has(cell):
		return
	_rotors[cell].queue_free()
	_rotors.erase(cell)


# ====================
# Can place
# ====================
func can_place(cell: Vector2i, id: StringName) -> bool:
	if not super.can_place(cell, id):
		return false

	var terrain := terrainLayer.get_definition_at(cell) as TerrainTile
	if terrain == null:
		return false

	var structure := definitions[id] as StructureTile
	if structure.allowedTerrains.is_empty():
		return terrain.buildable

	return terrain in structure.allowedTerrains


# ====================
# Behavior
# ====================
# --- apply cell ---
func _apply_cell(cell: Vector2i, id: StringName) -> void:
	super._apply_cell(cell, id)
	heat[cell] = OverInfinity.zero()

# --- register ---
func _register(cell: Vector2i, id: StringName) -> void:
	super._register(cell, id)
	heat[cell] = OverInfinity.zero()
	_spawn_rotor(cell, id)

# --- remove ---
func remove(cell: Vector2i) -> void:
	super.remove(cell)
	heat.erase(cell)
	_despawn_rotor(cell)

# --- clear all ---
func clear_all() -> void:
	super.clear_all()
	heat.clear()
	for cell in _rotors.keys().duplicate():
		_despawn_rotor(cell)
