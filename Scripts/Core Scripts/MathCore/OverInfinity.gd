# ====================
# Class & Extend
# ====================
class_name OverInfinity
extends RefCounted


# ====================
# Data
# ====================
const  SUFFIIXES = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "D"]

var mantissa: float = 0.0
var exponent: int = 0


# ====================
# Constructor
# ====================
static func zero() -> OverInfinity:
	return OverInfinity.new()

static func from_float(value: float) -> OverInfinity:
	var n := OverInfinity.new()
	
	if value == 0.0:
		return n
	
	var sing := 1.0 if value > 0.0 else -1.0
	value = absf(value)
	n.exponent = int(floor(log(value) / log(10.0)))
	n.mantissa = sing * value / pow(10.0, n.exponent)
	n._normalize()
	return n

static func from_int(value: int) -> OverInfinity:
	return OverInfinity.from_float(float(value))


# ====================
# Clone
# ====================
func clone() -> OverInfinity:
	var n:= OverInfinity.new()
	n.mantissa = mantissa
	n.exponent = exponent
	
	return n


# ====================
# Normalizar & set from
# ====================
func _normalize() -> void:
	if mantissa == 0.0:
		exponent = 0
		return
	
	while absf(mantissa) >= 10.0:
		mantissa /= 10.0
		exponent += 1
	
	while absf(mantissa) < 1.0:
		mantissa *= 10
		exponent -= 1

func set_from(other: OverInfinity) -> void:
	mantissa = other.mantissa
	exponent = other.exponent


# ====================
# Sing
# ====================
func _sign() -> int:
	if mantissa > 0.0:
		return 1
	elif mantissa < 0.0:
		return -1
	
	return 0


# ====================
# Operations
# ====================
# --- add ---
func add(other: OverInfinity) -> OverInfinity:
	_normalize()
	other._normalize()
	
	if mantissa == 0.0:
		return other.clone()
	if other.mantissa == 0.0:
		return clone()

	if exponent < other.exponent:
		return other.add(self)

	var diff := exponent - other.exponent

	if diff > 17:
		return clone()

	var result := OverInfinity.new()
	result.mantissa = mantissa + other.mantissa * pow(10.0, -diff)
	result.exponent = exponent
	result._normalize()

	return result

# --- subtract ---
func subtract(other: OverInfinity) -> OverInfinity:
	return add(other.negate())

# --- mutiply scalar ---
func multiply_scalar(factor: float) -> OverInfinity:
	_normalize()
	
	if factor == 0.0 or mantissa == 0.0:
		return OverInfinity.zero()
	
	var result := OverInfinity.new()
	result.mantissa = mantissa * factor
	result.exponent = exponent
	result._normalize()
	
	return result

# --- multiply ---
func multiply(other: OverInfinity) -> OverInfinity:
	_normalize()
	other._normalize()
	
	if mantissa == 0.0 or other.mantissa == 0.0:
		return OverInfinity.zero()
	
	var result := OverInfinity.new()
	result.mantissa = mantissa * other.mantissa
	result.exponent = exponent + other.exponent
	result._normalize()
	
	return result

# --- division ---
func division(other: OverInfinity) -> OverInfinity:
	_normalize()
	other._normalize()
	
	if other.mantissa == 0.0:
		push_error("Tá tentando dividir por 0 amigo?")
		return OverInfinity.zero()
	
	if mantissa == 0.0:
		return OverInfinity.zero()
	
	var result := OverInfinity.new()
	result.mantissa = mantissa / other.mantissa
	result.exponent = exponent - other.exponent
	result._normalize()
	
	return result


# ====================
# Comparative operations
# ====================
# --- comparation ---
func compare(other: OverInfinity) -> int:
	_normalize()
	other._normalize()
	
	var selfSing := _sign()
	var otherSing := other._sign()
	
	if selfSing != otherSing:
		return -1 if selfSing < otherSing else 1
	
	if selfSing == 0:
		return 0
	
	if exponent != other.exponent:
		var bigger := 1 if selfSing > 0 else -1
		return bigger if exponent > other.exponent else -bigger
	
	if mantissa == other.mantissa:
		return 0
	
	return -1 if mantissa < other.mantissa else 1

# --- Less than ---
func less_than(other: OverInfinity) -> bool:
	_normalize()
	other._normalize()
	
	return compare(other) < 0

# --- less or equal ---
func less_or_equal(other: OverInfinity) -> bool:
	_normalize()
	other._normalize()
	
	return compare(other) <= 0

# --- equal ---
func equal(other: OverInfinity) -> bool:
	_normalize()
	other._normalize()
	
	return compare(other) == 0

# --- greater ---
func greater_than(other: OverInfinity) -> bool:
	_normalize()
	other._normalize()
	
	return compare(other) > 0

# --- greater or equal ---
func greater_or_equal(other: OverInfinity) -> bool:
	_normalize()
	other._normalize()
	
	return compare(other) >= 0


# ====================
# Math Utilits
# ====================
# --- min ---
func minOF(other: OverInfinity) -> OverInfinity:
	_normalize()
	other._normalize()
	
	if greater_or_equal(other):
		return other.clone()
	else:
		return clone()

# --- max ---
func maxOF(other: OverInfinity) -> OverInfinity:
	_normalize()
	other._normalize()
	
	if greater_or_equal(other):
		return clone()
	else:
		return other.clone()

# --- clamp ---
func clampOF(min_value: OverInfinity, max_value: OverInfinity) -> OverInfinity:
	_normalize()
	min_value._normalize()
	max_value._normalize()
	
	if less_than(min_value):
		return min_value.clone()

	if greater_than(max_value):
		return max_value.clone()
	
	return clone()

# --- negate ---
func negate() -> OverInfinity:
	var result := clone()
	result.mantissa = -result.mantissa
	return result

# -- absolute ---
func absOF() -> OverInfinity:
	var result := clone()
	result.mantissa = absf(result.mantissa)
	
	return result

# --- is zero ---
func is_zero() -> bool:
	return mantissa == 0.0

# --- is positive ---
func is_positive() -> bool:
	return mantissa > 0.0

# --- is negative ---
func is_negative() -> bool:
	return mantissa < 0.0

# ====================
# Out
# ====================
# --- to float ---
func to_float() -> float:
	return mantissa * pow(10.0, exponent)  # não muito útil em números grandes

# --- display ---

func to_display_string(decimals: int = 2) -> String:
	_normalize()
	if mantissa == 0.0 or exponent < 3:
		return "%.*f" % [decimals, to_float()]
	
	var tier := exponent / 3
	var scaled := mantissa * pow(10.0, exponent - tier * 3)
	if tier < SUFFIIXES.size():
		return "%.*f%s" % [decimals, scaled, SUFFIIXES[tier]]
	
	return "%.*fe%d" % [decimals, mantissa, exponent]


# ====================
# Save/Load
# ====================
# --- to save ---
func to_save_data() -> Array:
	_normalize()
	return [mantissa, exponent]

# --- to load ---
static func to_load(data: Array) -> OverInfinity:
	var n := OverInfinity.new()
	n.mantissa = float(data[0])
	n.exponent = int(data[1])
	n._normalize()
	
	return n
