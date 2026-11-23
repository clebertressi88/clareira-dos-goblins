extends RefCounted
## Inventario LAN privado por mapa, armazenado neste computador.
## O anfitriao envia o identificador persistente do mundo; nao usamos IP como chave.

const ROOT := "user://clareira-lan-inventarios"
const SCHEMA := 1

static func valid_world_uid(uid: String) -> bool:
	if uid.length()!=32:
		return false
	for i in range(uid.length()):
		if not "0123456789abcdef".contains(uid.substr(i,1)):
			return false
	return true

static func path_for_world(uid: String) -> String:
	if not valid_world_uid(uid):
		return ""
	return ROOT+"/"+uid+".json"

static func has_inventory(uid: String) -> bool:
	var path := path_for_world(uid)
	return not path.is_empty() and FileAccess.file_exists(path)

static func read_inventory(uid: String) -> Dictionary:
	var path := path_for_world(uid)
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary:
		return {}
	if int(value.get("schema",0))!=SCHEMA or not value.get("inventory",null) is Dictionary:
		return {}
	return (value["inventory"] as Dictionary).duplicate(true)

static func write_inventory(uid: String, inventory: Dictionary) -> bool:
	var path := path_for_world(uid)
	if path.is_empty():
		return false
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))!=OK:
		return false
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:
		return false
	file.store_string(JSON.stringify({"schema":SCHEMA,"inventory":inventory}))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK
