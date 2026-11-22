extends SceneTree
## Valida que o visual e a fisica compartilham a mesma altura no relevo
## e que o jogador nao fica visualmente embaixo do solo ou do rio.
func _initialize() -> void:
	call_deferred("_run")

func fail(message: String) -> void:
	printerr("TERRAIN VISUAL FAIL: " + message)
	quit(1)

func _run() -> void:
	var resource := load("res://main.tscn") as PackedScene
	if resource == null:
		fail("Cena principal inexistente")
		return
	var game := resource.instantiate() as Node3D
	root.add_child(game)
	await physics_frame
	await physics_frame
	var chunks: Dictionary = game.get("chunks")
	if chunks.size() < 9:
		fail("Mapa nao carregou chunks suficientes: " + str(chunks.size()))
		return
	var check_count := 0
	for chunk_key: Vector2i in chunks.keys():
		var chunk: Node3D = chunks[chunk_key]
		var land := chunk.get_node_or_null("TerrenoVisual") as MeshInstance3D
		var collision := chunk.get_node_or_null("TerrenoFisico/ColisaoTerreno") as CollisionShape3D
		if land == null or collision == null:
			fail("Chunk sem terreno visual ou fisico: " + str(chunk_key))
			return
		if not (collision.shape is HeightMapShape3D):
			fail("Colisao nao e HeightMapShape3D: " + str(chunk_key))
			return
		var height_shape := collision.shape as HeightMapShape3D
		if height_shape.map_width != 17 or height_shape.map_depth != 17:
			fail("Dimensao fisica diferente da grade de 1 m")
			return
		var material := land.material_override as StandardMaterial3D
		if material == null or material.cull_mode != BaseMaterial3D.CULL_DISABLED:
			fail("Terreno com culling ativo, pode desaparecer visto de baixo")
			return
		var arrays := land.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		if vertices.size() != 16*16*6 or normals.size() != vertices.size():
			fail("Grade visual incompleta: " + str(vertices.size()))
			return
		for i in range(vertices.size()):
			var p: Vector3 = vertices[i]
			if absf(p.y-float(game.call("ground",p.x,p.z))) > .003:
				fail("Buraco/desalinhamento na malha: " + str(p))
				return
			if normals[i].y < .1:
				fail("Normal invertida no chao (face visivel pelo lado errado): " + str(normals[i]))
				return
		check_count += 1
	print("TERRAIN VISUAL TEST OK: %d chunks, vertices e altura/colisao alinhados." % check_count)

	var player := game.get("player") as CharacterBody3D
	if player == null:
		fail("Jogador nao foi criado")
		return
	game.call("begin")
	# Reproduz a situacao da captura: save embaixo da encosta.
	var px := 24.5
	var pz := 7.5
	var level := float(game.call("ground",px,pz))
	player.position = Vector3(px,level-5.0,pz)
	player.velocity = Vector3.ZERO
	for i in range(4):
		await physics_frame
	if player.position.y < float(game.call("ground",player.position.x,player.position.z))+.1:
		fail("Camera/jogador permaneceu abaixo do terreno")
		return
	print("SPAWN SAFETY TEST OK: jogador recuperado acima do relevo.")

	# Rio: a camera nao deve ficar submersa caso o jogador alcance o leito.
	var terrain := load("res://landscape_terrain.gd")
	var river_x: float = terrain.river_x(0.0)
	player.position = Vector3(river_x,terrain.WATER_LEVEL-3.0,0.0)
	player.velocity = Vector3.ZERO
	for i in range(3):
		await physics_frame
	var camera := game.get("camera") as Camera3D
	if camera.global_position.y < terrain.WATER_LEVEL+.1:
		fail("Camera continua submersa no rio: " + str(camera.global_position.y))
		return
	print("WATER CAMERA TEST OK: camera acima do rio.")
	print("TERRAIN RENDERING OK: malha visual, colisao e camera verificados.")
	quit(0)
