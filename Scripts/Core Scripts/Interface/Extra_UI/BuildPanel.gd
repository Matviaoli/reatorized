# ====================
# Class & Extend
# ====================
class_name BuildPanel
extends SlidePanel


# ====================
# Signals
# ====================
signal build_requested(id: StringName)
signal auto_build_toggled(enabled: bool)
signal substitute_build_toggled(enabled: bool) # Mais tarde farei o modo construção também suportar substituição


# ====================
# Components
# ====================
@onready var _auto_toggle: CheckButton = %AutoBuildToggle
@onready var _substitute_toggle: CheckButton = %SubstituteModeToggle
@onready var _categories_box: VBoxContainer = %CategoriesBox
@onready var _structures_box: VBoxContainer = %StructuresBox
@onready var _info_box: VBoxContainer = %InfoBox
@onready var _exit_button: Button = %ExitBuild


# ====================
# Const
# ====================
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

# --- others ---
const FONT_SIZE := 22

# ====================
# Variables
# ====================
var buildables: Array[StructureTile] = []
var _selected_category: int = StructureTile.structureType.NONE


# ====================
# Wake up
# ====================
func _ready() -> void:
	super()
	_auto_toggle.toggled.connect(auto_build_toggled.emit)
	_substitute_toggle.toggled.connect(substitute_build_toggled.emit)
	_exit_button.pressed.connect(close)


# ====================
# Setup
# ====================
func setup(p_buildables: Array[StructureTile], auto_build: bool) -> void:
	buildables = p_buildables
	_auto_toggle.set_pressed_no_signal(auto_build)
	_refresh_categories()


# ====================
# Open
# ====================
func open() -> void:
	_show_categories()
	super()


# ====================
# Refresh Categories
# ====================
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


# ====================
# Show categories
# ====================
func _show_categories() -> void:
	_categories_box.visible = true
	_structures_box.visible = false
	_info_box.visible = false


# ====================
# Show structures
# ====================
func _show_structures(category: int) -> void:
	_selected_category = category
	_categories_box.visible = false
	_structures_box.visible = true
	_info_box.visible = false
	
	for child in _structures_box.get_children():
		child.queue_free()
	
	var back := _make_button("<- Voltar")
	back.pressed.connect(_show_categories)
	_structures_box.add_child(back)
	
	for def in buildables:
		if def.type != category or not def.unlocked:
			continue
			
		var label := def.display_name if not def.display_name.is_empty() else String(def.id)
		var button := _make_button("%s (%s)" % [label, def.get_price().to_display_string()])
		button.pressed.connect(_show_structure_info.bind(def))
		_structures_box.add_child(button)


# ====================
# Show structures info
# ====================
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
	build_btn.pressed.connect(build_requested.emit.bind(def.id))
	_info_box.add_child(build_btn)


# ====================
# Makers
# ====================
# --- Make button ---
func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	
	return button

# --- Make label ---
func _make_label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label
