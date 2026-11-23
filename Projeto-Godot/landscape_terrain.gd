extends RefCounted
## Funcoes deterministicas do relevo: sem estado, ruido e alocacoes por frame.
## A mesma altura e usada para malha, colisao, recursos e movimentacao.

const WATER_LEVEL := -1.05
const RIVER_HALF_WIDTH := 4.8

static func river_x(z: float) -> float:
	# Rio principal no vale a leste da clareira inicial.
	return 34.0 + sin(z * 0.034) * 7.0 + sin(z * 0.079) * 2.3

static func height_at(x: float, z: float) -> float:
	var distance := Vector2(x, z).length()
	# Mantem a area central jogavel e o acampamento existente.
	var original := (sin(x * .12) * 1.2 + cos(z * .14) * .87 + sin((x + z) * .22) * .52) * smoothstep(16.0, 38.0, distance)
	var mountain_fade := smoothstep(30.0, 100.0, distance)
	var crest := pow(absf(sin(x * .019 + cos(z * .014) * .8)), 2.0)
	var peaks := crest * (8.0 + 5.0 * absf(cos(z * .023))) * mountain_fade
	var undulation := (sin(x * .055 + sin(z * .027)) * .8 + cos(z * .067) * .7) * mountain_fade
	var terrain := original + peaks + undulation

	# Escava uma calha real, com margens elevadas e leito abaixo da agua.
	var river_distance := absf(x - river_x(z))
	var valley := lerpf(-.38, terrain, smoothstep(8.0, 22.0, river_distance))
	var river_bed := 4.25 * (1.0 - smoothstep(2.2, 5.9, river_distance))
	return valley - river_bed

static func is_river(x: float, z: float) -> bool:
	return absf(x - river_x(z)) <= RIVER_HALF_WIDTH
