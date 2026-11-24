extends SceneTree
# Regressao da pa de pedra: receita, modelo e durabilidade.
func _initialize() -> void:
	call_deferred("_check")

func _fail(why: String) -> void:
	printerr("STONE SHOVEL TEST FAIL: "+why)
	quit(1)

func _check() -> void:
	var scene := load("res://main.tscn") as PackedScene
	if scene==null:
		_fail("Cena principal nao encontrada")
		return
	var game := scene.instantiate()
	root.add_child(game)
	await physics_frame
	var constants: Dictionary = game.get_script().get_script_constant_map()
	if (constants.get("ITEM_KINDS",[]) as Array).find("stone_shovel")!=34:
		_fail("Indice de item incorreto")
		return
	if int((constants.get("TOOL_MAX_DURABILITY",{}) as Dictionary).get(34,0))!=180:
		_fail("Durabilidade incorreta")
		return
	if (constants.get("STATION_PATTERNS",{}) as Dictionary).get("stone_shovel",[])!=[-1,2,-1,-1,1,-1,-1,1,-1]:
		_fail("Receita invalida")
		return
	var tool := Node3D.new()
	root.add_child(tool)
	preload("res://stone_shovel_model.gd").build(tool)
	if tool.get_child_count()<6:
		_fail("Modelo tridimensional nao foi criado")
		return
	print("STONE SHOVEL TEST PASS")
	quit(0)
