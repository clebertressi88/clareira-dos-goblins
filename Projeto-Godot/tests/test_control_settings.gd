extends SceneTree
## Valida ajustes de teclado, colisoes e interface sem alterar configuracoes no disco.
const KEYBINDS := preload("res://control_bindings.gd")
const MENU := preload("res://medieval_main_menu.gd")

var model: RefCounted
var changed_radius := 2

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	model = KEYBINDS.new()
	model.reset_defaults(false)
	if model.actions().size()<14:
		_fail("Controles insuficientes")
		return
	if model.key_for("goblin_frente")!=KEY_W:
		_fail("Tecla de movimento padrao nao foi configurada")
		return
	var key_old := InputEventKey.new()
	key_old.physical_keycode = KEY_W
	var key_new := InputEventKey.new()
	key_new.physical_keycode = KEY_I
	if not InputMap.action_has_event("goblin_frente",key_old):
		_fail("Acao inicial de movimento nao esta no InputMap")
		return
	if model.rebind("goblin_frente",KEY_I,false)!="":
		_fail("Nao foi possivel personalizar a tecla de movimento")
		return
	if not InputMap.action_has_event("goblin_frente",key_new):
		_fail("Nova tecla nao foi aplicada ao InputMap")
		return
	if InputMap.action_has_event("goblin_frente",key_old):
		_fail("Tecla antiga permaneceu ativa apos o remapeamento")
		return
	if model.rebind("goblin_pular",KEY_I,false).is_empty():
		_fail("Permitiu duplicidade de teclas")
		return
	if model.rebind("goblin_pular",KEY_ESCAPE,false).is_empty():
		_fail("Permitiu mudar a tecla Esc reservada")
		return
	model.reset_defaults(false)
	if model.key_for("goblin_frente")!=KEY_W:
		_fail("Restaurar padrao nao funcionou")
		return

	var ui := MENU.new() as Control
	ui.size=Vector2(1280,720)
	root.add_child(ui)
	await process_frame
	ui.rebuild({
		"role":"solo",
		"active_world_name":"Mundo de teste",
		"worlds":[{"id":"original","name":"Mundo original"}],
		"active_world_id":"original",
		"controls_model":model,
		"view_radius":2
	},{
		"rebind_key":Callable(self,"_rebind"),
		"reset_keys":Callable(self,"_reset"),
		"change_view_radius":Callable(self,"_set_radius")
	})
	ui._activate("settings")
	if not is_instance_valid(ui._view_distance_value):
		_fail("Configuracao de distancia nao apareceu no menu")
		return
	ui._on_distance_changed(4.0)
	if changed_radius!=4 or not ui._view_distance_value.text.contains("9×9"):
		_fail("Distancia maxima de 9x9 chunks nao funciona")
		return
	ui._activate("controls")
	if ui._key_buttons.size()!=model.actions().size():
		_fail("Nem todas as teclas aparecem na tela de configuracoes")
		return
	ui._begin_capture("goblin_frente")
	var typed := InputEventKey.new()
	typed.pressed=true
	typed.physical_keycode=KEY_I
	typed.keycode=KEY_I
	ui._input(typed)
	if model.key_for("goblin_frente")!=KEY_I or ui._key_capture_action!="":
		_fail("Editor visual nao aplicou a tecla escolhida")
		return
	ui._restore_keys()
	if model.key_for("goblin_frente")!=KEY_W:
		_fail("Botao de restaurar controles nao funcionou")
		return
	print("KEY SETTINGS OK: teclas, conflitos, restauracao e visao 9x9")
	quit(0)

func _rebind(action: String,key_code: int) -> String:
	return model.rebind(action,key_code,false)

func _reset() -> void:
	model.reset_defaults(false)

func _set_radius(value: int) -> void:
	changed_radius=value

func _fail(message: String) -> void:
	push_error("KEY SETTINGS FAIL: "+message)
	quit(1)
