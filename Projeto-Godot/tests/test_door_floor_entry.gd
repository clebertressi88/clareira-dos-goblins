extends SceneTree
const SIZE := 2.55

func _initialize() -> void:
	call_deferred("_run")

func fail(message: String) -> void:
	printerr("DOOR FLOOR FAIL: "+message)
	quit(1)

func _run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	if scene==null:
		fail("Cena principal nao encontrada")
		return
	var game := scene.instantiate() as Node3D
	root.add_child(game)
	await physics_frame
	await physics_frame

	var px := 9.7
	var pz := 11.2
	var h: float = float(game.call("ground",px,pz))+.36
	game.call("store_object","wood_doorway",Vector3(px,h,pz),0.0,0)
	var list: Array = game.get("placed")
	var objs: Dictionary = game.get("objects")
	var doorway := objs[list.back()["id"]] as StaticBody3D
	if doorway==null:
		fail("Porta nao criada")
		return
	# Simula piso novo colocado DEPOIS da porta, como o usuario fez.
	game.call("store_object","wood_floor",Vector3(px,h,pz+SIZE*.5),0.0,0)
	var panel := objs[list.back()["id"]] as StaticBody3D
	if panel==null:
		fail("Piso nao criado")
		return
	await physics_frame
	await physics_frame
	var solid := panel.get_node_or_null("PainelContinuo") as MeshInstance3D
	if solid==null or solid.mesh==null:
		fail("Piso ainda apresenta frestas: falta painel continuo")
		return
	var ramps := 0
	var collisions := 0
	for child in doorway.get_children():
		if child.name.begins_with("RampaPorta"):
			ramps+=1
		elif child is CollisionShape3D:
			var ramp_shape := (child as CollisionShape3D).shape as BoxShape3D
			if ramp_shape!=null and ramp_shape.size.z>1.5:
				collisions+=1
	if ramps!=2 or collisions!=2:
		for ch in doorway.get_children():
			print("DOOR DEBUG CHILD:",ch.name," type=",ch.get_class(), " shape=",ch.shape if ch is CollisionShape3D else "")
		fail("A porta deveria ter duas rampas fisicas: %d visuais, %d colisoes" % [ramps,collisions])
		return
	print("DOOR RAMP OK: 2 rampas e 2 colisoes, atualizadas ao adicionar piso.")
	
	# Regressao: bloco ocupado deve produzir um candidato livre adjacente.
	game.set("build_level",0)
	var floor_point := Vector3(px,h,pz+SIZE*.5)
	var next_floor: Vector3 = game.call("find_floor_snap",floor_point)
	if bool(game.call("floor_intersects_other_floor",next_floor)):
		fail("Encaixe sugeriu piso duplicado, nao a celula vizinha")
		return
	if absf(Vector2(next_floor.x-floor_point.x,next_floor.z-floor_point.z).length()-SIZE)>.05:
		fail("Piso vizinho nao encaixa na grade de 2,55 m")
		return
	print("FLOOR SNAP OK: proximo quadrado livre.")

	# Mesmo de dentro do terreo, primeiro teto precisa estar apoiado na porta.
	game.set("build_level",1)
	var top := Vector3(px,h+SIZE,pz+SIZE*.5)
	if not bool(game.call("upper_build_supported",top)):
		fail("Cobertura sobre a parede nao reconheceu apoio")
		return
	var roof: Vector3 = game.call("find_floor_snap",top)
	if not roof.is_equal_approx(top):
		fail("O primeiro teto nao encaixou sobre a parede da porta")
		return
	print("ROOF PLACEMENT OK: piso superior/teto no nivel 1 sem mudar posicao da parede.")

	# Um pinheiro gerado pelo mapa ocupava a frente desta porta do teste.
	# Limpa SOMENTE o corredor do cenario sintetico, preservando os
	# colisores da porta, rampa, piso e proprio terreno.
	for obstacle in objs.values():
		if not (obstacle is CollisionObject3D) or obstacle==doorway or obstacle==panel:
			continue
		if obstacle.global_position.distance_to(Vector3(px,h,pz))<4.0:
			obstacle.collision_layer = 0
	# Entrada real: corpo fisico anda do lado de fora, sobre a rampa,
	# ate a laje, sem salto e sem atravessar uma parede solida.
	var character := game.get("player") as CharacterBody3D
	character.position = Vector3(px,float(game.call("ground",px,pz-2.3))+.12,pz-2.3)
	character.velocity = Vector3.ZERO
	var arrived := false
	for tick in range(160):
		await physics_frame
		character.velocity.x = 0
		character.velocity.z = 2.8
		if not character.is_on_floor():
			character.velocity.y -= 15.0/60.0
		else:
			character.velocity.y = 0
		character.move_and_slide()
		if character.position.z>pz+1.08:
			arrived = true
			break
	if not arrived:
		print("ENTRY DEBUG pos=",character.global_position," floor=",character.is_on_floor()," wall=",character.is_on_wall()," ceiling=",character.is_on_ceiling())
		print("ENTRY DEBUG terreno=",game.call("ground",character.position.x,character.position.z)," shape=",character.get_slide_collision_count())
		for contact_idx in range(character.get_slide_collision_count()):
			var contact := character.get_slide_collision(contact_idx)
			var other := contact.get_collider()
			print("ENTRY DEBUG colliding=",other," type=",other.get_class() if other!=null else "null"," kind=",other.get_meta("kind","") if other!=null else "", " normal=",contact.get_normal())
		for child in doorway.get_children():
			if child.name.begins_with("RampaPorta"):
				print("ENTRY DEBUG ramp=",child.name," local=",child.position," rot=",child.rotation)
		fail("Jogador preso na entrada: z=%.2f; porta z=%.2f" % [character.position.z,pz])
		return
	if character.position.y < h-.35:
		fail("Jogador atravessou a colisao do piso ao entrar")
		return
	print("DOOR FLOOR WALK OK: jogador entrou andando, sem pulo, z=%.2f" % character.position.z)
	print("DOOR FLOOR TEST OK: piso continuo, porta acessivel, encaixe e teto.")
	quit(0)
