extends SceneTree
## Verifica que a base do broto e a base do tronco em crescimento
## permanecem no topo do toco, inclusive apos escalar.
func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	var scene := load("res://main.tscn") as PackedScene
	if scene == null:
		push_error("Cena principal ausente")
		quit(1)
		return
	var game := scene.instantiate() as Node3D
	root.add_child(game)
	await physics_frame
	await physics_frame
	var objects: Dictionary = game.get("objects")
	var tree: Node3D = null
	for obj in objects.values():
		if is_instance_valid(obj) and str(obj.get_meta("kind","")) == "tree":
			tree = obj
			break
	if tree == null:
		push_error("Nao encontramos arvore para teste")
		quit(1)
		return
	var id := str(tree.get_meta("id"))
	var regrowth: Dictionary = game.get("tree_regrowth")
	var now := Time.get_unix_time_from_system()
	var growth := tree.get_node("Visual/Crescimento") as Node3D
	var sprout := tree.get_node("Visual/Broto") as Node3D
	for progress in [0.0, 0.05, 0.08, 0.12, 0.17, 0.25, 0.5, 0.9]:
		regrowth[id] = now - 120.0 - progress * 720.0
		game.call("update_tree_visual",tree)
		# Altura local inferior do cilindro adulto: 1.36 - 1.68/2 = .52.
		var bottom_growth := growth.position.y + .52 * growth.scale.y
		if absf(bottom_growth - .52) > .015:
			push_error("Tronco solto do toco no progresso %.2f: Y=%.3f" % [progress,bottom_growth])
			quit(1)
			return
		# Base inferior do caule: .67 - .46/2 = .44.
		var bottom_sprout := sprout.position.y + .44 * sprout.scale.y
		if absf(bottom_sprout - .52) > .015:
			push_error("Broto flutuando no progresso %.2f: Y=%.3f" % [progress,bottom_sprout])
			quit(1)
			return
	regrowth.erase(id)
	game.call("update_tree_visual",tree)
	if growth.position != Vector3.ZERO or growth.scale != Vector3.ONE:
		push_error("Arvore adulta nao restaurou a escala/posicao")
		quit(1)
		return
	print("TREE REGROWTH ANCHOR OK")
	quit(0)
