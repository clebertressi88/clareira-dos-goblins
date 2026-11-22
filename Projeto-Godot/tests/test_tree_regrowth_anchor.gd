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
	var stump_trunk := tree.get_node("Visual/BaseTronco/TroncoToco") as MeshInstance3D
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
			var bottom_sprout := sprout.position.y
			if absf(bottom_sprout - .505) > .015 or sprout.scale.y > 1.01:
				push_error("Broto flutuando")
				quit(1)
				return
		# A base do tronco jovem deve penetrar no toco (topo Y=.44).
		# Um teste apenas da fase visivel nao detectaria a flutuacao.
		if sapling_stage.visible and sapling_stage.position.y >= .44:
			push_error("Muda flutuando acima do topo do toco")
			quit(1)
			return
		if young_stage.visible and young_stage.position.y >= .44:
			push_error("Jovem flutuando acima do topo do toco")
			quit(1)
			return
		if sapling_stage.visible and absf(sapling_stage.position.y-.36)>.015:
			push_error("Muda desconectada do toco")
			quit(1)
			return
		if young_stage.visible and absf(young_stage.position.y-.36)>.015:
			push_error("Arvore jovem desconectada do toco")
			quit(1)
			return
		if stump_trunk.visible == growth.visible:
			push_error("Emenda ou sobreposicao entre tronco de toco e tronco adulto")
			quit(1)
			return
		if growth.visible:
			var bottom_growth := growth.position.y
			if absf(bottom_growth)>.015:
				push_error("Tronco adulto nao comeca no nivel do solo")
				quit(1)
				return
	regrowth.erase(id)
	game.call("update_tree_visual",tree)
	if not growth.visible or stump_trunk.visible or growth.position != Vector3.ZERO or growth.scale != Vector3.ONE:
		push_error("Arvore adulta nao restaurou escala/posicao")
		quit(1)
		return
	print("TREE REGROWTH STAGES OK")
	quit(0)
