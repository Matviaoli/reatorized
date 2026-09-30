# ====================
# Makers
# ====================
class_name Sidebar
extends SlidePanel


# ====================
# Signals
# ====================
signal build_pressed
signal demolish_pressed
signal research_pressed
signal upgrades_pressed
signal info_pressed
signal config_pressed


# ====================
# Variables
# ====================
@onready var _build_button: Button = %BuildButton
@onready var _demolish_button: Button = %DemolishButton
@onready var _research_button: Button = %ResearchButton
@onready var _upgrades_button: Button = %UpgradesButton
@onready var _info_button: Button = %InfoButton
@onready var _config_button: Button = %ConfigButton


# ====================
# Wake up
# ====================
func _ready() -> void:
	super()
	_build_button.pressed.connect(build_pressed.emit)
	_demolish_button.pressed.connect(demolish_pressed.emit)
	_research_button.pressed.connect(research_pressed.emit)
	_upgrades_button.pressed.connect(upgrades_pressed.emit)
	_info_button.pressed.connect(info_pressed.emit)
	_config_button.pressed.connect(config_pressed.emit)
