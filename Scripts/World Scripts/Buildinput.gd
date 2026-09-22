## ====================
## Class & Extend
## ====================
class_name BuildInput
extends Node


## ====================
## Data
## ====================
# Ajuste essa lista com os ids que você já tem em Objects/Structures/*
var build_ids: Array[StringName] = [
	&"micro_generator",
	&"wind_turbine",
	&"Home_office",
	&"Garage_search",
]

var selected := 0


## ====================
## Refs (setados pelo WorldScript em _ready)
## ====================
var structures: StructureLayer
var simulation: Simulation


## ====================
## Input
## ====================
func _unhandled_input(event: InputEvent) -> void:
	if structures == null or simulation == null:
		return

	if event is InputEventKey and event.pressed:
		var idx = event.keycode - KEY_1
		if idx >= 0 and idx < build_ids.size():
			selected = idx
			print("Estrutura selecionada: ", build_ids[selected])

	if event is InputEventMouseButton and event.pressed:
		var cell := structures.local_to_map(structures.get_local_mouse_position())

		if event.button_index == MOUSE_BUTTON_LEFT:
			var placed := simulation.buy_structure(cell, build_ids[selected])
			if not placed:
				print("Não foi possível construir em ", cell)

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			structures.remove(cell)
