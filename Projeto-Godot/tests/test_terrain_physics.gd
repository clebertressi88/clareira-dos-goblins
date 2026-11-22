extends SceneTree
# Diagnostico fisico real: verifica solo, deslocamento do jogador e dois NPCs.
# Compara a velocidade solicitada com o deslocamento real e avalia bloqueios.
func _initialize() -> void:
	call_deferred("_run")

func fail(message: String) -> void:
	printerr("TERRAIN PHYSICS FAIL: " + message)
	quit(1)

func _run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	if scene == null:
		fail("Cena principal nao existe.")
		return
	var game := scene.instantiate() as Node3D
	root.add_child(game)
	await physics_frame
	await physics_frame
	var player := game.get("player") as CharacterBody3D
	if player == null:
		fail("Jogador nao gerado.")
		return
	var terrain_h: float = float(game.call("ground",1.25,1.25))
	var world := player.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(Vector3(1.25,8,1.25),Vector3(1.25,-8,1.25),1)
	var hit: Dictionary = world.intersect_ray(ray)
	if hit.is_empty():
		fail("Malha de terreno sem colisao fisica sob a clareira.")
		return
	if absf(float(hit["position"].y)-terrain_h)>0.3:
		fail("Colisao de solo desalinhada: ray=" + str(hit["position"].y) + " func=" + str(terrain_h))
		return
	if hit["normal"].y < .7:
		fail("Normal da colisao de solo incorreta: " + str(hit["normal"]))
		return
	print("SOLO TEST OK: colisao y=%.2f normal=%s" % [hit["position"].y,str(hit["normal"])])
	# Posicao central limpa de recursos, num patamar horizontal.
	player.position = Vector3(1.25,terrain_h+0.85,1.25)
	player.velocity = Vector3.ZERO
	game.call("begin")
	Input.action_press("goblin_frente")
	var initial := player.global_position
	for i in range(60):
		await physics_frame
	Input.action_release("goblin_frente")
	var displacement := Vector2(player.global_position.x-initial.x,player.global_position.z-initial.z).length()
	print("PLAYER TEST: traveled %.3f m, position %s, velocity %s, on_floor=%s, on_wall=%s" % [
		displacement,str(player.global_position),str(player.velocity),str(player.is_on_floor()),str(player.is_on_wall())
	])
	if displacement < 2.0:
		fail("Player travado no novo relevo (andou %.2f m em 60 quadros)" % displacement)
		return
	# Deslocamento NPC de verdade, nao so animacao nem mudanca de status.
	var villagers: Array = game.get("villagers")
	if villagers.size()<2:
		fail("Os dois goblins nao foram criados.")
		return
	# Retira jogador do caminho da patrulha sem afastar goblins da clareira.
	player.position = Vector3(0,terrain_h+.85,3)
	var origin_a: Vector3 = villagers[0].global_position
	var origin_b: Vector3 = villagers[1].global_position
	for npc in villagers:
		npc.set_meta("next_react",10000.0)
		npc.set_meta("look_until",-1000.0)
		npc.set_meta("ai_until",-1000.0)
		npc.set_meta("ai_state","idle")
	for i in range(300):
		await physics_frame
	var a: float = (villagers[0].global_position-origin_a).length()
	var b: float = (villagers[1].global_position-origin_b).length()
	print("NPC TEST: Bruma %.2f m, Talo %.2f m, states %s / %s" % [a,b,str(villagers[0].get_meta("ai_state")),str(villagers[1].get_meta("ai_state"))])
	if a < .55 or b < .55:
		fail("Goblins travados na fisica/patrulha: %.2f m / %.2f m" % [a,b])
		return
	# Reproduz o problema das imagens: guardiao na encosta em x=3, z=-39.
	# O codigo antigo nascia em y=0, quando o solo aqui fica quase 70 cm acima.
	var guardian := game.call("creature","guardian","teste-guardiao",Vector3(3,0,-39),game) as CharacterBody3D
	if guardian==null:
		fail("Nao foi possivel criar guardiao.")
		return
	var guardian_height: float = float(game.call("ground",3.0,-39.0))
	if absf(guardian.global_position.y-(guardian_height+.06))>.06:
		fail("Guardiao nasceu enterrado: y=%.2f, solo=%.2f" % [guardian.global_position.y,guardian_height])
		return
	print("GUARDIAN SPAWN OK: base=%.2f, solo=%.2f" % [guardian.global_position.y,guardian_height])
	# Traz os chunks para perto do guardiao e exige ataque com contato visivel.
	player.position = Vector3(3.0,float(game.call("ground",3.0,-37.8))+.04,-37.8)
	player.velocity = Vector3.ZERO
	game.call("load_chunks")
	await physics_frame
	await physics_frame
	if not bool(game.call("mob_has_clear_hit",guardian)):
		fail("A linha de ataque livre nao detectou o jogador.")
		return
	var obstacle := StaticBody3D.new()
	obstacle.collision_layer = 1
	obstacle.collision_mask = 0
	obstacle.position = Vector3(3.0, guardian_height+1.1, -38.4)
	var wall := CollisionShape3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(1.4,2.2,.14)
	wall.shape = wall_shape
	obstacle.add_child(wall)
	game.add_child(obstacle)
	await physics_frame
	if bool(game.call("mob_has_clear_hit",guardian)):
		fail("Guardiao pode atacar atraves de parede.")
		return
	print("GUARDIAN COMBAT OK: obstrucao interrompe ataque.")
	print("TERRAIN PHYSICS OK: jogador e ambos os goblins caminharam sobre o relevo.")
	quit(0)
