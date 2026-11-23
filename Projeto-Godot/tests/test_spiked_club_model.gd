extends SceneTree
## Verifica modelos do porrete e receita 3x3.
func _initialize() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	preload("res://spiked_club_model.gd").build(root)
	var meshes: int = 0
	for child in root.get_children():
		if child is MeshInstance3D:
			meshes += 1
	if meshes < 35:
		push_error("SPIKED CLUB FAIL: %d malhas" % meshes)
		quit(1)
		return
	print("SPIKED CLUB MODEL OK: %d malhas" % meshes)
	quit(0)
