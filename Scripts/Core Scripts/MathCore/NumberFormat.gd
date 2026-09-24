# ====================
# Class & Extend
# ====================
class_name NumberFormat
extends RefCounted


# ====================
# mode
# ====================
enum Type { # A maioria desses estão só para meme, mas acho engraçado
	NORMAL,			# mil, milhão, bilhão...
	SCIENTIFIC,		# e3, e6, e9 ...
	MILITARY,		# Alpha, Bravo, Charlie...
	SIM_PREFIX,		# Kilo, Mega, Giga...
	LETTERS,		# AA, AB, AC...
	GREEK			# Alpha, Beta, Delta...
}

enum Mode {
	FULL_NAME,
	PREFFIX
}


# ====================
# format constructor
# ====================
static func format(value: OverInfinity, mode: Mode, type: Type, suffixes: Suffixes = null, decimals: int = 2) -> String:
	if value.is_zero() or value.exponent < 3:
		return "%.*f" % [decimals, value.to_float()]
	
	match type:
		Type.NORMAL:
			return _with_list(value, suffixes)
