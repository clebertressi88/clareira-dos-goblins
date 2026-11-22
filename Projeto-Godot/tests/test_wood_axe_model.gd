extends SceneTree
## Smoke test do machado de madeira aprovado, executado no CI antes do export.
func _initialize() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	preload("res://wood_axe_model.gd").build(root)
	var meshes := 0
	for child in root.get_children():
		if child is MeshInstance3D:
			meshes += 1
	if meshes < 10:
		push_error("WOOD AXE FAIL: modelo incompleto (%d malhas)" % meshes)
		quit(1)
		return
	print("WOOD AXE MODEL OK: %d malhas" % meshes)
	quit(0)
