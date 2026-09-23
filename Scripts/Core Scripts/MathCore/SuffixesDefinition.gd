# ====================
# Class & Extend
# ====================
class_name Suffixes
extends Resource


# ====================
# Data
# ====================
@export var suffixes_id : StringName
@export var units_names : Array[String]
@export var units_suffixes : Array[String]


# ====================
# Auto suffixes
# ====================
func autoSuffixes() -> void:
	units_suffixes.clear()
	
	for unit in units_names:
		if unit == "":
			units_suffixes.append("")
			continue
		
		var suf := ""
		for i in range(unit.length()):
			suf = suf + unit[i]
			if not units_suffixes.has(suf):
				break
		
		while units_suffixes.has(suf):
			suf = suf + "*"
		
		units_suffixes.append(suf)
