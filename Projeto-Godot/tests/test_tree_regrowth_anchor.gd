extends SceneTree
## Valida fases exclusivas, troncos ancorados no topo do toco e volta a adulto.
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
	var sapling_stage := tree.get_node("Visual/Muda") as Node3D
	var young_stage := tree.get_node("Visual/Jovem") as Node3D
	var nodes := [sprout,sapling_stage,young_stage,growth]
	var stages := [
		{"progress":0.05,"active":-1},
		{"progress":0.17,"active":0},
		{"progress":0.35,"active":1},
		{"progress":0.58,"active":2},
		{"progress":0.90,"active":3}
	]
	for stage in stages:
		var progress: float = stage["progress"]
		regrowth[id] = now - 120.0 - progress * 720.0
		game.call("update_tree_visual",tree)
		for i in range(nodes.size()):
			if nodes[i].visible != (i == int(stage["active"])):
				push_error("Fase incorreta ou sobreposta em %.2f" % progress)
				quit(1)
				return
		if sprout.visible:
			var bottom_sprout := sprout.position.y + .44 * sprout.scale.y
			if absf(bottom_sprout - .52) > .015:
				push_error("Broto flutuando")
				quit(1)
				return
		if sapling_stage.visible and absf(sapling_stage.position.y-.52)>.015:
			push_error("Muda desconectada do toco")
			quit(1)
			return
		if young_stage.visible and absf(young_stage.position.y-.52)>.015:
			push_error("Arvore jovem desconectada do toco")
			quit(1)
			return
		if growth.visible:
			var bottom_growth := growth.position.y + .52*growth.scale.y
			if absf(bottom_growth-.52)>.015:
				push_error("Arvore adulta em crescimento flutuando")
				quit(1)
				return
	regrowth.erase(id)
	game.call("update_tree_visual",tree)
	if not growth.visible or growth.position != Vector3.ZERO or growth.scale != Vector3.ONE:
		push_error("Arvore adulta nao restaurou escala/posicao")
		quit(1)
		return
	print("TREE REGROWTH STAGES OK")
	quit(0)
