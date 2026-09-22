## ====================
## Class & Extend
## ====================
class_name WorldBaseScript
extends Node2D


## ====================
## Data
## ====================
@export var flat_size := Vector2i(24, 24)
@export var starting_terrain_id: StringName = &"grass"


## ====================
## Refs (nomes dos nós na cena World.tscn)
## ====================
@onready var terrain: TerrainLayer = $TerrainLayer
@onready var structures: StructureLayer = $StructureLayer
@onready var simulation: Simulation = $Simulation
@onready var build_input: BuildInput = $BuildInput


## ====================
## Wake up
## ====================
func _ready() -> void:
	# Conecta as camadas entre si (não dá pra fazer isso 100% pelo Inspector
	# porque terrainLayer/structures são var normais, não @export tipadas
	# aceitando NodePath direto)
	structures.terrainLayer = terrain
	simulation.structures = structures
	build_input.structures = structures
	build_input.simulation = simulation

	_generate_flat_world()


## ====================
## Geração (manual/flat por enquanto)
## ====================
func _generate_flat_world() -> void:
	for x in range(flat_size.x):
		for y in range(flat_size.y):
			terrain.place(Vector2i(x, y), starting_terrain_id)
