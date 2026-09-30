# ====================
# Class & Extend
# ====================
class_name Hud
extends CanvasLayer


# ====================
# Siganls & Consts
# ====================
signal tool_selected(tool_id: StringName)

const TOOL_NONE := &""
const TOOL_DEMOLISH := &"__demolish"
const FONT_SIZE := 22


# ====================
# Nodes 
# ====================
@onready var _layout: Control = %Layout

@onready var _stats: Label = %StatsLabel
@onready var _message: Label = %MenssageLabel
@onready var _mode_label: Label = %ModeLabel

@onready var _sell_button: Button = %SellButton
@onready var _sidebar_toggle: Button = %SidebarToggle
@onready var _sidebar: Sidebar = %Sidebar

@onready var _build_panel: BuildPanel = %BuildPanel
@onready var _research_panel: SlidePanel = %ResearchPanel
@onready var _upgrades_panel: SlidePanel = %UpgradesPanel

@onready var _confirm_bar: HBoxContainer = %ConfirmBar
@onready var _cost_label: Label = %CostLabel
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton
@onready var _leave_button: Button = %LeaveButton

# ====================
# Groups
# ====================
var all_itens := [_layout]
var occult_on_tool = [_sidebar, _sell_button, _sidebar_toggle]
var occult_on_demolish := [_sidebar, _sell_button, _sidebar_toggle]

# ====================
# Variables
# ====================
var _message_tween: Tween
var _selected_tool: StringName = TOOL_NONE

var simulation: Simulation
var placement: PlacementController
var buildables: Array[StructureTile] = []

var _panels: Array[SlidePanel]


# ====================
# Wake up
# ====================
func _ready() -> void:
	# --- init groups ---
	all_itens = [_layout]
	occult_on_tool = [_sidebar, _sell_button, _sidebar_toggle]
	occult_on_demolish = [_sidebar, _sell_button, _sidebar_toggle]
	
	_panels = [_build_panel]
	
	_sidebar.side = SlidePanel.Side.LEFT
	_sidebar.build_pressed.connect(_toggle_exclusive.bind(_build_panel))
	_sidebar.research_pressed.connect(_toggle_exclusive.bind(_research_panel))
	_sidebar.upgrades_pressed.connect(_toggle_exclusive.bind(_upgrades_panel))
	_sidebar.demolish_pressed.connect(func() -> void: _select_tool(TOOL_DEMOLISH))
	
	_build_panel.build_requested.connect(_select_tool)
	_build_panel.auto_build_toggled.connect(func(on: bool) -> void: simulation.auto_build = on)
	
	_leave_button.pressed.connect(_cancel)
	_sell_button.pressed.connect(func() -> void: simulation.sell_energy(simulation.energy))
	_sidebar_toggle.pressed.connect(_toggle_sidebar)
	_confirm_button.pressed.connect(_confirm)
	_cancel_button.pressed.connect(_cancel)
	
	_confirm_bar.visible = false
	_leave_button.visible = false
	
	_mode_label.visible = false
	_mode_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_mode_label.modulate = Color(1.0, 0.35, 0.3) 


# ====================
# Setup
# ====================
func setup(p_buildables: Array[StructureTile]) -> void:
	buildables = p_buildables
	_build_panel.setup(p_buildables, simulation.auto_build)


# ====================
# Confirm/Cancel
# ====================
# --- Confirm ---
func _confirm() -> void:
	placement.confirm()
	_exit_tool_mode()

# --- Cancel ---
func _cancel() -> void:
	placement.cancel()
	_exit_tool_mode()

# ====================
# Sidebar
# ====================
func _toggle_sidebar() -> void:
	_sidebar.toggle()


# ====================
# Toggle exclusive
# ====================
func _toggle_exclusive(panel: SlidePanel) -> void:
	for p in _panels:
		if p != panel:
			p.close()
	panel.toggle()


# ====================
# Select tool
# ====================
func _select_tool(id: StringName) -> void:
	_selected_tool = TOOL_NONE if _selected_tool == id else id
	tool_selected.emit(_selected_tool)
	
	if _selected_tool != TOOL_NONE:
		_build_panel.close()
		occult(occult_on_tool)
	
	_update_mode_label()


# ====================
# Update mode label
# ====================
func _update_mode_label() -> void:
	if _selected_tool == TOOL_DEMOLISH:
		_mode_label.text = "Modo Demolição"
		_mode_label.visible = true
		_mode_label.modulate = Color(1.0, 0.35, 0.3)
	elif _selected_tool != TOOL_NONE:
		var def: StructureTile = null
		for b in buildables:
			if b.id == _selected_tool:
				def = b
				break
		
		if def:
			var name := def.display_name if not def.display_name.is_empty() else String(def.id)
			_mode_label.text = "Construindo: %s" % name
			_mode_label.visible = true
			_mode_label.modulate = Color(0.4, 0.85, 1.0)  # azul claro
		else:
			_mode_label.visible = false
	else:
		_mode_label.visible = false

# ====================
# Process
# ====================
func _process(_delta: float) -> void:
	if simulation == null:
		return

	_stats.text = "Energia %s/%s  |  Dinheiro %s  |  Ciência %s  |  Horário: %02d:%02d" % [
		simulation.energy.to_display_string(),
		simulation.maxEnergy.to_display_string(),
		simulation.money.to_display_string(),
		simulation.science.to_display_string(),
		simulation.clock[0],
		simulation.clock[1]
	]

	if placement == null:
		return
	
	var in_tool := _selected_tool != TOOL_NONE
	var has_pending := not placement.pending.is_empty()
	
	_confirm_bar.visible = not simulation.auto_build and in_tool
	
	if _confirm_bar.visible:
		if has_pending:
			_cost_label.text = "Total: %s" % placement.get_total_cost().to_display_string()
		else:
			_cost_label.text = "Nada selecionado"
	
	_leave_button.visible = simulation.auto_build and in_tool


func show_message(text: String) -> void:
	_message.text = text
	_message.modulate.a = 1.0
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(1.5)
	_message_tween.tween_property(_message, "modulate", 0.0, 0.5)


# ====================
# Exit tool
# ====================
func _exit_tool_mode() -> void:
	reveal(occult_on_tool)   # restaura sidebar, botões, etc.
	_selected_tool = TOOL_NONE
	tool_selected.emit(TOOL_NONE)
	_leave_button.visible = false
	_update_mode_label()


# ====================
# Visible functions
# ====================
# --- Occult ---
func occult(objs: Array) -> void:
	for o in objs:
		if o is CanvasItem:
			o.visible = false

# --- Reveal ---
func reveal(objs: Array) -> void:
	for o in objs:
		if o is CanvasItem:
			o.visible = true

# --- Flip visibilit ---
func flip_visibility(objs: Array) -> void:
	for o in objs:
		if o is CanvasItem:
			o.visible = not o.visible
