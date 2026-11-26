extends Control
## Controles experimentais, exclusivos do Android. Usa os mesmos comandos do PC.
var game: Node
var axis := Vector2.ZERO
var move_finger := -1
var look_finger := -1
var held_actions: Dictionary = {}
var active_last := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hide()

func _process(_delta: float) -> void:
	var active: bool = is_instance_valid(game) and bool(game.get("moving"))
	if active != active_last:
		active_last = active
		visible = active
		if not active:
			reset_touches()
	if active:
		queue_redraw()

func reset_touches() -> void:
	axis = Vector2.ZERO
	move_finger = -1
	look_finger = -1
	for action in held_actions.values():
		Input.action_release(str(action))
	held_actions.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		reset_touches()

func joystick_center() -> Vector2:
	return Vector2(108.0, size.y - 145.0)

func button_positions() -> Dictionary:
	return {
		"attack": Vector2(size.x-66.0,size.y-174.0),
		"interact": Vector2(size.x-163.0,size.y-174.0),
		"jump": Vector2(size.x-66.0,size.y-272.0),
		"run": Vector2(66.0,size.y-276.0),
		"crouch": Vector2(153.0,size.y-276.0),
		"inventory": Vector2(size.x-56.0,112.0),
		"menu": Vector2(size.x-56.0,40.0),
		"camera": Vector2(size.x-141.0,40.0),
		"rotate": Vector2(size.x-163.0,size.y-272.0),
		"drop": Vector2(size.x-141.0,112.0)
	}

func _draw() -> void:
	var center := joystick_center()
	draw_circle(center,80.0,Color(0.09,0.12,0.10,0.54))
	draw_arc(center,80.0,0.0,TAU,48,Color(0.85,0.78,0.58,0.7),2.0,true)
	draw_circle(center+axis*55.0,30.0,Color(0.83,0.72,0.49,0.82))
	var labels := {"attack":"Atacar","interact":"Usar","jump":"Pular","run":"Correr","crouch":"Agachar","inventory":"Bolsa","menu":"Menu","camera":"Visão","rotate":"Girar","drop":"Largar"}
	var positions := button_positions()
	var font := ThemeDB.fallback_font
	for name in positions:
		var p: Vector2 = positions[name]
		var radius := 33.0 if name in ["menu","inventory","camera","drop"] else 40.0
		draw_circle(p,radius,Color(0.09,0.12,0.10,0.65))
		draw_arc(p,radius,0.0,TAU,32,Color(0.85,0.78,0.58,0.8),2.0,true)
		var caption: String = labels[name]
		var width := font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
		draw_string(font,p+Vector2(-width*0.5,5.0),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color.WHITE)

func set_axis(pos: Vector2) -> void:
	var value := (pos-joystick_center())/65.0
	axis = value.limit_length(1.0) if value.length()>0.12 else Vector2.ZERO

func hold_action(finger: int, action: String) -> void:
	held_actions[finger] = action
	Input.action_press(action)

func press_button(name: String, finger: int) -> void:
	match name:
		"attack": game.call("primary")
		"interact": game.call("secondary")
		"jump":
			game.set("jump",true)
			hold_action(finger,"goblin_pular")
		"run": hold_action(finger,"goblin_correr")
		"crouch": hold_action(finger,"goblin_agachar")
		"inventory": game.call("show_inventory")
		"menu": game.call("show_menu")
		"camera": game.call("toggle_view")
		"drop": game.call("drop_selected")
		"rotate":
			game.call("mobile_rotate_or_use")

func _input(event: InputEvent) -> void:
	if not is_instance_valid(game) or not bool(game.get("moving")):
		return
	if event is InputEventScreenTouch:
		var finger: int = event.index
		if not event.pressed or event.canceled:
			if finger == move_finger:
				move_finger = -1
				axis = Vector2.ZERO
			if finger == look_finger:
				look_finger = -1
			if held_actions.has(finger):
				Input.action_release(str(held_actions[finger]))
				held_actions.erase(finger)
		else:
			var pos: Vector2 = event.position
			var positions := button_positions()
			var hit_button := false
			for name in positions:
				var p: Vector2 = positions[name]
				var radius := 34.0 if name in ["menu","inventory","camera","drop"] else 42.0
				if pos.distance_to(p) <= radius:
					press_button(str(name),finger)
					hit_button = true
					break
			if not hit_button:
				var frames: Array = game.get("hotbar_frames")
				for i in range(frames.size()):
					var frame: Control = frames[i]
					if frame.get_global_rect().has_point(pos):
						game.set("selected",i)
						hit_button = true
						break
			if not hit_button and move_finger == -1 and pos.distance_to(joystick_center()) <= 110.0:
				move_finger = finger
				set_axis(pos)
				hit_button = true
			if not hit_button and look_finger == -1:
				look_finger = finger
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == move_finger:
			set_axis(event.position)
		elif event.index == look_finger:
			var player: Node3D = game.get("player")
			var camera: Camera3D = game.get("camera")
			player.rotate_y(-event.relative.x*0.0035)
			camera.rotation.x = clampf(camera.rotation.x-event.relative.y*0.0035,-1.42,1.42)
		get_viewport().set_input_as_handled()
