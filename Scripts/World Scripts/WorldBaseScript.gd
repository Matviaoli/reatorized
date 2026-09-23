# ====================
# Class & Extend
# ====================
class_name WorldBase
extends Node2D


# ====================
# Consts
# ====================
const TERRAIN_LAYER_SCENE := preload("res://Scripts/TileLayer/TerrainLayer.tscn")
const STRUCTURE_LAYER_SCENE := preload("res://Scripts/TileLayer/StructureLayer.tscn")


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
@export var starting_time := 900
@export var terrain_texture: Texture2D = preload("res://Visual/TileMaps/TerrainTilemapBeta.png")
@export var structures_texture: Texture2D = preload("res://Visual/TileMaps/StructuresTileMapBeta.png")
@export_dir var terrain_folder := "res://Objects/Terrain"
@export_dir var structures_folder := "res://Objects/Structures"


# ====================
# Variables
# ====================
var terrain : TerrainLayer
var structures: StructureLayer
var simulation : Simulation
var camera : WorldCamera
var hud : Hud
var day_tint : CanvasModulate

var _tool : StringName = Hud.TOOL_NONE


# ====================
# Wake up
# ====================
func _ready() -> void:
	terrain = _make_layer(TERRAIN_LAYER_SCENE, terrain_texture, terrain_folder) as TerrainLayer
	structures = _make_layer(STRUCTURE_LAYER_SCENE, structures_texture, structures_folder) as StructureLayer
	
	structures.terrainLayer = terrain
	
	simulation = Simulation.new()
	simulation.structures = structures
	simulation.money = OverInfinity.to_load([starting_money_mantissa, starting_money_exponent])
	print("dinheiro inicial registrado: " + simulation.money.to_display_string())
	print(simulation.money.mantissa + simulation.money.exponent)
	simulation.time = starting_time
	simulation.exploded.connect(_on_exploded)
	
	add_child(simulation)
	
	camera = WorldCamera.new()
	camera.set_bounds(Rect2i(Vector2i.ZERO, world_size * tile_size))
	camera.zoom = Vector2.ONE * start_zoom
	camera.tapped.connect(_on_tap)
	
	add_child(camera)
	camera.make_current()
	
	hud = Hud.new()
	hud.simulation = simulation
	
	add_child(hud)
	
	hud.setup(_get_buildables())
	hud.tool_selected.connect(func(id: StringName) -> void: _tool = id)
	
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
func _make_layer(scene: PackedScene, texture : Texture2D, folder: String) -> BaseTileMapLayer:
	var layer := scene.instantiate() as BaseTileMapLayer
	layer.definitions_folder = folder
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	if layer.tile_set == null:
		layer.tile_set = _make_tileset(texture)
	
	add_child(layer)
	
	return layer

func _make_tileset(texture: Texture2D) -> TileSet:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = tile_size
	var cols := floori(float(texture.get_width()) / tile_size.x)
	var rows := floori(float(texture.get_height()) / tile_size.y)
	
	for x in cols:
		for y in rows:
			atlas.create_tile(Vector2i(x, y))
	
	var tile_set := TileSet.new()
	tile_set.tile_size = tile_size
	tile_set.add_source(atlas, BaseTileMapLayer.SOURCE_ID)
	
	return tile_set

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
func _on_tap(world_position: Vector2) -> void:
	var cell := terrain.local_to_map(terrain.to_local(world_position))
	
	if not  terrain.data.has(cell):
		return
	
	match _tool:
		Hud.TOOL_NONE:
			return
		
		Hud.TOOL_DEMOLISH:
			structures.remove(cell)
		
		_:
			if not simulation.buy_structure(cell, _tool):
				hud.show_message(_why_not(cell, _tool))

func _why_not(cell: Vector2i, id: StringName) -> String:
	if structures.data.has(cell):
		return "Já tem uma estrutura aí"
	
	if not structures.can_place(cell, id):
		return "Não dá para construir '%s' nesse terreno" % [structures.definitions[id].display_name]
	
	return "Dinehiro insuficiente"

func _on_exploded(cell: Vector2i, _power: float) -> void:
	hud.show_message("Explosão em %d, %d" % [cell.x, cell.y])
