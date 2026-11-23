extends SceneTree
## Verifica a planta rasteira, seus frutos e a integracao do item.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var model := preload("res://forest_tomato_plant.gd")
	var root := Node3D.new()
	get_root().add_child(root)
	model.build(root,"tomateiro-teste")
	var mature := 0
	var immature := 0
	var leaf_count := 0
	for node in root.get_children():
		if node.name == "TomateMaduro":
			mature += 1
		elif node.name == "TomateVerde":
			immature += 1
		elif node.name == "FolhaSerrilhada":
			leaf_count += 1
	if mature<2 or immature<1 or leaf_count<20:
		printerr("TOMATO FAIL: insufficient fruit or leaves")
		quit(1)
		return
	var item := Node3D.new()
	root.add_child(item)
	model.build(item,"tomate-item",true)
	if item.get_child_count()<6:
		printerr("TOMATO FAIL: fruit item details absent")
		quit(1)
		return
	print("TOMATO OK: realistic low-growing plant and pickup fruit")
	quit(0)
