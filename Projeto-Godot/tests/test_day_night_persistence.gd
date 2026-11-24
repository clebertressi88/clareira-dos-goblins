extends SceneTree
## Regressao: horario salvo no mundo e restaurado na sincronizacao.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	if scene==null:
		printerr("DAY NIGHT SAVE FAIL: cena principal ausente")
		quit(1)
		return
	var game := scene.instantiate() as Node3D
	root.add_child(game)
	await physics_frame
	var constants: Dictionary = game.get_script().get_script_constant_map()
	var full_cycle := float(constants["NPC_DAY_SECONDS"])+float(constants["NPC_NIGHT_SECONDS"])
	var checkpoint := float(constants["NPC_DAY_SECONDS"])+78.5
	game.set("npc_world_clock",checkpoint)
	game.call("update_npc_daylight",0.0)
	if not bool(game.call("npc_is_night")):
		printerr("DAY NIGHT SAVE FAIL: teste deveria comecar a noite")
		quit(1)
		return
	var snapshot: Dictionary = game.call("capture_net_world")
	if absf(float(snapshot.get("npc_world_clock",-1.0))-checkpoint)>0.001:
		printerr("DAY NIGHT SAVE FAIL: snapshot nao contem o relogio")
		quit(1)
		return
	game.set("npc_world_clock",0.0)
	game.call("apply_net_world",snapshot)
	var restored := float(game.get("npc_world_clock"))
	if absf(restored-checkpoint)>0.001 or not bool(game.call("npc_is_night")):
		printerr("DAY NIGHT SAVE FAIL: fase da noite nao foi recuperada")
		quit(1)
		return
	game.call("update_npc_daylight",0.0)
	if absf(float(game.get("npc_world_clock"))-checkpoint)>0.001:
		printerr("DAY NIGHT SAVE FAIL: restauracao avancou o relogio")
		quit(1)
		return
	if restored<0.0 or restored>=full_cycle:
		printerr("DAY NIGHT SAVE FAIL: relogio fora do ciclo")
		quit(1)
		return
	print("DAY NIGHT SAVE OK: horario mantido e restaurado sem avancar")
	quit(0)
