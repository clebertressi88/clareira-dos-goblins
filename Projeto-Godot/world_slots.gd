extends RefCounted
## Catalogo local de mundos. Mantem o save antigo intacto e isola os novos mapas.

const ORIGINAL_SAVE := "user://clareira-nativa.json"
const INDEX_PATH := "user://clareira-mundos.json"
const SAVE_FOLDER := "user://clareira-mundos"

var worlds: Array[Dictionary] = []
var active_id := "original"
var last_error := ""

func initialize() -> void:
	worlds.clear()
	active_id = "original"
	last_error = ""
	var valid_index := false
	if FileAccess.file_exists(INDEX_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
		if parsed is Dictionary and parsed.get("worlds",null) is Array:
			valid_index = true
			for entry in parsed["worlds"]:
				if not entry is Dictionary:
					continue
				var id := str(entry.get("id",""))
				if not _valid_id(id) or contains_world(id):
					continue
				var name := _clean_name(str(entry.get("name","")))
				if name.is_empty():
					name = "Mundo original" if id=="original" else "Mundo sem nome"
				worlds.append({"id":id,"name":name})
			active_id = str(parsed.get("active_id","original"))
		else:
			last_error = "Catálogo de mundos inválido. O arquivo original foi preservado."
			worlds.append({"id":"original","name":"Mundo original"})
			return
	if not contains_world("original"):
		worlds.insert(0,{"id":"original","name":"Mundo original"})
	if not contains_world(active_id):
		active_id = "original"
	if not valid_index:
		_write_index()

func contains_world(id: String) -> bool:
	for item in worlds:
		if str(item.get("id",""))==id:
			return true
	return false

func list_worlds() -> Array:
	return worlds.duplicate(true)

func active_name() -> String:
	for item in worlds:
		if str(item["id"])==active_id:
			return str(item["name"])
	return "Mundo original"

func save_path() -> String:
	if active_id=="original":
		return ORIGINAL_SAVE
	return SAVE_FOLDER+"/"+active_id+".json"

func prepare_save() -> bool:
	if active_id=="original":
		return true
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_FOLDER))
	if error!=OK:
		last_error = "Não foi possível criar a pasta de salvamentos."
		return false
	return true

func create_world(input_name: String) -> bool:
	if not _accept_name(input_name,""):
		return false
	var name := _clean_name(input_name)
	var previous_id := active_id
	var id := ""
	for attempt in range(10):
		id = "mundo-%d-%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()+attempt]
		if not contains_world(id):
			break
	if contains_world(id):
		last_error = "Não foi possível gerar um identificador para o mundo."
		return false
	worlds.append({"id":id,"name":name})
	active_id = id
	if not _write_index():
		worlds.pop_back()
		active_id = previous_id
		return false
	return true

func rename_world(id: String, input_name: String) -> bool:
	if not contains_world(id):
		last_error = "O mundo selecionado não existe."
		return false
	if not _accept_name(input_name,id):
		return false
	for i in range(worlds.size()):
		if str(worlds[i]["id"])==id:
			var previous_name := str(worlds[i]["name"])
			worlds[i]["name"] = _clean_name(input_name)
			if not _write_index():
				worlds[i]["name"] = previous_name
				return false
			return true
	return false

func select_world(id: String) -> bool:
	if not contains_world(id):
		last_error = "O mundo selecionado não existe."
		return false
	if id==active_id:
		return true
	var previous_id := active_id
	active_id = id
	if not _write_index():
		active_id = previous_id
		return false
	return true

func _accept_name(input_name: String, except_id: String) -> bool:
	var name := _clean_name(input_name)
	if name.is_empty():
		last_error = "Digite um nome para o mundo."
		return false
	if name.length()>36:
		last_error = "O nome pode ter no máximo 36 caracteres."
		return false
	for item in worlds:
		if str(item["id"])!=except_id and str(item["name"]).to_lower()==name.to_lower():
			last_error = "Já existe um mundo com esse nome."
			return false
	last_error = ""
	return true

func _clean_name(input_name: String) -> String:
	return input_name.replace("\n"," ").replace("\r"," ").strip_edges()

func _valid_id(id: String) -> bool:
	if id=="original":
		return true
	if not id.begins_with("mundo-") or id.length()>60:
		return false
	var digits := id.substr(6)
	if digits.is_empty():
		return false
	for character in digits:
		if character not in "0123456789-":
			return false
	return true

func _write_index() -> bool:
	var file := FileAccess.open(INDEX_PATH+".tmp",FileAccess.WRITE)
	if file==null:
		last_error = "Não foi possível salvar a lista de mundos."
		return false
	file.store_string(JSON.stringify({"active_id":active_id,"worlds":worlds}))
	file.flush()
	file.close()
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(INDEX_PATH+".tmp"),
		ProjectSettings.globalize_path(INDEX_PATH)
	)
	if error!=OK:
		last_error = "Não foi possível atualizar a lista de mundos."
		return false
	last_error = ""
	return true
