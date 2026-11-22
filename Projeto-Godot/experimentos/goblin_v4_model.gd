extends "res://experimentos/goblin_v3_model.gd"
## Goblin V4 - nova anatomia e escultura organica a partir da referencia.
## Mantem os mesmos 16 ossos V3 e a mesma interface de animacao.
## A geometria e criada nova; nao deforma a malha GLB antiga.
const SCULPT = preload("res://experimentos/goblin_v4_body.gd")

func _construct_visuals() -> void:
	SCULPT.sculpt(self)

func install() -> bool:
	var ok := super.install()
	if ok:
		set_meta("modelo_goblin_v4",true)
	return ok
