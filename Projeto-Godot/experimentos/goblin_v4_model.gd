extends "res://experimentos/goblin_v3_model.gd"
## Goblin V4 - nova anatomia e escultura organica a partir da referencia.
## Mantem os mesmos 16 ossos V3 e a mesma interface de animacao.
## A geometria e criada nova; nao deforma a malha GLB antiga.
const SCULPT = preload("res://experimentos/goblin_v4_body.gd")
# Altura do chifre (2.233) ajustada para 1,25 m na cena de jogo.
const GAME_HEIGHT_METERS := 1.25
const ORIGINAL_HEIGHT := 2.233
const GAME_SCALE := GAME_HEIGHT_METERS / ORIGINAL_HEIGHT

func _construct_visuals() -> void:
	SCULPT.sculpt(self)

func install() -> bool:
	var ok := super.install()
	if ok:
		scale = Vector3.ONE * GAME_SCALE
		set_meta("altura_jogo_m", GAME_HEIGHT_METERS)
		set_meta("modelo_goblin_v4",true)
	return ok
