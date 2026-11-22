extends RefCounted
## Folhagem 3D com folhas realmente visiveis, sem bolas de SphereMesh.
## Cartoes de folhas recortadas e cruzadas, semente estavel por arvore.
static var shared_leaf_material: StandardMaterial3D
static var shared_leaf_mesh: QuadMesh
const WOOD := preload("res://forest_wood_geometry.gd")

static func _leaf_material() -> StandardMaterial3D:
	if shared_leaf_material != null:
		return shared_leaf_material
	shared_leaf_material = StandardMaterial3D.new()
	shared_leaf_material.albedo_color = Color.WHITE
	shared_leaf_material.albedo_texture = preload("res://forest_leaf_pattern.gd").make_texture()
	shared_leaf_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	shared_leaf_material.alpha_scissor_threshold = 0.45
	shared_leaf_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	shared_leaf_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	shared_leaf_material.roughness = 1.0
	shared_leaf_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return shared_leaf_material

static func _leaf_mesh() -> QuadMesh:
	if shared_leaf_mesh == null:
		shared_leaf_mesh = QuadMesh.new()
		shared_leaf_mesh.size = Vector2(1.0,1.0)
	return shared_leaf_mesh

static func decorate(growth: Node3D, bark: Material, tree_id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(tree_id))
	var variation := rng.randf_range(-0.16,0.20)
	# Galhos visiveis mas sem colisao: apenas o tronco bloqueia passagem.
	for i in range(7):
		var angle := TAU*float(i)/7.0+rng.randf_range(-0.24,0.24)
		var height := rng.randf_range(1.45,2.24)
		var radius := rng.randf_range(0.65,1.02)
		var start := Vector3(cos(angle)*0.055,height,sin(angle)*0.055)
		var tip := Vector3(cos(angle)*radius,height+rng.randf_range(0.24,0.55),sin(angle)*radius)
		WOOD.make_branch(growth,start,tip,rng.randf_range(0.078,0.117),bark)

	# Copas compostas de ramos e folhas pequenas em varias profundidades.
	# Duas cartas cruzadas em cada volume deixam as folhas visiveis de todos os lados.
	for i in range(37):
		var angle := rng.randf_range(0.0,TAU)
		var radial := sqrt(rng.randf())*1.17
		var height := rng.randf_range(1.91,2.93)+variation
		var taper := clampf((3.22-height)/1.25,0.24,1.0)
		var pos := Vector3(cos(angle)*radial*taper,height,sin(angle)*radial*taper)
		var scale_size := rng.randf_range(0.62,0.98)
		_add_leaf_cluster(growth,pos,scale_size,rng.randf_range(0.0,TAU),rng)
	# Silhueta de folhas no topo, em vez de um unico poligono arredondado.
	for i in range(6):
		var angle := float(i)*TAU/6.0
		_add_leaf_cluster(growth,Vector3(cos(angle)*0.24,3.04+variation,sin(angle)*0.24),0.59,angle,rng)

static func _add_leaf_cluster(parent: Node3D, pos: Vector3, extent: float, yaw: float, rng: RandomNumberGenerator) -> void:
	var leaf_material := _leaf_material()
	var leaf_mesh := _leaf_mesh()
	for side in range(2):
		var part := MeshInstance3D.new()
		part.mesh = leaf_mesh
		part.material_override = leaf_material
		part.position = pos
		part.rotation = Vector3(rng.randf_range(-0.26,0.26),yaw+float(side)*PI*0.5,rng.randf_range(-0.15,0.15))
		part.scale = Vector3(extent*1.45,extent*1.25,1.0)
		parent.add_child(part)
