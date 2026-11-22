extends Node3D
## Comparacao visual isolada. Nenhum save ou NPC real e modificado.
## ESC ou botao "Voltar" retorna ao menu original.

const OLD_RIG = preload("res://npc_goblin.gd")
const NEW_RIG = preload("res://experimentos/goblin_skin_v2.gd")

var characters: Array[Node3D] = []
var mode := "walk"
var angle := 0.0
var sword_on := false
var shield_on := false
var caption: Label

func _ready() -> void:
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	_build_environment()
	_spawn(OLD_RIG,Vector3(-1.3,0,0),"SKIN ATUAL")
	_spawn(NEW_RIG,Vector3(1.3,0,0),"SKIN NOVA V2")
	_build_controls()


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("#9bb3af")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("#eeeeea")
	env.ambient_light_energy=0.75
	world.environment=env
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-48,-30,0)
	light.light_energy=1.3
	add_child(light)
	var floor := MeshInstance3D.new()
	floor.name="ChaoDeTeste"
	var plane := PlaneMesh.new()
	plane.size=Vector2(15,15)
	floor.mesh=plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color=Color("#566b59")
	mat.roughness=1.0
	floor.material_override=mat
	add_child(floor)
	var camera := Camera3D.new()
	camera.position=Vector3(0,2.2,6.2)
	add_child(camera)
	camera.look_at(Vector3(0,0.85,0),Vector3.UP)
	camera.current=true
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=3.5


func _spawn(script: GDScript, place: Vector3, title: String) -> void:
	var holder := Node3D.new()
	holder.name=title
	holder.position=place
	add_child(holder)
	var rig: Node3D=script.new()
	rig.name="GoblinRig"
	holder.add_child(rig)
	if not bool(rig.call("install")):
		push_error("Nao foi possivel carregar "+title)
		return
	rig.call("set_equipment",false,false)
	characters.append(rig)
	var description := Label3D.new()
	description.name="Legenda"
	description.position=Vector3(0,1.7,0)
	description.text=title
	description.font_size=42
	description.pixel_size=.0025
	description.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	holder.add_child(description)


func _build_controls() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var container := PanelContainer.new()
	container.position=Vector2(20,18)
	container.custom_minimum_size=Vector2(350,0)
	layer.add_child(container)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",7)
	container.add_child(column)
	var title := Label.new()
	title.text="LABORATORIO DE SKIN DOS GOBLINS"
	title.add_theme_font_size_override("font_size",17)
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text="Esquerda: skin atual  |  Direita: nova V2"
	column.add_child(subtitle)
	var explanation := Label.new()
	explanation.text="Textura e equipamentos originais.\nEste teste nao modifica seu jogo nem seus saves."
	column.add_child(explanation)
	_button(column,"Parado",_set_motion.bind("idle"))
	_button(column,"Caminhar",_set_motion.bind("walk"))
	_button(column,"Correr",_set_motion.bind("run"))
	_button(column,"Girar ambos 90 graus",_turn)
	_button(column,"Equipar / retirar espada",_sword)
	_button(column,"Equipar / retirar escudo",_shield)
	_button(column,"Voltar ao jogo (ESC)",_back)
	caption=Label.new()
	caption.text="Estado: Caminhando"
	column.add_child(caption)


func _button(parent: VBoxContainer, name: String, action: Callable) -> void:
	var button_node := Button.new()
	button_node.text=name
	parent.add_child(button_node)
	button_node.pressed.connect(action)


func _set_motion(state: String) -> void:
	mode=state
	if caption != null:
		caption.text="Estado: "+("Parado" if mode=="idle" else "Correndo" if mode=="run" else "Caminhando")


func _turn() -> void:
	angle=fposmod(angle+PI*.5,TAU)
	for rig in characters:
		if is_instance_valid(rig) and is_instance_valid(rig.get_parent()):
			(rig.get_parent() as Node3D).rotation.y=angle


func _sword() -> void:
	sword_on=not sword_on
	_apply_equipment()


func _shield() -> void:
	shield_on=not shield_on
	_apply_equipment()


func _apply_equipment() -> void:
	for rig in characters:
		if is_instance_valid(rig):
			rig.call("set_equipment",sword_on,shield_on)


func _process(delta: float) -> void:
	var speed := 0.0 if mode=="idle" else 3.2 if mode=="run" else 1.6
	for rig in characters:
		if is_instance_valid(rig):
			rig.call("animate",Vector3(0,0,speed),delta,true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		_back()


func _back() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
