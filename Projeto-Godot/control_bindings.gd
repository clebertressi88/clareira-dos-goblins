extends RefCounted
## Mapeamento local de teclado, independente de mundos e partidas LAN.
## Os atalhos 1-9 (hotbar) e Esc (menu/Cancelar) permanecem reservados.

const FILE_PATH := "user://clareira-menu.cfg"
const SECTION := "teclado"
const ACTION_ORDER := [
	"goblin_frente","goblin_tras","goblin_esquerda","goblin_direita",
	"goblin_correr","goblin_pular","goblin_agachar","goblin_inventario",
	"goblin_largar","goblin_interagir","goblin_girar_usar","goblin_girar_alternativo",
	"goblin_camera","goblin_respawn","goblin_subir_construcao","goblin_descer_construcao"
]
const LABELS := {
	"goblin_frente":"Andar para frente",
	"goblin_tras":"Andar para trás",
	"goblin_esquerda":"Andar para esquerda",
	"goblin_direita":"Andar para direita",
	"goblin_correr":"Correr",
	"goblin_pular":"Pular / subir na água",
	"goblin_agachar":"Agachar / descer na água",
	"goblin_inventario":"Abrir inventário",
	"goblin_largar":"Largar item",
	"goblin_interagir":"Atacar / usar (teclado)",
	"goblin_girar_usar":"Girar construção / comer",
	"goblin_girar_alternativo":"Girar parede / altura de piso",
	"goblin_camera":"Trocar câmera",
	"goblin_respawn":"Voltar à clareira (resgate)",
	"goblin_subir_construcao":"Subir nível de construção",
	"goblin_descer_construcao":"Descer nível de construção"
}
const DEFAULTS := {
	"goblin_frente":KEY_W,"goblin_tras":KEY_S,
	"goblin_esquerda":KEY_A,"goblin_direita":KEY_D,
	"goblin_correr":KEY_SHIFT,"goblin_pular":KEY_SPACE,
	"goblin_agachar":KEY_X,"goblin_inventario":KEY_E,
	"goblin_largar":KEY_Q,"goblin_interagir":KEY_F,
	"goblin_girar_usar":KEY_R,"goblin_girar_alternativo":KEY_T,
	"goblin_camera":KEY_F5,"goblin_respawn":KEY_F10,
	"goblin_subir_construcao":KEY_PAGEUP,"goblin_descer_construcao":KEY_PAGEDOWN
}
# Setas e C continuam disponíveis como alternativas.
const ALTERNATIVES := {
	"goblin_frente":KEY_UP,"goblin_tras":KEY_DOWN,
	"goblin_esquerda":KEY_LEFT,"goblin_direita":KEY_RIGHT,
	"goblin_inventario":KEY_C
}

var bindings: Dictionary = DEFAULTS.duplicate(true)

func configure() -> void:
	var config := ConfigFile.new()
	if config.load(FILE_PATH)==OK:
		var used := {}
		for name in ACTION_ORDER:
			var action := str(name)
			var saved := int(config.get_value(SECTION,action,DEFAULTS[action]))
			if not is_valid_key(saved):
				continue
			if _has_conflict_with_secondary(action,saved):
				continue
			if used.has(saved):
				continue
			bindings[action] = saved
			used[saved] = true
	_apply_to_input_map()

func actions() -> Array:
	return ACTION_ORDER.duplicate()

func label_for(action: String) -> String:
	return str(LABELS.get(action,action))

func key_for(action: String) -> int:
	return int(bindings.get(action,KEY_NONE))

func text_for(action: String) -> String:
	var main := OS.get_keycode_string(key_for(action))
	if ALTERNATIVES.has(action):
		return main+" / "+OS.get_keycode_string(int(ALTERNATIVES[action]))
	return main

func is_valid_key(code: int) -> bool:
	if code in [KEY_NONE,KEY_ESCAPE,KEY_CTRL,KEY_ALT,KEY_META]:
		return false
	if code>=KEY_1 and code<=KEY_9:
		return false
	return code>0 and code<0x4000000

func conflict_with(action: String,code: int) -> String:
	if not is_valid_key(code):
		return "Esc e teclas 1–9 são reservadas para o menu e a barra de itens."
	for other in ACTION_ORDER:
		var name := str(other)
		if name==action:
			continue
		if key_for(name)==code or (ALTERNATIVES.has(name) and int(ALTERNATIVES[name])==code):
			return "Esta tecla já está em uso: "+label_for(name)+"."
	return ""

func rebind(action: String,code: int,save_to_disk: bool = true) -> String:
	if not DEFAULTS.has(action):
		return "Comando desconhecido."
	var error := conflict_with(action,code)
	if not error.is_empty():
		return error
	bindings[action] = code
	_register(action)
	if save_to_disk:
		_save()
	return ""

func reset_defaults(save_to_disk: bool = true) -> void:
	bindings = DEFAULTS.duplicate(true)
	_apply_to_input_map()
	if save_to_disk:
		_save()

func _has_conflict_with_secondary(action: String,code: int) -> bool:
	for other in ALTERNATIVES:
		if other!=action and int(ALTERNATIVES[other])==code:
			return true
	return false

func _apply_to_input_map() -> void:
	for entry in ACTION_ORDER:
		_register(str(entry))

func _register(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var keys := [key_for(action)]
	if ALTERNATIVES.has(action) and int(ALTERNATIVES[action])!=key_for(action):
		keys.append(int(ALTERNATIVES[action]))
	for key in keys:
		var physical := InputEventKey.new()
		physical.physical_keycode = int(key)
		InputMap.action_add_event(action,physical)
		var logical := InputEventKey.new()
		logical.keycode = int(key)
		InputMap.action_add_event(action,logical)

func _save() -> void:
	var config := ConfigFile.new()
	config.load(FILE_PATH)
	for action in ACTION_ORDER:
		config.set_value(SECTION,str(action),key_for(str(action)))
	var result := config.save(FILE_PATH)
	if result!=OK:
		push_warning("Falha ao salvar controles personalizados: %d" % result)
