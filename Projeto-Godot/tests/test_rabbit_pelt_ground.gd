extends SceneTree
## Confere tamanho e encaixe no relevo da pele de coelho.
func _ground_test(x: float, z: float) -> float:
	return 0.02 * x + 0.025 * z

func _initialize() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	root.position = Vector3(2.5,_ground_test(2.5,-1.5)+0.008,-1.5)
	preload("res://rabbit_pelt_model.gd").new().build(root,Callable(self,"_ground_test"))
	if root.get_child_count() != 1 or not root.get_child(0) is MeshInstance3D:
		push_error("RABBIT PELT FAIL: modelo nao criado")
		quit(1)
		return
	var skin := root.get_child(0) as MeshInstance3D
	var bounds := skin.mesh.get_aabb()
	if bounds.size.x > 0.70 or bounds.size.z > 0.70:
		push_error("RABBIT PELT FAIL: pele grande demais %s" % [bounds.size])
		quit(1)
		return
	if bounds.position.y < -0.04 or bounds.end.y > 0.10:
		push_error("RABBIT PELT FAIL: pele fora do nivel do chao %s" % [bounds])
		quit(1)
		return
	print("RABBIT PELT GROUND OK")
	quit(0)
