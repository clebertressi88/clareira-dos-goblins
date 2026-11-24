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
	var day_seconds := float(constants["NPC_DAY_SECONDS"])
	var night_seconds := float(constants["NPC_NIGHT_SECONDS"])
	var full_cycle := day_seconds+night_seconds
	if not is_equal_approx(day_seconds,night_seconds):
		printerr("DAY NIGHT SAVE FAIL: dia e noite precisam ter duracao igual")
		quit(1)
		return
	var sun := game.get("npc_sun") as DirectionalLight3D
	var moon := game.get("npc_moon") as DirectionalLight3D
	var sky := game.get("npc_sky") as ProceduralSkyMaterial
	if sun==null or moon==null or sky==null:
		printerr("DAY NIGHT SAVE FAIL: Sol, Lua ou ceu inexistentes")
		quit(1)
		return
	if sun.light_angular_distance<=0.5 or moon.light_angular_distance<=0.5 or sky.sun_angle_max<=5.0:
		printerr("DAY NIGHT SAVE FAIL: astros continuam pequenos")
		quit(1)
		return
	# Mesma trajetoria em fases equivalentes: leste -> alto no ceu -> oeste.
	for fraction in [0.10,0.50,0.90]:
		var t: float = float(fraction)
		game.set("npc_world_clock",t*day_seconds)
		game.call("update_npc_daylight",0.0)
		var sun_arc: Vector3 = sun.rotation_degrees
		if sun.light_energy<=0.0 or moon.light_energy>0.0:
			printerr("DAY NIGHT SAVE FAIL: iluminacao incorreta durante o dia")
			quit(1)
			return
		game.set("npc_world_clock",day_seconds+t*night_seconds)
		game.call("update_npc_daylight",0.0)
		var moon_arc: Vector3 = moon.rotation_degrees
		if moon.light_energy<=0.0 or sun.light_energy>0.0:
			printerr("DAY NIGHT SAVE FAIL: iluminacao incorreta durante a noite")
			quit(1)
			return
		if absf(sun_arc.x-moon_arc.x)>.01 or absf(sun_arc.y-moon_arc.y)>.01:
			printerr("DAY NIGHT SAVE FAIL: Lua usa caminho diferente do Sol")
			quit(1)
			return
	game.set("npc_world_clock",0.0)
	game.call("update_npc_daylight",0.0)
	var sunrise: float = sun.rotation_degrees.y
	game.set("npc_world_clock",day_seconds)
	game.call("update_npc_daylight",0.0)
	var moonrise: float = moon.rotation_degrees.y
	if absf(sunrise-moonrise)>.01:
		printerr("DAY NIGHT SAVE FAIL: Lua nao nasce no mesmo horizonte do Sol")
		quit(1)
		return
	if not (sunrise < 0.0):
		printerr("DAY NIGHT SAVE FAIL: Sol nao nasce no lado leste")
		quit(1)
		return
	game.set("npc_world_clock",day_seconds-0.001)
	game.call("update_npc_daylight",0.0)
	var sunset: float = sun.rotation_degrees.y
	game.set("npc_world_clock",full_cycle-0.001)
	game.call("update_npc_daylight",0.0)
	var moonset: float = moon.rotation_degrees.y
	if not (sunset > 0.0) or absf(sunset-moonset)>.01:
		printerr("DAY NIGHT SAVE FAIL: Sol e Lua nao se poem no mesmo lado")
		quit(1)
		return
	var checkpoint := day_seconds+78.5
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
	print("DAY NIGHT SAVE OK: dia/noite iguais, Sol e Lua no mesmo arco, tamanho ampliado e relogio persistido")
	quit(0)
