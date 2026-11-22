extends SceneTree
# Teste de rede em DOIS processos reais Godot via UDP 24650.
# host: Godot --script ... -- --mode=host
# client: Godot --script ... -- --mode=client

func _initialize() -> void:
	call_deferred("_run")

func fail(reason: String) -> void:
	printerr("NET MULTIPLAYER FAIL: "+reason)
	quit(1)

func _run() -> void:
	var mode := "client"
	for arg in OS.get_cmdline_user_args():
		if arg=="--mode=host":
			mode = "host"
	var scene := load("res://main.tscn") as PackedScene
	if scene==null:
		fail("Cena nao carregada")
		return
	var game := scene.instantiate() as Node3D
	root.add_child(game)
	await physics_frame
	await physics_frame
	var player := game.get("player") as CharacterBody3D
	if player==null:
		fail("Jogador inexistente")
		return
	if mode=="host":
		# Construir antes de receber visitas: deve aparecer no snapshot.
		var spawn := Vector3(7,float(game.call("ground",7.0,8.0)),8)
		game.call("store_object","wood_wall",spawn,0.0,0)
		game.call("host_game")
		if str(game.get("net_role"))!="host":
			fail("Servidor UDP nao iniciou")
			return
		print("NET HOST READY: UDP 24650")
		var placed_after_connect := false
		for tick in range(850):
			await physics_frame
			var online: Dictionary = game.get("remotes")
			if online.size()>0 and not placed_after_connect:
				game.call("store_object","wood_floor",Vector3(8.3,spawn.y,8.2),0.0,0)
				placed_after_connect = true
				print("NET HOST LIVE BUILD SENT")
			var found_remote_build := false
			for entry in game.get("placed"):
				if str(entry.get("kind",""))=="bench":
					found_remote_build = true
			if found_remote_build and placed_after_connect and online.size()>0:
				print("NET MULTIPLAYER HOST OK: cliente visivel e bancada recebida via UDP.")
				quit(0)
				return
		fail("Host nao recebeu construcao do convidado ou posicao. Remotes="+str(game.get("remotes").size()))
		return

	game.call("join_at_address","127.0.0.1")
	if str(game.get("net_role"))!="client":
		fail("Cliente nao iniciou conexao")
		return
	print("NET CLIENT CONNECTING")
	var sent_build := false
	var has_host_avatar := false
	var has_snapshot_wall := false
	var has_live_floor := false
	for tick in range(850):
		await physics_frame
		var world_ready: bool = bool(game.get("net_world_ready"))
		if world_ready and game.get("remotes").has(1):
			has_host_avatar = true
		if world_ready:
			for entry in game.get("placed"):
				if str(entry.get("kind",""))=="wood_wall":
					has_snapshot_wall = true
				elif str(entry.get("kind",""))=="wood_floor":
					has_live_floor = true
		if world_ready and has_host_avatar and has_snapshot_wall and has_live_floor and not sent_build:
			game.call("store_object","bench",player.position+Vector3(0,0,2),0.0,0)
			sent_build = true
			print("NET CLIENT BUILD REQUEST SENT")
		if sent_build:
			var saw_bench := false
			for entry in game.get("placed"):
				if str(entry.get("kind",""))=="bench":
					saw_bench = true
			if saw_bench:
				if str(game.get("net_role"))!="client":
					fail("Modo cliente mudou durante conexao")
					return
				print("NET MULTIPLAYER CLIENT OK: anfitriao visivel, snapshot, construcao e envio sincronizados.")
				for _i in range(30):
					await physics_frame
				quit(0)
				return
	fail("Cliente nao completou. ready=%s avatar=%s snapshot=%s live=%s sent=%s" % [
		str(game.get("net_world_ready")),str(has_host_avatar),str(has_snapshot_wall),str(has_live_floor),str(sent_build)])
