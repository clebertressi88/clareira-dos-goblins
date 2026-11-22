extends SceneTree
## Teste das duas variacoes de carne crua de animais.
func _initialize() -> void:
	var model = preload("res://raw_meat_model.gd")
	for rabbit in [false,true]:
		var parent := Node3D.new()
		get_root().add_child(parent)
		model.build(parent,rabbit)
		var meshes: int = 0
		for child in parent.get_children():
			if child is MeshInstance3D:
				meshes += 1
		if meshes < 15:
			push_error("RAW MEAT FAIL: poucas malhas (%d), rabbit=%s" % [meshes,str(rabbit)])
			quit(1)
			return
	print("RAW MEAT MODEL OK")
	quit(0)
