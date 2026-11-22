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
	var terrain_h: float = float(game.call("ground",0.0,0.0))
	var world := player.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(Vector3(0,8,0),Vector3(0,-8,0),1)
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
	player.position = Vector3(0.0,terrain_h+0.85,0.0)
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
	print("TERRAIN PHYSICS OK: jogador e ambos os goblins caminharam sobre o relevo.")
	quit(0)
