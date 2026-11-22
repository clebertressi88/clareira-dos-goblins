extends RefCounted
## Copas organicas de baixo custo. Apenas visual: a colisao permanece no tronco.
## A semente vem do ID persistente da arvore; cliente e servidor veem o mesmo formato.

static func decorate(growth: Node3D, bark: Material, tree_id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(tree_id))
	var variation := rng.randi_range(0, 3)
	var green_colors := [
		Color("#345c32"), Color("#426e39"), Color("#527d43"),
		Color("#60834a"), Color("#728d50")
	]
	var foliage_materials: Array[StandardMaterial3D] = []
	for col in green_colors:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.roughness = 1.0
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		foliage_materials.append(mat)
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radius = 0.5
	leaf_mesh.height = 1.0
	leaf_mesh.radial_segments = 8
	leaf_mesh.rings = 4
	# Galhos saem do tronco e apontam para a copa; nao possuem colisao.
	for i in range(5):
		var angle := TAU * (float(i) / 5.0) + rng.randf_range(-0.21, 0.21)
		var height := 1.48 + float(i % 3) * 0.31
		var radius := 0.85 + rng.randf_range(-0.13, 0.23)
		var start := Vector3(cos(angle) * 0.12, height, sin(angle) * 0.12)
		var tip := Vector3(cos(angle) * radius, height + 0.50, sin(angle) * radius)
		_add_branch(growth, start, tip, bark)
	# Grandes tufos em alturas e larguras alternadas, evitando a forma de bola unica.
	var crown_height := 2.34 + float(variation) * 0.10
	for i in range(9):
		var angle := TAU * (float(i) / 9.0) + rng.randf_range(-0.25, 0.25)
		var ring := 0.43 if i >= 6 else 0.76
		var lateral := ring + rng.randf_range(-0.14, 0.14)
		var y := crown_height + (float(i % 3) - 1.0) * 0.27 + rng.randf_range(-0.13, 0.13)
		var pos := Vector3(cos(angle) * lateral, y, sin(angle) * lateral)
		var width := rng.randf_range(0.96, 1.33)
		var depth := rng.randf_range(0.90, 1.24)
		_add_leaf(growth, leaf_mesh, pos, Vector3(width, rng.randf_range(0.85, 1.20), depth), foliage_materials[(i + variation) % foliage_materials.size()])
	# Topo estreito para dar uma silhueta de arvore em vez de um bloco arredondado.
	_add_leaf(growth, leaf_mesh, Vector3(0.0, 3.02 + float(variation) * 0.10, 0.0), Vector3(1.08, 1.02, 1.08), foliage_materials[(variation + 2) % foliage_materials.size()])

static func _add_branch(parent: Node3D, start: Vector3, tip: Vector3, bark: Material) -> void:
	var delta := tip - start
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = 0.09
	mesh.top_radius = 0.035
	mesh.height = delta.length()
	mesh.radial_segments = 6
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = bark
	part.position = (start + tip) * 0.5
	part.quaternion = Quaternion(Vector3.UP, delta.normalized())
	parent.add_child(part)

static func _add_leaf(parent: Node3D, mesh: Mesh, pos: Vector3, dimensions: Vector3, mat: Material) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = mat
	part.position = pos
	part.scale = dimensions
	parent.add_child(part)
