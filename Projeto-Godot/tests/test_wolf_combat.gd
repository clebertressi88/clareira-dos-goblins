extends SceneTree
## Regressao: aproximacao nao ultrapassa o alvo e recuo nao inverte o focinho.

func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	var game := load("res://main.gd").new() as Node3D
	var wolf := CharacterBody3D.new()
	root.add_child(wolf)
	var aligned: bool = game.call("wolf_attack_heading",wolf,Vector3.FORWARD,.1)
	if not aligned:
		_fail(game,wolf,"Lobo nao reconhece alvo a frente.")
		return
	var stride: Vector3 = game.call("wolf_combat_stride",wolf,Vector3.FORWARD*1.30,1.30,.1,true)
	if stride.length()*.1>.021 or stride.z>=0:
		_fail(game,wolf,"Ultimo passo ultrapassa distancia de ataque.")
		return
	stride = game.call("wolf_combat_stride",wolf,Vector3.FORWARD*1.28,1.28,.1,true)
	if stride.length()>.001:
		_fail(game,wolf,"Lobo continua andando na distancia de mordida.")
		return
	var facing := wolf.rotation.y
	stride = game.call("wolf_combat_stride",wolf,Vector3.FORWARD*.70,.70,.1,true)
	if stride.z<=0 or not is_equal_approx(wolf.rotation.y,facing):
		_fail(game,wolf,"Recuo nao preserva a orientacao.")
		return
	wolf.set_meta("wolf_bite_hold_until",1000000.0)
	stride = game.call("wolf_combat_stride",wolf,Vector3.FORWARD*2,2.0,.1,true)
	if stride.length()>.001:
		_fail(game,wolf,"Lobo avanca durante a mordida.")
		return
	wolf.rotation.y = 0.0
	aligned = bool(game.call("wolf_attack_heading",wolf,Vector3.BACK,.1,true))
	if not aligned:
		_fail(game,wolf,"Guardiao nao reconhece a frente +Z.")
		return
	stride = game.call("wolf_combat_stride",wolf,Vector3.BACK*.95,.95,.1,true,true)
	if stride.length()>.001:
		_fail(game,wolf,"Guardiao avanca alem da distancia de ataque.")
		return
	stride = game.call("wolf_combat_stride",wolf,Vector3.BACK*.5,.5,.1,true,true)
	if stride.z>=0 or absf(wolf.rotation.y)>.001:
		_fail(game,wolf,"Guardiao nao recua mantendo o olhar.")
		return
	wolf.set_meta("guardian_attack_hold_until",1000000.0)
	stride = game.call("wolf_combat_stride",wolf,Vector3.BACK*2,2.0,.1,true,true)
	if stride.length()>.001:
		_fail(game,wolf,"Guardiao avanca durante ataque.")
		return
	game.free()
	wolf.free()
	print("WOLF COMBAT OK")
	quit(0)

func _fail(game: Node3D,wolf: Node3D,message: String) -> void:
	printerr(message)
	game.free()
	wolf.free()
	quit(1)
