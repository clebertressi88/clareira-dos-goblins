extends SceneTree
## Regressao: horta 3D e itens de tomate/sementes.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var model := preload("res://forest_tomato_plant.gd")
	var root := Node3D.new()
	get_root().add_child(root)
	model.build(root,"tomateiro-horta")
	if root.get_child_count()<70:
		printerr("GARDEN FAIL: tomato plant not fully generated")
		quit(1)
		return
	var scene := load("res://main.tscn") as PackedScene
	if scene==null:
		printerr("GARDEN FAIL: main scene missing")
		quit(1)
		return
	var game := scene.instantiate() as Node3D
	get_root().add_child(game)
	await physics_frame
	var names: Array = game.get("ITEMS")
	var kinds: Array = game.get("ITEM_KINDS")
	if names.size()!=kinds.size() or names[27]!="Tomate" or names[28]!="Sementes de tomate":
		printerr("GARDEN FAIL: item index mismatch")
		quit(1)
		return
	game.set("tomato_crop_times",{"test-crop":Time.get_unix_time_from_system()-301})
	var crop := game.call("spawn_object","tomato_crop","test-crop",Vector3(5,0,5)) as Node3D
	game.call("update_tomato_crop",crop)
	if not bool(crop.get_meta("ready",false)):
		printerr("GARDEN FAIL: planted crop did not mature")
		quit(1)
		return
	print("GARDEN OK: mature tomato crop and matched item indices")
	quit(0)
