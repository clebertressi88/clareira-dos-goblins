extends SceneTree
## Verifica que cada item de inventario possui um icone carregavel.
func _initialize() -> void:
	var script := load("res://main.gd") as GDScript
	if script == null:
		printerr("ITEM ICON FAIL: main.gd absent")
		quit(1)
		return
	var constants := script.get_script_constant_map()
	var items: Array = constants["ITEMS"]
	var icons: Array = constants["ITEM_ICONS"]
	if icons.size()!=items.size():
		printerr("ITEM ICON FAIL: %d icons for %d items" % [icons.size(),items.size()])
		quit(1)
		return
	for index in [27,28]:
		if icons[index]==null or not icons[index] is Texture2D:
			printerr("ITEM ICON FAIL: missing texture at index %d" % index)
			quit(1)
			return
	print("ITEM ICON OK: tomato and seeds load correctly")
	quit(0)
