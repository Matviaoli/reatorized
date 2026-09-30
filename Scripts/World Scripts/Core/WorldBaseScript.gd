# ====================
# Class & Extend
# ====================
class_name WorldBase
extends Node2D


# ====================
# Consts
# ====================
const HUD_SCENE := preload("res://Scripts/Core Scripts/Interface/Core_UI/Hud.tscn")

# ====================
# Configs
# ====================
@export var world_id : StringName
@export var world_name := "Betalands"
@export var debug_mode := false
@export var world_size := Vector2i(50, 50)
@export var tile_size := Vector2i(16, 16)
@export var start_zoom := 3.0
@export var starting_money_mantissa := 100.0
@export var starting_money_exponent := 0
@export var starting_time := 9000
@export_dir var regions_folder : String


# ====================
# Variables
# ====================
@onready var terrain : TerrainLayer = $TerrainLayer
@onready var structures : StructureLayer = $StructureLayer
var simulation : Simulation
var camera : WorldCamera
var day_tint : CanvasModulate
var waves : WaveOcean
var placement : PlacementController
var hud : Hud
var regionsManager : RegionsManager
var cloud_layer : CloudLayer

var _tool : StringName = Hud.TOOL_NONE
var _last_painted_cell : Vector2i
var _has_last_painted_cell := false


# ====================
# Wake up
# ====================
func _ready() -> void:
	structures.terrainLayer = terrain
	terrain.import_painted_cells()
	structures.import_painted_cells()
	
	simulation = Simulation.new()
	simulation.structures = structures
	simulation.money = OverInfinity.to_load([starting_money_mantissa, starting_money_exponent])
	simulation.time = starting_time
	simulation.exploded.connect(_on_exploded)
	add_child(simulation)
	
	camera = WorldCamera.new()
	camera.set_bounds(Rect2i(Vector2i.ZERO, world_size * tile_size))
	camera.zoom = Vector2.ONE * start_zoom
	add_child(camera)
	camera.make_current()
	
	regionsManager = RegionsManager.new()
	regionsManager.world_folder = regions_folder
	regionsManager.name = "RegionsManager"
	regionsManager.setup()
	
	cloud_layer = CloudLayer.new()
	cloud_layer.name = "CloudLayer"
	cloud_layer.regionsManager = regionsManager
	cloud_layer.clouds_folder = "res://Visual/Paper/Clouds"  # sua pasta
	cloud_layer.terrain = terrain
	cloud_layer.tileSize = tile_size
	cloud_layer.z_index = 7
	add_child(cloud_layer)
	cloud_layer.setup()
	move_child(cloud_layer, get_child_count() - 1)
	
	placement = PlacementController.new()
	placement.terrain = terrain
	placement.structures = structures
	placement.simulation = simulation
	placement.regionsManager = regionsManager
	placement.tile_size = tile_size
	add_child(placement)
	
	hud = HUD_SCENE.instantiate()
	hud.simulation = simulation
	hud.placement = placement
	add_child(hud)
	hud.setup(_get_buildables())
	hud.tool_selected.connect(_on_tool_selected)
	
	waves = WaveOcean.new()
	waves.terrain_layer = terrain
	waves.wave_texture = preload("res://Visual/Paper/Waves/Wave(placeholder).png")
	add_child(waves)
	waves.setup(world_size, tile_size)
	
	day_tint = CanvasModulate.new()
	add_child(day_tint)
	
	_generate()

func _process(_delta: float) -> void:
	if simulation == null:
		return
	var d := simulation.get_daylight()
	# noite azulada -> dia branco, com um leve alaranjado no meio do caminho
	var night := Color(0.25, 0.3, 0.55)
	var noon := Color(1.0, 1.0, 1.0)
	day_tint.color = night.lerp(noon, d)

# ====================
# Generate
# ====================
func _generate() -> void:
	pass

# ====================
# Assemblying
# ====================
func _get_buildables() -> Array[StructureTile]:
	var out: Array[StructureTile] = []
	
	for def in structures.definitions.values():
		var structure := def as StructureTile
		
		if structure and structure.purchasable:
			out.append(structure)
			
	out.sort_custom(func(a: StructureTile, b: StructureTile) -> bool: return a.get_price().less_than(b.get_price()))
	return out

# ====================
# Interactions
# ====================
func _on_tool_selected(id: StringName) -> void:
	_tool = id
	placement.set_tool(id)
	camera.input_enabled = id == Hud.TOOL_NONE

func _unhandled_input(event: InputEvent) -> void:
	if _tool == Hud.TOOL_NONE:
		return
	
	# ===== MOUSE =====
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_start_paint(get_global_mouse_position(), true)   # true = adicionar
				else:
					_has_last_painted_cell = false
			
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					_start_paint(get_global_mouse_position(), false)  # false = remover
				else:
					_has_last_painted_cell = false
	
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_drag_paint(get_global_mouse_position(), true)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_drag_paint(get_global_mouse_position(), false)
		else:
			_has_last_painted_cell = false
	
	# ===== TOUCH (celular) =====
	elif event is InputEventScreenTouch:
		if event.pressed:
			# Dedo único = pintar (adicionar)
			_start_paint(event.position, true)
		else:
			_has_last_painted_cell = false
	
	elif event is InputEventScreenDrag:
		_drag_paint(event.position, true)

func _start_paint(world_pos: Vector2, add: bool) -> void:
	var cell := terrain.local_to_map(terrain.to_local(world_pos))
	_try_paint_cell(cell, add)
	_last_painted_cell = cell
	_has_last_painted_cell = true

func _drag_paint(world_pos: Vector2, add: bool) -> void:
	var cell := terrain.local_to_map(terrain.to_local(world_pos))
	
	if not _has_last_painted_cell:
		_try_paint_cell(cell, add)
		_last_painted_cell = cell
		_has_last_painted_cell = true
		return
	
	if cell == _last_painted_cell:
		return
	
	for c in _cells_between(_last_painted_cell, cell):
		_try_paint_cell(c, add)
	
	_last_painted_cell = cell

func _try_paint_cell(cell: Vector2i, add: bool) -> void:
	if terrain.data.has(cell):
		placement.handle_click(cell, add)

# Bresenham simples entre duas células (exclui a origem, inclui o destino)
func _cells_between(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var dx := absi(to.x - from.x)
	var dy := -absi(to.y - from.y)
	var sx := 1 if from.x < to.x else -1
	var sy := 1 if from.y < to.y else -1
	var err := dx + dy
	var cur := from
	
	while cur != to:
		var e2 := err * 2
		if e2 >= dy:
			err += dy
			cur.x += sx
		if e2 <= dx:
			err += dx
			cur.y += sy
		out.append(cur)
	
	return out

func _on_exploded(cell: Vector2i, _power: float) -> void:
	hud.show_message("Explosão em %d, %d" % [cell.x, cell.y])
