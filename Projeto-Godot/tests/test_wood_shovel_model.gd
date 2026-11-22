extends SceneTree
## Verifica se a pa artesanal de madeira cria geometria 3D completa.
func _initialize() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	preload("res://wood_shovel_model.gd").build(root)
	var meshes: int = 0
	for child in root.get_children():
		if child is MeshInstance3D:
			meshes += 1
	if meshes < 35:
		push_error("WOOD SHOVEL FAIL: malhas insuficientes (%d)" % meshes)
		quit(1)
		return
	print("WOOD SHOVEL MODEL OK: %d malhas" % meshes)
	quit(0)
