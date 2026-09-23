# ====================
# Class & Extend
# ====================
class_name Hud
extends CanvasLayer


# ====================
# Signals & Consts
# ====================
signal tool_selected(tool_id: StringName)

const TOOL_NONE := &""
const TOOL_DEMOLISH := &"__demolish"
const FONT_SIZE := 22


# ====================
# Variables
# ====================
var simulation : Simulation

var _stats : Label
var _message : Label
var _bar : HBoxContainer
var _buttons := {}
var _selected : StringName = TOOL_NONE
var _tween : Tween


# ====================
# Wake up
# ====================
func _ready() -> void:
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	for side in ["left", "top", "right", "bottom"]:
		root.add_theme_constant_override("margin_" + side, 8)
	
	add_child(root)
	
	var columm := VBoxContainer.new()
	columm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(columm)
	
	_stats = _make_label()
	columm.add_child(_stats)
	_message = _make_label()
	columm.add_child(_message)
	
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columm.add_child(scroll)
	
	_bar = HBoxContainer.new()
	scroll.add_child(_bar)


# ====================
# Setup
# ====================
func setup(buildables: Array[StructureTile]) -> void:
	var sell := _make_button("Vender energia")
	sell.pressed.connect(func() -> void: simulation.sell_energy(simulation.energy))
	_bar.add_child(sell)
	
	_add_tool_button(TOOL_DEMOLISH, "Demolir")
	
	for def in buildables:
		var label := def.display_name if not def.display_name.is_empty() else String(def.id)
		_add_tool_button(def.id, "%s (%d)" % [label, int(def.price)])


# ====================
# Process
# ====================
func _process(delta : float) -> void:
	if simulation == null:
		return
	
	_stats.text = "energia %d/%d  |  Dinheiro %d  |  Poluição %.1f  |  Ciência %d" % [
		int(simulation.energy), int(simulation.maxEnergy), int(simulation.money), simulation.GlobalPollution, int(simulation.science)]


# ====================
# Show message
# ====================
func show_message(text: String) -> void:
	_message.text = text
	_message.modulate.a = 1.0
	
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(1.5)
	_tween.tween_property(_message, "modulate", 0.0, 0.5)


# ====================
# Helpers
# ====================
func _add_tool_button(id: StringName, text: String) -> void:
	var button := _make_button(text)
	button.toggle_mode = true
	button.pressed.connect(_select.bind(id))
	_bar.add_child(button)
	_buttons[id] = button

func _select(id: StringName) -> void:
	_selected = TOOL_NONE if _selected == id else id
	
	for key in _buttons:
		_buttons[key].set_pressed_no_signal(key == _selected)
	
	tool_selected.emit(_selected)

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 64)
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	
	return button

func _make_label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	
	return label
