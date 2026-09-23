# ====================
# Class & Extend
# ====================
class_name GrasslandWorld
extends WorldBase


# ====================
# Generate
# ====================
func _generate() -> void:
	if not terrain.definitions.has(&"grass"):
		push_error("Nenhum terreno com id 'grass' foi encontrado em " + terrain_folder)
		return

	for x in world_size.x:
		for y in world_size.y:
			terrain.place(Vector2i(x, y), &"grass")
