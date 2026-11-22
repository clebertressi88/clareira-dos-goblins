extends SceneTree
## Testa base/raizes antes e depois da queda, numero de golpes e som.
## Testa pa, toco persistente, muda e lobo presente na floresta.

func _initialize() -> void:
	call_deferred("_test")

func fail(message: String) -> void:
	printerr("FOREST GAMEPLAY FAIL: " + message)
	quit(1)

func _test() -> void:
	var scene := load("res://main.tscn") as PackedScene
	if scene == null:
		fail("Cena principal ausente")
		return
	var game := scene.instantiate() as Node3D
	root.add_child(game)
	await physics_frame
	await physics_frame
	var trees: Array[Node3D] = []
	var objects: Dictionary = game.get("objects")
	for obj in objects.values():
		if is_instance_valid(obj) and obj is StaticBody3D and obj.get_meta("kind","")=="tree":
			trees.append(obj)
			if trees.size()==2:
				break
	if trees.size()<2:
		fail("Precisamos de duas arvores para testar os machados")
		return

	# A textura compacta precisa decodificar corretamente no executavel exportado.
	var bark := preload("res://tree_bark_texture.gd").make_texture()
	if bark == null or bark.get_width()!=128 or bark.get_height()!=128:
		fail("JPG de casca nao decodificou corretamente")
		return
	var stream := preload("res://tree_fall_sound.gd").make_stream()
	if stream == null or stream.data.size()<30000:
		fail("Som de queda nao gerou PCM")
		return
	for idx in range(2):
		var tree := trees[idx]
		var base := tree.get_node_or_null("Visual/BaseTronco") as Node3D
		if base==null or not base.visible or base.get_child_count()<6:
			fail("Base com cinco raizes deve aparecer na arvore adulta")
			return
		var base_id := base.get_instance_id()
		var stump := tree.get_node_or_null("Visual/Toco") as Node3D
		if stump==null or stump.visible:
			fail("A secao cortada deve ficar invisivel na arvore inteira")
			return
		var cut_pos := tree.global_position+Vector3.UP*.8
		var tool := 9 if idx==0 else 10
		var required := 5 if idx==0 else 4
		for i in range(required):
			var fell: bool = bool(game.call("chop_tree",tree,tool,cut_pos,Vector3.FORWARD))
			if fell != (i==required-1):
				fail("Machado %d derrubou na batida %d em vez de %d" % [tool,i+1,required])
				return
			if i<required-1 and str(tree.get_meta("kind",""))!="tree":
				fail("Tronco mudou antes do ultimo golpe")
				return
		if str(tree.get_meta("kind",""))!="stump":
			fail("O corte nao criou o toco")
			return
		if base.get_instance_id()!=base_id or not base.visible or not is_instance_valid(base):
			fail("O corte trocou o tronco ou removeu as raizes originais")
			return
		if not stump.visible:
			fail("A superficie de corte nao apareceu")
			return
		if idx==0:
			var wood_before: int = int(game.get("stock")[6])
			var tree_id: String = str(tree.get_meta("id"))
			var first: bool = bool(game.call("dig_stump",tree,20,cut_pos,Vector3.FORWARD))
			if first or str(tree.get_meta("kind",""))!="stump":
				fail("O toco saiu com apenas uma cavada")
				return
			var second: bool = bool(game.call("dig_stump",tree,20,cut_pos,Vector3.FORWARD))
			if not second:
				fail("A segunda cavada nao removeu toco")
				return
			var cleared: Dictionary = game.get("cleared_stumps")
			if not cleared.has(tree_id):
				fail("Toco removido nao foi registrado no save")
				return
			if int(game.get("stock")[6])!=wood_before+1:
				fail("Remover toco nao devolveu tronco")
				return
	var sounds := get_nodes_in_group("placeholder-none")
	var sound_present := false
	for child in game.get_children():
		if child is AudioStreamPlayer3D and child.name.begins_with("SomQuedaArvore"):
			sound_present = true
	if not sound_present:
		fail("Queda nao reproduziu som 3D de madeira")
		return

	# O timer deve funcionar perto da clareira, sem esperar 95 a 175 segundos.
	var wolf_timer: float = float(game.get("wolf_spawn_timer"))
	if wolf_timer>15.0:
		fail("Tempo inicial dos lobos permanece excessivo")
		return
	game.set("wolf_spawn_timer",-1.0)
	for repeat in range(15):
		game.call("update_wolf_spawns",.1)
		var wolf: CharacterBody3D = game.get("roaming_wolf")
		if is_instance_valid(wolf):
			if str(wolf.get_meta("kind",""))!="wolf":
				fail("NPC gerado nao e lobo")
				return
			if wolf.global_position.distance_to((game.get("player") as CharacterBody3D).global_position)<10:
				fail("Lobo nasceu em cima do jogador")
				return
			print("FOREST WOLF OK: lobo criado a %.1f m" % wolf.global_position.distance_to((game.get("player") as CharacterBody3D).global_position))
			break
		game.set("wolf_spawn_timer",-1.0)
	if not is_instance_valid(game.get("roaming_wolf")):
		fail("Lobo nao apareceu apos varias tentativas de spawn")
		return

	print("FOREST GAMEPLAY OK: tronco e raizes persistentes, 5/4 golpes, som, pa, toco, lobo.")
	quit(0)
