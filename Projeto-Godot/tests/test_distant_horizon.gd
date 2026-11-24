extends SceneTree
const TERRAIN := preload("res://landscape_terrain.gd")
const HORIZON := preload("res://distant_horizon.gd")

func _initialize() -> void:
	call_deferred("_run")

func fail(message: String) -> void:
	printerr("DISTANT HORIZON FAIL: " + message)
	quit(1)

func _run() -> void:
	# A geometria do fundo deve ser apenas visual, alinhada ao relevo real.
	var distant := HORIZON.build(Vector2i.ZERO,2,16)
	if distant==null or distant.mesh==null or distant.material_override==null:
		fail("Malha visual do horizonte nao foi criada")
		return
	if distant.get_child_count()!=0 or distant is CollisionObject3D:
		fail("Horizonte nao pode gerar colisoes ou objetos jogaveis")
		return
	var material := distant.material_override as StandardMaterial3D
	if material==null or material.transparency!=BaseMaterial3D.TRANSPARENCY_ALPHA:
		fail("Horizonte nao possui transparencia para se fundir ao ceu")
		return
	var arrays := distant.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	if vertices.size()<1000 or colors.size()!=vertices.size():
		fail("Vertices e cores/fade do horizonte invalidos")
		return
	var opaque_count := 0
	var transparent_count := 0
	for i in range(vertices.size()):
		var v: Vector3 = vertices[i]
		if absf(v.y-TERRAIN.height_at(v.x,v.z))>.003:
			fail("Horizonte e mapa usam alturas diferentes")
			return
		var c: Color = colors[i]
		if c.a>.99:
			opaque_count += 1
		if c.a<.01:
			transparent_count += 1
	if opaque_count==0 or transparent_count==0:
		fail("Fade progressivo do horizonte ausente")
		return
	# Os triangulos nao podem cobrir o miolo dos chunks renderizados.
	for i in range(0,vertices.size(),3):
		var mid := (vertices[i]+vertices[i+1]+vertices[i+2])/3.0
		if mid.x > -32.0 and mid.x < 48.0 and mid.z > -32.0 and mid.z < 48.0:
			fail("Horizonte sobrepoe terreno perto do jogador")
			return
	distant.free()
	# Integração: mover o jogador obriga a recriar a camada de fundo.
	var scene := load("res://main.tscn") as PackedScene
	if scene==null:
		fail("Cena principal indisponivel")
		return
	var game := scene.instantiate() as Node3D
	root.add_child(game)
	await physics_frame
	var player := game.get("player") as CharacterBody3D
	var horizon_before := game.get("distant_horizon") as MeshInstance3D
	var camera := game.get("camera") as Camera3D
	if not is_instance_valid(player) or not is_instance_valid(horizon_before) or not is_instance_valid(camera):
		fail("Horizonte nao foi integrado a cena principal")
		return
	if camera.far < 180.0:
		fail("Plano distante da camera corta o horizonte antecipadamente")
		return
	var first_center: Vector2i = game.get("distant_horizon_center")
	player.global_position = Vector3(144.0,TERRAIN.height_at(144.0,80.0)+.8,80.0)
	game.call("load_chunks")
	var horizon_after := game.get("distant_horizon") as MeshInstance3D
	var next_center: Vector2i = game.get("distant_horizon_center")
	if not is_instance_valid(horizon_after) or horizon_before==horizon_after or next_center==first_center:
		fail("Horizonte nao acompanhou o movimento do jogador")
		return
	print("DISTANT HORIZON OK: terreno visual, fade, colisao ausente e reposicionamento")
	quit(0)
