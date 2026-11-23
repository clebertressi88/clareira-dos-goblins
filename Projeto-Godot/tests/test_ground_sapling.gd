extends SceneTree
## Verifica que a muda coletavel e rasteira e nao usa mais haste vertical.
func _initialize() -> void:
	var scene := load("res://main.tscn") as PackedScene
	if scene == null:
		printerr("SAPLING FAIL: main scene not found")
		quit(1)
		return
	var game := scene.instantiate() as Node3D
	root.add_child(game)
	call_deferred("_run",game)

func _run(game: Node3D) -> void:
	await physics_frame
	var sapling := game.call("spawn_object","sapling","test-sapling-low",Vector3(6.0,0.0,6.0)) as StaticBody3D
	if sapling == null:
		printerr("SAPLING FAIL: spawn failed")
		quit(1)
		return
	var visual := sapling.get_node_or_null("MudaRasteira") as Node3D
	if visual == null or visual.get_child_count()<10:
		printerr("SAPLING FAIL: low ground geometry absent")
		quit(1)
		return
	var collision := sapling.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null or not collision.shape is BoxShape3D:
		printerr("SAPLING FAIL: collection collision absent")
		quit(1)
		return
	var box := collision.shape as BoxShape3D
	if box.size.y > 0.25 or box.size.x < 0.75:
		printerr("SAPLING FAIL: collider not low and wide")
		quit(1)
		return
	print("SAPLING OK: low fallen twig model, leaf litter and pickup collider")
	quit(0)
