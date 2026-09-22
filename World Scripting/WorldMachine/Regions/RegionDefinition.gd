# ====================
# Class & Extend
# ====================
class_name RegionDefinition
extends Resource


# ====================
# Data
# ====================
@export var id: StringName
@export var display_name: String
@export var area := Rect2i(0, 0, 24, 16)
@export var unlockedByDefault := true
@export var unlockWithMoney := true
@export var unlockCost := 0.0
@export var regionsRequires : Array[RegionDefinition]
# Mais tarte adicionar sistema de conquistas
# @export var achivimentsRequires : Array[AchivimentsDefinitions]
