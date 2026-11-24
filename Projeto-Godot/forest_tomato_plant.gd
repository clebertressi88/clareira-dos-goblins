extends RefCounted
## Tomateiro rasteiro: folhagem composta, ramos curvos e frutos 3D texturizados.
## Todos os detalhes sao gerados localmente, sem arquivos binarios externos.
const WOOD := preload("res://forest_wood_geometry.gd")
static var leaf_material: StandardMaterial3D
static var green_material: StandardMaterial3D
static var ripe_material: StandardMaterial3D
static var calyx_material: StandardMaterial3D
static var stem_material: StandardMaterial3D

static func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.86
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

static func _leaf_material() -> StandardMaterial3D:
	if leaf_material != null:
		return leaf_material
	leaf_material = _material(Color.WHITE)
	var img := Image.create(64,64,false,Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var u := float(x)/63.0
			var v := float(y)/63.0
			var rib: float = absf(u-0.5)
			var veins := 0.13 if rib<0.038 or abs(v-(0.22+rib*0.92))<0.025 or abs(v-(0.78-rib*0.92))<0.025 else 0.0
			var noise := sin(u*53.0+v*17.0)*sin(v*79.0-u*19.0)*0.075
			var shade := 0.88+veins+noise
			img.set_pixel(x,y,Color(0.30*shade,0.47*shade,0.22*shade,1.0))
	leaf_material.albedo_texture = ImageTexture.create_from_image(img)
	leaf_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return leaf_material

static func _fruit_material(ripe: bool) -> StandardMaterial3D:
	if ripe and ripe_material != null:
		return ripe_material
	if not ripe and green_material != null:
		return green_material
	var mat := _material(Color.WHITE)
	var img := Image.create(64,64,false,Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var u := float(x)/63.0
			var v := float(y)/63.0
			var grain := 0.96+0.035*sin(u*71.0+v*21.0)*sin(v*83.0-u*15.0)
			var gradient := 0.90+0.10*v
			var c := Color(0.81,0.105,0.058) if ripe else Color(0.37,0.56,0.19)
			img.set_pixel(x,y,Color(c.r*grain*gradient,c.g*grain*gradient,c.b*grain*gradient,1.0))
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if ripe:
		ripe_material = mat
	else:
		green_material = mat
	return mat

static func _leaf(parent: Node3D, center: Vector3, direction: Vector3, size: float) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.085
	mesh.height = 0.17
	mesh.radial_segments = 7
	mesh.rings = 4
	var leaf := MeshInstance3D.new()
	leaf.name = "FolhaSerrilhada"
	leaf.mesh = mesh
	leaf.material_override = _leaf_material()
	leaf.position = center
	leaf.quaternion = Quaternion(Vector3.UP,direction.normalized())
	leaf.scale = Vector3(0.72,size/0.17,0.17)
	parent.add_child(leaf)

static func _fruit(parent: Node3D, pos: Vector3, ripe: bool, radius: float) -> void:
	var cluster := Node3D.new()
	cluster.name = "Fruto_%d" % parent.get_child_count()
	parent.add_child(cluster)
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = 2.0*radius*0.93
	sphere.radial_segments = 12
	sphere.rings = 8
	var tomato := MeshInstance3D.new()
	tomato.name = "TomateMaduro" if ripe else "TomateVerde"
	tomato.mesh = sphere
	tomato.material_override = _fruit_material(ripe)
	tomato.position = pos
	cluster.add_child(tomato)
	# Sepalas finas em estrela no topo do tomate.
	for j in range(5):
		var angle := TAU*float(j)/5.0
		var blade := MeshInstance3D.new()
		var leaf_mesh := SphereMesh.new()
		leaf_mesh.radius = 0.023
		leaf_mesh.height = 0.065
		leaf_mesh.radial_segments = 5
		leaf_mesh.rings = 2
		blade.mesh = leaf_mesh
		blade.material_override = calyx_material
		blade.position = pos+Vector3(cos(angle)*radius*0.50,radius*0.87,sin(angle)*radius*0.50)
		blade.quaternion = Quaternion(Vector3.UP,Vector3(cos(angle),0.18,sin(angle)).normalized())
		blade.scale = Vector3(0.50,1.0,0.20)
		cluster.add_child(blade)

## Atualiza apenas a malha do fruto: verde imaturo, vermelho pronto.
## Materiais compartilhados evitam criar novas texturas a cada atualizacao.
static func set_fruit_ripe(cluster: Node3D, ripe: bool) -> void:
	for part in cluster.get_children():
		if part is MeshInstance3D and str(part.name) in ["TomateMaduro","TomateVerde"]:
			part.name = "TomateMaduro" if ripe else "TomateVerde"
			part.material_override = _fruit_material(ripe)
			break

static func build(parent: Node3D, seed: String, harvested_item: bool = false) -> void:
	if stem_material == null:
		stem_material = _material(Color("#496e34"))
	if calyx_material == null:
		calyx_material = _material(Color("#284f29"))
	if harvested_item:
		_fruit(parent,Vector3(0,0.115,0),true,0.115)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(seed+"-tomateiro"))
	var root_pos := Vector3(0,0.075,0)
	for i in range(5):
		var angle := TAU*float(i)/5.0+rng.randf_range(-0.28,0.28)
		var direction := Vector3(cos(angle),0,sin(angle))
		var near := root_pos+direction*0.20+Vector3.UP*rng.randf_range(0.06,0.13)
		var far := root_pos+direction*rng.randf_range(0.38,0.53)+Vector3.UP*rng.randf_range(0.10,0.21)
		WOOD.tapered(parent,root_pos,near,0.024,0.017,stem_material,6)
		WOOD.tapered(parent,near,far,0.017,0.007,stem_material,6)
		for j in range(3):
			var t := 0.30+float(j)*0.25
			var origin := near.lerp(far,t)
			var side := -1.0 if j%2==0 else 1.0
			var tip := origin+direction*0.035+Vector3(-direction.z,0,direction.x)*side*rng.randf_range(0.13,0.20)+Vector3.UP*0.06
			WOOD.tapered(parent,origin,tip,0.007,0.002,stem_material,5)
			# Folha de tomate composta: lamina central e dois foliolos laterais.
			_leaf(parent,tip,(tip-origin).normalized(),rng.randf_range(0.15,0.23))
			for k in [-1.0,1.0]:
				var leaf_pos: Vector3 = tip+Vector3(-direction.z,0,direction.x)*float(k)*0.056
				_leaf(parent,leaf_pos,Vector3(direction.x+k*0.44,0.20,direction.z-k*0.44),0.115)
		if i<4:
			var fruit_base := far+Vector3(0,-0.055,0)
			_fruit(parent,fruit_base,false,rng.randf_range(0.068,0.096))
