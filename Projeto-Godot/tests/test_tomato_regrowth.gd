extends SceneTree
## Testa a colheita individual sem arrancar planta e retorno gradual dos frutos.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	if scene==null:
		printerr("TOMATO REGROW FAIL: cena principal ausente")
		quit(1)
		return
	var game := scene.instantiate() as Node3D
	root.add_child(game)
	await physics_frame
	var constants: Dictionary = game.get_script().get_script_constant_map()
	if int(constants["TOMATO_MAX_FRUITS"])!=4 or float(constants["TOMATO_FRUIT_SECONDS"])!=600.0:
		printerr("TOMATO REGROW FAIL: tempos/quantidades invalidos")
		quit(1)
		return
	var plant := game.call("spawn_object","tomato_plant","test-regrow-tomato",Vector3(6,0,6)) as Node3D
	if plant==null or int(game.call("tomato_available",plant))!=4:
		printerr("TOMATO REGROW FAIL: planta deve comecar com 4 frutos")
		quit(1)
		return
	var red_before := 0
	for cluster in plant.get_children():
		if str(cluster.name).begins_with("Fruto_") and cluster.visible:
			for part in cluster.get_children():
				if part.name=="TomateMaduro":
					red_before += 1
	if red_before!=4:
		printerr("TOMATO REGROW FAIL: frutos disponiveis devem ser vermelhos")
		quit(1)
		return
	if not bool(game.call("take_one_tomato",plant)) or int(game.call("tomato_available",plant))!=3:
		printerr("TOMATO REGROW FAIL: colher deve retirar apenas 1")
		quit(1)
		return
	var ripe_after := 0
	var green_after := 0
	for cluster in plant.get_children():
		if str(cluster.name).begins_with("Fruto_") and cluster.visible:
			for part in cluster.get_children():
				if part.name=="TomateMaduro":
					ripe_after += 1
				if part.name=="TomateVerde":
					green_after += 1
	if ripe_after!=3 or green_after!=1:
		printerr("TOMATO REGROW FAIL: fruto regenerando deve estar verde")
		quit(1)
		return
	if not is_instance_valid(plant) or str(plant.get_meta("kind",""))!="tomato_plant":
		printerr("TOMATO REGROW FAIL: planta foi arrancada")
		quit(1)
		return
	var state: Dictionary = game.get("tomato_fruits")
	var item: Dictionary = state["test-regrow-tomato"]
	item["next"] = Time.get_unix_time_from_system()-1.0
	state["test-regrow-tomato"] = item
	game.set("tomato_fruits",state)
	game.call("update_tomato_fruit_regrowth")
	if int(game.call("tomato_available",plant))!=4:
		printerr("TOMATO REGROW FAIL: fruto nao cresceu novamente")
		quit(1)
		return
	print("TOMATO REGROW OK: 1 fruto por coleta, planta persistente e regrowth")
	quit(0)
