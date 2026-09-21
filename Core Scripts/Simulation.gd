# ====================
# Class & Extend
# ====================
class_name Simulation
extends Node


# ====================
# Signals
# ====================
signal exploded(cell: Vector2i, power: float)


# ====================
# Tick
# ====================
const TICK = 1.0


# ====================
# Exports
# ====================
@export var structures: StructureLayer


# ====================
# Variables
# ====================
var energy := 0.0
var maxEnergy := 500.0
var money := 0.0
var GlobalPollution := 0.0
var science := 0.0
var energyPrice := 1.0
var heatToEnergy := 1.0
var credit := 0.0

var _acc := 0.0


# ====================
# Process
# ====================
func _process(delta: float) -> void:
	_acc += delta
	while _acc >= TICK:
		_acc -= TICK
		tick()


# ====================
# Tick tiki tiki
# ====================
func _tick() -> void:
	_produce()
	_convert_heat()
	_check_overheat()
	_sell()
	_clean_and_research()
	energy = minf(energy, maxEnergy)


# ====================
# Produce
# ====================
func _produce() -> void:
	for cell in structures.data:
		var reactor := structures.get_definition_at(cell) as ReactorStructure
		if reactor == null:
			continue
		
		energy += reactor.energyProduction * TICK
		structures.heat[cell] += reactor.heatProduction * TICK
		GlobalPollution += reactor.pollutionProduction * TICK


# ====================
# Convert hear
# ====================
func _convert_heat() -> void:
	for cell in structures.data:
		var gen := structures.get_definition_at(cell) as GeneratorStructure
	
		if gen == null:
			continue
		
		var capacity := gen.heatConvert * TICK
		for n in structure.get_surrounding_cells(cell):
			if capacity <= 0.0:
				break
			
			if not structures.heat.has(n):
				continue
			
			var taken := minf(structures.heat[n], capacity)
			structures.heat[n] -= taken
			capacity -= taken
			energy += taken * heatToEnergy


# ====================
# Check overheat
# ====================
func _check_overheat() -> void:
	var overheated: Array[Vector2i] = []
	for cell in  structures.heat:
		
		var def := structures.get_definition_at(cell) as StructureTile
		
		if structures.heat[cell] > def.maxHeat:
			overheated.append(cell)
	
	for cell in overheated:
		explode(cell)


# ====================
# Sell
# ====================
func _sell() -> void:
	for cell in structures.data:
		
		var office := structures.get_definition_at(cell) as OfficeStructure
		
		if office:
			sell_energy(office.energyConvert * TICK)


# ====================
# Clean and Research
# ====================
func _clean_and_research() -> void:
	for cell in structures.data:
		
		var def := structures.get_definition_at(cell)
		var cleaner := def as PollutionStructure
		
		if cleaner:
			GlobalPollution = max(0.0, GlobalPollution - cleaner.pollutionConvert * TICK )
		
		var lab := def as SearchStructure
		
		if lab:
			science += lab.sciencePoints * TICK


# --- Support function ---


# ====================
# Sell Energy
# ====================
func sell_energy(amount: float) -> void:
	var sold := minf(amount, energy)
	energy -= sold
	money += sold * energyPrice


# ====================
# Buy structure
# ====================
func buy_structure(cell: Vector2i, id: StringName) -> bool:
	var def := structures.get_definition(id) as StructureTile
	
	if def == null or not def.purchasable or money + credit < def.price:
		return false
	
	if not structures.place(cell, id):
		return false
	
	money -= def.price
	return true


# ====================
# Explode
# ====================
func explode(origin: Vector2i) -> void:
	var queue: Array[Vector2i] = [origin]
	
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		var def := structures.get_definition_at(cell) as StructureTile
		
		if def == null:
			continue
		
		var power := def.explosionPower
		structures.remove(cell)
		exploded.emit(cell, power)
		var radius := ceili(power)
		
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var target := cell + Vector2i(dx, dy)
				var victim := structures.get_definition_at(target) as StructureTile
				
				if victim == null:
					continue
				
				var force := power - Vector2(dx, dy).length()
				
				if force > victim.blastResistence:
					queue.append(target)
