# ====================
# Class & Extend
# ====================
class_name PlacementController
extends Node


# ====================
# Signals
# ====================
signal changed


# ====================
# Data
# ====================
var terrain: TerrainLayer
var structures: StructureLayer
var simulation: Simulation
var regionsManager : RegionsManager
var tile_size := Vector2i(16, 16)

var tool: StringName = &""
var pending: Dictionary = {}  # Vector2i -> true

var _preview_layer: TileMapLayer
var _demolish_overlay: Node2D


# ====================
# Wake up
# ====================
func _ready() -> void:
	_preview_layer = TileMapLayer.new()
	_preview_layer.tile_set = structures.tile_set
	_preview_layer.modulate = Color(1, 1, 1, 0.5)
	_preview_layer.z_index = 5
	structures.get_parent().add_child(_preview_layer)
	
	_demolish_overlay = Node2D.new()
	_demolish_overlay.z_index = 6
	_demolish_overlay.draw.connect(_draw_demolish_overlay)
	structures.get_parent().add_child(_demolish_overlay)


# ====================
# Set tool
# ====================
func set_tool(id: StringName) -> void:
	cancel()
	tool = id


# ====================
# Handle click
# ====================
# --- Handle click ---
func handle_click(cell: Vector2i, add: bool) -> void:
	if tool == &"":
		return
	
	if simulation.auto_build:
		if not add:      
			return
		
		
		if tool == Hud.TOOL_DEMOLISH:
			structures.remove(cell)
		else:
			simulation.buy_structure(cell, tool)
		return
	
	_paint(cell, add)

# --- Paint ---
func _paint(cell: Vector2i, add: bool) -> void:
	if not regionsManager.is_cell_unlocked(cell):
		return
	
	if add:
		if tool == Hud.TOOL_DEMOLISH:
			if not structures.data.has(cell):
				return
			
		elif not structures.can_place(cell, tool):
			return
		
		pending[cell] = true
		
	else:
		pending.erase(cell)
	
	_refresh_preview()


# ====================
# Preview
# ====================
# --- Refresh preview ---
func _refresh_preview() -> void:
	_preview_layer.clear()
	
	if tool != Hud.TOOL_DEMOLISH and tool != &"":
		for cell in pending:
			var visual: BaseTileMapLayer.TileVisual = structures._pick_visual(cell, tool, TileDefinition.DEFAULT_STATE)
			_preview_layer.set_cell(cell, visual.source_id, visual.coords)
	
	_demolish_overlay.queue_redraw()
	changed.emit()

# --- Draw demolish ---
func _draw_demolish_overlay() -> void:
	if tool != Hud.TOOL_DEMOLISH:
		return
		
	var size := Vector2(tile_size)
	
	for cell in pending:
		var rect := Rect2(Vector2(cell) * size, size)
		_demolish_overlay.draw_rect(rect, Color(1.0, 0.2, 0.2, 0.35))


# ====================
# Get total cost
# ====================
func get_total_cost() -> OverInfinity:
	if tool == Hud.TOOL_DEMOLISH or tool == &"":
		return OverInfinity.zero()
	
	var def := structures.get_definition(tool) as StructureTile
	if def == null:
		return OverInfinity.zero()
	
	return def.get_price().multiply_scalar(pending.size())


# ====================
# Confirm
# ====================
# --- Confirm ---
func confirm() -> void:
	if pending.is_empty():
		return
	
	if tool == Hud.TOOL_DEMOLISH:
		for cell in pending:
			structures.remove(cell)
	else:
		for cell in pending:
			if not simulation.buy_structure(cell, tool):
				break  
	cancel()
	set_tool(Hud.TOOL_NONE)

# --- Cancel ---
func cancel() -> void:
	pending.clear()
	_preview_layer.clear()
	_demolish_overlay.queue_redraw()
	changed.emit()
	tool = Hud.TOOL_NONE
