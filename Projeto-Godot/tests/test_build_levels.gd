extends SceneTree
const SIZE := 2.55
## Teste completo do sistema: paredes + piso/teto em tres pavimentos,
## fundacao em terreno desigual, colisao e persistencia de pecas antigas.

func _initialize() -> void:
	call_deferred("_test")

func fail(message: String) -> void:
	printerr("BUILD LEVELS FAIL: "+message)
	quit(1)

func _test() -> void:
	var scene := load("res://main.tscn") as PackedScene
	if scene==null:
		fail("Cena principal nao encontrada.")
		return
	var game := scene.instantiate() as Node3D
	root.add_child(game)
	await physics_frame
	var player := game.get("player") as CharacterBody3D
	if player==null:
		fail("Personagem ausente.")
		return
	if (game.get("stock") as Array).size()<23:
		fail("Inventario nao inclui a peca de piso/teto.")
		return
	var x := 51.0
	var z := 50.0
	var base := float(game.call("ground",x,z))+.83
	game.call("store_object","wood_wall",Vector3(x,base,z),0.0,0)
	var objects: Dictionary = game.get("objects")
	var entries: Array = game.get("placed")
	var wall0: StaticBody3D = objects[entries.back()["id"]]
	var posts := 0
	for child in wall0.get_children():
		if child is MeshInstance3D and child.position.y < -.12:
			posts += 1
	if posts<4:
		fail("Parede suspensa antiga nao recebeu quatro pilares: "+str(posts))
		return
	if not game.call("wall_intersects_other_wall",Vector3(x,base,z),0.0):
		fail("Uma parede nao bloqueou sobreposicao no proprio andar.")
		return
	game.set("build_level",1)
	if game.call("wall_intersects_other_wall",Vector3(x,base+SIZE,z),0.0):
		fail("Parede de outro pavimento foi considerada sobreposicao.")
		return
	for floor_level in [1,2,3]:
		game.set("build_level",floor_level)
		player.position = Vector3(x,base+.9,z-.6)
		player.rotation.y = PI
		var floor_created: bool = bool(game.call("place_craft","wood_floor"))
		if not floor_created:
			fail("Nao foi possivel instalar piso/teto no nivel "+str(floor_level))
			return
		var floor_entry: Dictionary = entries.back()
		if floor_entry["kind"]!="wood_floor" or int(floor_entry.get("level",-1))!=floor_level:
			fail("Piso nao armazenou nivel na construcao.")
			return
		var slab: StaticBody3D = objects[floor_entry["id"]]
		if slab.collision_layer & 1 == 0:
			fail("Piso superior nao tem colisao solida.")
			return
		var shapes := 0
		for child in slab.get_children():
			if child is CollisionShape3D:
				shapes += 1
		if shapes==0:
			fail("O piso superior nao tem forma de colisao.")
			return
		if floor_level<=2:
			game.call("store_object","wood_wall",Vector3(x,base+float(floor_level)*SIZE,z),0.0,floor_level)
			var wall_entry: Dictionary = entries.back()
			if not game.call("upper_build_supported",Vector3(x,base+float(floor_level)*SIZE,z)):
				fail("Parede superior sem apoio reconhecido.")
				return
		print("BUILD LEVEL %d OK: painel horizontal, parede de apoio e save" % floor_level)
	if entries.size()<6:
		fail("A sequencia de estruturas nao foi gravada.")
		return
	game.set("build_level",1)
	if game.call("upper_build_supported",Vector3(x+90,base+SIZE,z+90)):
		fail("Apoio fantasma em area vazia.")
		return
	print("BUILD LEVELS OK: pilares, paredes empilhadas, piso/teto 3 pavimentos e salvamento.")
	quit(0)
