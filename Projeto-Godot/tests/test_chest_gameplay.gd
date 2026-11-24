extends SceneTree
# Teste de regressao do bau: receita, modelo e transferencia sem perdas.
func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	printerr("CHEST TEST FAIL: "+message)
	quit(1)

func _run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	if scene==null:
		_fail("Cena nao encontrada")
		return
	var game := scene.instantiate() as Node3D
	root.add_child(game)
	await physics_frame
	await physics_frame
	var constants: Dictionary = game.get_script().get_script_constant_map()
	var kinds: Array = constants["ITEM_KINDS"]
	if kinds.find("chest")!=29:
		_fail("ID do bau deve ser 29")
		return
	var recipes: Dictionary = constants["STATION_PATTERNS"]
	var expected := [7,7,7,7,11,7,7,7,7]
	if recipes.get("chest",[])!=expected:
		_fail("Receita de 8 tabuas e cipo incorreta")
		return
	var world := game.get("objects") as Dictionary
	var chest_id := "item-test-chest"
	var chest := game.call("spawn_object","chest",chest_id,Vector3(2,1,2),game,0.0) as Node3D
	if chest==null or chest.get_node_or_null("Tampa")==null or not world.has(chest_id):
		_fail("Modelo ou tampa ausente")
		return
	var stock: Array = game.get("stock")
	stock[7] = 70
	game.set("stock",stock)
	var moved := int(game.call("chest_apply_transfer",chest_id,0,7,70,true))
	if moved!=64 or int(game.get("stock")[7])!=6:
		_fail("Deposito e limite de 64 unidades")
		return
	if not bool(game.call("chest_has_items",chest_id)):
		_fail("Bau preenchido nao foi detectado")
		return
	moved = int(game.call("chest_apply_transfer",chest_id,0,7,10,false))
	if moved!=10 or int(game.get("stock")[7])!=16:
		_fail("Retirada parcial incorreta")
		return
	moved = int(game.call("chest_apply_transfer",chest_id,0,7,54,false))
	if moved!=54 or bool(game.call("chest_has_items",chest_id)):
		_fail("Retirada final nao esvaziou o bau")
		return
	if int(game.get("stock")[7])!=70:
		_fail("Houve perda de itens")
		return
	print("CHEST GAMEPLAY PASS")
	quit(0)
