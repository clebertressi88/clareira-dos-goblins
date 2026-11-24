extends RefCounted
## Distribuicao deterministica de biomas: a mesma semente espacial resulta
## no mesmo bioma, independente de quem carregou o chunk ou do save.
const DENSE_REGION_SIZE := 96.0

static func dense_forest(x: float, z: float) -> bool:
	# Blocos de paisagem amplos; cerca de um terco vira mata fechada.
	# A clareira inicial permanece livre e facil para construir.
	if Vector2(x,z).length()<42.0:
		return false
	var region := Vector2i(floori(x/DENSE_REGION_SIZE),floori(z/DENSE_REGION_SIZE))
	return posmod(hash("dense-biome-%d:%d" % [region.x,region.y]),3)==0

static func trail_distance(x: float, z: float) -> float:
	# Caminhos sinuosos, paralelos a direcao norte-sul; nao sao rios.
	# Corredores sem arvores e sem capim alto conectam bordas dos chunks.
	var center := 16.0*sin(z*.017+sin(z*.006)*1.2)+5.0*sin(z*.043)
	var lane := fposmod(x-center+48.0,48.0)-24.0
	return absf(lane)

static func is_trail(x: float, z: float) -> bool:
	return dense_forest(x,z) and trail_distance(x,z)<2.0

static func foliage_multiplier(x: float, z: float) -> float:
	if not dense_forest(x,z):
		return 1.0
	if trail_distance(x,z)<3.5:
		return 0.0
	return 2.2
