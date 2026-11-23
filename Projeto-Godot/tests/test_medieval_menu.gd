extends SceneTree
## Verifica as paginas e controles do menu sem iniciar o mundo 3D.
const MAIN_MENU := preload("res://medieval_main_menu.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var ui := MAIN_MENU.new() as Control
	ui.size = Vector2(1280,720)
	root.add_child(ui)
	await process_frame
	ui.rebuild({
		"role":"solo",
		"active_world_id":"original",
		"active_world_name":"Mundo original",
		"worlds":[{"id":"original","name":"Mundo original"},{"id":"mundo-123-456","name":"Vale dos Goblins"}],
		"last_connected_ip":"192.168.1.5",
		"ip":"192.168.1.5"
	},{})
	await process_frame
	if ui._nav_buttons.size()!=9:
		_fail("A navegacao medieval nao criou os 9 botoes")
		return
	if not is_instance_valid(ui._primary_button):
		_fail("Botao Jogar Agora ausente")
		return
	if ui._stage.scale.x<=0.0 or ui._stage.scale.x>1.0:
		_fail("Escala responsiva invalida")
		return
	ui._activate("new_world")
	if not is_instance_valid(ui.world_create_input):
		_fail("Formulario de novo mundo ausente")
		return
	ui._activate("worlds")
	if not is_instance_valid(ui.world_picker) or ui.world_picker.item_count!=2:
		_fail("Seletor de mapas nao mostra os mundos")
		return
	ui._activate("network")
	if not is_instance_valid(ui.ip_input) or ui.ip_input.text!="192.168.1.5":
		_fail("Campo do ultimo IP da LAN ausente")
		return
	ui._activate("settings")
	if not is_instance_valid(ui._volume_label):
		_fail("Configuracoes de audio ausentes")
		return
	ui._activate("controls")
	ui._activate("updates")
	ui._activate("credits")
	ui._activate("home")
	if not is_instance_valid(ui._primary_button):
		_fail("A tela inicial nao retornou")
		return
	print("MEDIEVAL MENU OK: telas, mapa, IP, controles e responsividade")
	quit(0)

func _fail(reason: String) -> void:
	push_error("MEDIEVAL MENU FAIL: "+reason)
	quit(1)
