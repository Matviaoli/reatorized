# ====================
# Class & Extend
# ====================
class_name Regions
extends Resource


# ====================
# Data
# ====================
@export var id: StringName
@export var region_name: String
@export_multiline var description: String
@export var unlocked_by_default := true
@export var price := 0.0
@export var needed_regions : Array[Regions]
# @export var needed_achiviments : Array[Achiviments]
# Mais tarde adicionar conquistas para desbloquear certas regiões
@export var region_area : Array[Rect2i]
	
