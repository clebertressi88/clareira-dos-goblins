extends SceneTree
## Primeiro acesso vazio, retorno com inventario salvo e isolamento entre mapas.
const LAN_SLOTS := preload("res://lan_inventory_slots.gd")

func _initialize() -> void:
	var one := Crypto.new().generate_random_bytes(16).hex_encode()
	var two := Crypto.new().generate_random_bytes(16).hex_encode()
	if not LAN_SLOTS.valid_world_uid(one) or LAN_SLOTS.valid_world_uid("../bad"):
		_fail("identificador de mundo nao foi validado")
		return
	if LAN_SLOTS.has_inventory(one) or not LAN_SLOTS.read_inventory(one).is_empty():
		_fail("primeiro acesso nao comecou vazio")
		return
	var bag := {"stock":[0,7,2],"reserve":[0,1,0],"tool_durability":{"9":[47]},"backpack_slots":[[1,4]],"bar_items":[1,2]}
	if not LAN_SLOTS.write_inventory(one,bag):
		_fail("salvamento do inventario falhou")
		return
	var again: Dictionary = LAN_SLOTS.read_inventory(one)
	if again.get("stock",[])!=bag["stock"] or again.get("tool_durability",{})!=bag["tool_durability"]:
		_fail("itens ou durabilidade nao foram restaurados")
		return
	if LAN_SLOTS.has_inventory(two) or not LAN_SLOTS.read_inventory(two).is_empty():
		_fail("mapas diferentes compartilharam inventario")
		return
	# Atualizacoes do personagem sempre substituem o ultimo estado.
	bag["stock"]=[0,4,3]
	if not LAN_SLOTS.write_inventory(one,bag) or LAN_SLOTS.read_inventory(one).get("stock",[])!=bag["stock"]:
		_fail("retorno ao mesmo mapa nao preservou o progresso mais recente")
		return
	# Confere tambem o estado real do inventario, sem iniciar a cena 3D.
	var game = preload("res://main.gd").new()
	while game.stock.size()<game.ITEMS.size():
		game.stock.append(0)
	while game.reserve.size()<game.ITEMS.size():
		game.reserve.append(0)
	game.inventory_slots.resize(game.ITEMS.size())
	game.inventory_slots.fill(-1)
	game.backpack_slots.resize(game.BACKPACK_SIZE)
	game.backpack_slots.fill(Vector2i(-1,0))
	game.stock[1]=11
	game.apply_inventory_state({})
	if game.stock[1]!=0 or game.health!=100:
		_fail("primeira visita importou inventario do jogador offline")
		return
	var equipped := {"stock":[0,5,3,0,0,0,0,0,0,1],"bar_items":[1,2,9],
		"tool_durability":{"9":[38]},"reserve":[0,2],"health":76}
	game.apply_inventory_state(equipped)
	if game.stock[1]!=5 or game.stock[2]!=3 or game.tool_remaining(9)!=38 or game.health!=76:
		_fail("inventario do mapa nao foi restaurado corretamente")
		return
	var snapshot: Dictionary = game.capture_inventory_state()
	game.apply_inventory_state({})
	game.apply_inventory_state(snapshot)
	if game.stock[1]!=5 or game.tool_remaining(9)!=38:
		_fail("desconexao nao restaurou o inventario anterior")
		return
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LAN_SLOTS.path_for_world(one)))
	print("LAN INVENTORY OK: primeira visita, retorno, durabilidade e mapas isolados")
	quit(0)

func _fail(reason: String) -> void:
	push_error("LAN INVENTORY FAIL: "+reason)
	quit(1)
