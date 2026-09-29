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

# --- category order ---
const CATEGORY_ORDER := [
	StructureTile.structureType.REACTOR,
	StructureTile.structureType.GENERATOR,
	StructureTile.structureType.BATTERY,
	StructureTile.structureType.OFFICE,
	StructureTile.structureType.SEARCH,
	StructureTile.structureType.POLLUTION,
	StructureTile.structureType.SUPPORT,
	StructureTile.structureType.DEBRIS
]

# --- category labels ---
const CATEGORY_LABELS := {
	StructureTile.structureType.REACTOR: "Reatores",
	StructureTile.structureType.GENERATOR: "Geradores",
	StructureTile.structureType.BATTERY: "Baterias",
	StructureTile.structureType.OFFICE: "Escritórios",
	StructureTile.structureType.SEARCH: "Laboratórios",
	StructureTile.structureType.POLLUTION: "Poluição",
	StructureTile.structureType.SUPPORT: "Extras",
	StructureTile.structureType.DEBRIS: "Detritos"
}


# ====================
# Nodes 
# ====================
@onready var _layout: Control = %Layout

@onready var _stats: Label = %StatsLabel
@onready var _message: Label = %MenssageLabel
@onready var _mode_label: Label = %ModeLabel

@onready var _sell_button: Button = %SellButton
@onready var _sidebar_toggle: Button = %SidebarToggle
@onready var _sidebar: PanelContainer = %Sidebar

@onready var _build_button: Button = %BuildButton
@onready var _demolish_button: Button = %DemolishButton
@onready var _research_button: Button = %ResearchButton
@onready var _upgrade_button: Button = %UpgradesButton
@onready var _info_button: Button = %InfoButton
@onready var _config_button: Button = %ConfigButton

@onready var _build_panel: PanelContainer = %BuildPanel
@onready var _auto_toggle: CheckButton = %AutoBuildToggle
@onready var _categories_box: VBoxContainer = %CategoriesBox
@onready var _structures_box: VBoxContainer = %StructuresBox
@onready var _info_box: VBoxContainer = %InfoBox

@onready var _confirm_bar: HBoxContainer = %ConfirmBar
@onready var _cost_label: Label = %CostLabel
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton
@onready var _leave_button: Button = %LeaveButton

# ====================
# Groups
# ====================
var all_itens := [_layout]
var occult_on_tool := [_build_panel, _sidebar, _sell_button, _sidebar_toggle]
var occult_on_demolish := [_sidebar, _sell_button, _sidebar_toggle]

# ====================
# Variables
# ====================
# --- Is open? ---
var _sidebar_open := true
var _build_menu_open := false

# --- Tween ---
var _sidebar_open_x := 0.0 
var _sidebar_closed_x := -200.0
var _sidebar_tween: Tween

var _build_menu_open_x := 0.0
var _build_menu_closed_x := 300.0
var _build_menu_tween: Tween

var _message_tween: Tween
var _selected_tool: StringName = TOOL_NONE
var _selected_category: int = StructureTile.structureType.NONE

var simulation: Simulation
var placement: PlacementController
var buildables: Array[StructureTile] = []


# ====================
# Wake up
# ====================
func _ready() -> void:
	# --- init groups ---
	all_itens = [_layout]
	occult_on_tool = [_build_panel, _sidebar, _sell_button, _sidebar_toggle]
	occult_on_demolish = [_sidebar, _sell_button, _sidebar_toggle]
	
	# --- Tween ---
	_sidebar_open_x = _sidebar.position.x
	_sidebar_closed_x += _sidebar_open_x 
	
	_build_menu_open_x = _build_panel.position.x
	_build_menu_closed_x += _build_menu_open_x
	_build_panel.position.x = _build_menu_closed_x
	
	_leave_button.pressed.connect(_cancel)
	_sell_button.pressed.connect(func() -> void: simulation.sell_energy(simulation.energy))
	_sidebar_toggle.pressed.connect(_toggle_sidebar)
	_build_button.pressed.connect(_open_build_menu)
	_demolish_button.pressed.connect(func() -> void: _select_tool(TOOL_DEMOLISH))
	_auto_toggle.toggled.connect(func(pressed: bool) -> void: simulation.auto_build = pressed)
	_confirm_button.pressed.connect(_confirm)
	_cancel_button.pressed.connect(_cancel)
	
	_build_panel.visible = true
	_confirm_bar.visible = false
	_leave_button.visible = false
	_auto_toggle.button_pressed = simulation.auto_build
	
	_mode_label.visible = false
	_mode_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_mode_label.modulate = Color(1.0, 0.35, 0.3) 


func setup(p_buildables: Array[StructureTile]) -> void:
	buildables = p_buildables
	_refresh_categories()


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
	_sidebar_open = not _sidebar_open
	
	if _sidebar_tween:
		_sidebar_tween.kill()
	_sidebar_tween = create_tween()
	var target_x := _sidebar_open_x if _sidebar_open else -200.0
	_sidebar_tween.tween_property(_sidebar, "position:x", target_x, 0.25)


# ====================
# Painel de construção
# ====================
# --- open build menu ---
func _open_build_menu() -> void:
	if _selected_tool != TOOL_NONE:
		_selected_tool = TOOL_NONE
		tool_selected.emit(TOOL_NONE)
		
		_update_mode_label()
		reveal(occult_on_tool)
	
	_build_menu_open = not _build_menu_open
	
	if _build_menu_open:
		_show_categories()
	
	_toggle_build_menu()
	

# --- toggle build menu ---
func _toggle_build_menu() -> void:
	if _build_menu_tween:
		_build_menu_tween.kill()
	
	_build_menu_tween = create_tween()
	_build_menu_tween.set_ease(Tween.EASE_OUT if _build_menu_open else Tween.EASE_IN)
	_build_menu_tween.set_trans(Tween.TRANS_CUBIC)
	
	var target_x := _build_menu_open_x if _build_menu_open else _build_menu_closed_x
	_build_menu_tween.tween_property(_build_panel, "position:x", target_x, 0.35)

# --- refresh categories ---
func _refresh_categories() -> void:
	for child in _categories_box.get_children():
		child.queue_free()

	for category in CATEGORY_ORDER:
		var has_unlocked := buildables.any(func(def: StructureTile) -> bool:
			return def.type == category and def.unlocked
		)
		if not has_unlocked:
			continue
		var button := _make_button(CATEGORY_LABELS[category])
		button.pressed.connect(_show_structures.bind(category))
		_categories_box.add_child(button)


func _show_categories() -> void:
	_categories_box.visible = true
	_structures_box.visible = false
	_info_box.visible = false


func _show_structures(category: int) -> void:
	_selected_category = category
	_categories_box.visible = false
	_structures_box.visible = true
	_info_box.visible = false
	
	for child in _structures_box.get_children():
		child.queue_free()
	
	var back := _make_button("< Voltar")
	back.pressed.connect(_show_categories)
	_structures_box.add_child(back)
	
	for def in buildables:
		if def.type != category or not def.unlocked:
			continue
		var label := def.display_name if not def.display_name.is_empty() else String(def.id)
		var button := _make_button("%s (%s)" % [label, def.get_price().to_display_string()])
		button.pressed.connect(_show_structure_info.bind(def))
		_structures_box.add_child(button)


func _show_structure_info(def: StructureTile) -> void:
	_structures_box.visible = false
	_info_box.visible = true
	
	for child in _info_box.get_children():
		child.queue_free()
	
	var back := _make_button("< Voltar")
	back.pressed.connect(_show_structures.bind(_selected_category))
	_info_box.add_child(back)
	
	var name_label := _make_label()
	name_label.text = def.display_name if not def.display_name.is_empty() else String(def.id)
	_info_box.add_child(name_label)
	
	var desc_label := _make_label()
	desc_label.text = def.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_info_box.add_child(desc_label)
	
	var price_label := _make_label()
	price_label.text = "Preço: %s" % def.get_price().to_display_string()
	_info_box.add_child(price_label)
	
	var build_btn := _make_button("Construir")
	build_btn.pressed.connect(_select_tool.bind(def.id))
	_info_box.add_child(build_btn)


func _select_tool(id: StringName) -> void:
	_selected_tool = TOOL_NONE if _selected_tool == id else id
	tool_selected.emit(_selected_tool)
	
	if _selected_tool != TOOL_NONE:
		occult(occult_on_tool)
	else:
		pass

	_update_mode_label()


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
# Makers
# ====================
func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _make_label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label


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
