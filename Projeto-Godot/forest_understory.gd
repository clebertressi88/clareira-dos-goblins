extends RefCounted
## Vegetacao de floresta por chunk: desenho em lotes MultiMesh, sem colisores.
## Mudas interativas separadas; plantas decorativas nao entram em saves nem em RPCs.
const TERRAIN := preload("res://landscape_terrain.gd")
const BIOMES := preload("res://forest_biomes.gd")
const WOOD := preload("res://forest_wood_geometry.gd")
static var meshes: Dictionary = {}
static var mats: Dictionary = {}

static func _mat(color: Color, double_sided: bool = true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	if double_sided:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

static func _quad(width: float, height: float, tip: float = 0.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(-width*0.5,0,0)
	var b := Vector3(width*0.5,0,0)
	var c := Vector3(-width*0.20,height,tip)
	var d := Vector3(width*0.20,height,tip)
	for vertex in [a,b,c,b,d,c]:
		st.set_uv(Vector2(vertex.x/width+0.5,vertex.y/height))
		st.add_vertex(vertex)
	st.generate_normals()
	return st.commit()

## Um unico mesh de tufo com folhas cruzadas e inclinadas, renderizado
## por MultiMesh. Evita as antigas pontas isoladas tipo estacas.
static func _tuft(blades: int, max_height: float, width: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(blades):
		var angle := TAU*float(i)/float(blades)+0.21*sin(float(i)*2.7)
		var radial := Vector3(cos(angle),0.0,sin(angle))
		var across := Vector3(-radial.z,0.0,radial.x)
		var length := max_height*(0.64+0.36*absf(sin(float(i)*1.7+0.8)))
		var root := radial*(0.012+float(i%3)*0.010)
		var mid := root+radial*(length*0.24)+Vector3.UP*(length*0.53)
		var tip := root+radial*(length*0.63)+Vector3.UP*length
		var base_left := root-across*width*0.5
		var base_right := root+across*width*0.5
		var mid_left := mid-across*width*0.32
		var mid_right := mid+across*width*0.32
		# Duas secoes curvadas, terminacao estreita (nao triangulo rigido).
		for point in [base_left,base_right,mid_left,base_right,mid_right,mid_left,mid_left,mid_right,tip]:
			st.add_vertex(point)
	st.generate_normals()
	return st.commit()

static func _flat_leaf() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(-0.15,0.008,-0.045)
	var b := Vector3(0.14,0.008,-0.045)
	var c := Vector3(-0.06,0.015,0.075)
	var d := Vector3(0.08,0.015,0.07)
	for vertex in [a,b,c,b,d,c]:
		st.set_uv(Vector2(vertex.x+0.5,vertex.z+0.5))
		st.add_vertex(vertex)
	st.generate_normals()
	return st.commit()

static func _mesh(name: String) -> Mesh:
	if meshes.has(name):
		return meshes[name]
	var result: Mesh
	match name:
		"grass": result = _tuft(7,0.20,0.032)
		"moss": result = _flat_leaf()
		"leaf": result = _flat_leaf()
		"pebble":
			var sphere := SphereMesh.new()
			sphere.radius = 0.11
			sphere.height = 0.12
			sphere.radial_segments = 7
			sphere.rings = 3
			result = sphere
		"reeds": result = _tuft(5,0.58,0.025)
		"aquatic": result = _tuft(5,0.30,0.055)
		_: result = _quad(0.10,0.20)
	meshes[name] = result
	return result

static func _material(name: String) -> Material:
	if mats.has(name):
		return mats[name]
	var color := Color("#698a45")
	match name:
		"grass": color = Color("#668247")
		"moss": color = Color("#4e723c")
		"leaf": color = Color("#947446")
		"pebble": color = Color("#777a6a")
		"reeds": color = Color("#8c9851")
		"aquatic": color = Color("#3e7f60")
	var m := _mat(color)
	mats[name] = m
	return m

static func populate_chunk(chunk: Node3D, key: Vector2i, avoid: Array = []) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash("understory-v1-%d-%d" % [key.x,key.y]))
	var data := {"grass":[],"moss":[],"leaf":[],"pebble":[],"reeds":[],"aquatic":[]}
	# Baixa densidade fixa por chunk; nenhum Node3D por folha ou pedra.
	var dense := BIOMES.dense_forest(float(key.x*16+8),float(key.y*16+8))
	for i in range(210 if dense else 116):
		var x := float(key.x*16)+rng.randf_range(.3,15.7)
		var z := float(key.y*16)+rng.randf_range(.3,15.7)
		var pos := Vector3(x,TERRAIN.height_at(x,z),z)
		if BIOMES.is_trail(x,z):
			continue
		if Vector2(x,z).length()<7.0 or Vector2(x+0.0,z+6.0).length()<5.5:
			continue
		var blocked := false
		for p in avoid:
			if p is Vector3 and Vector2(x-p.x,z-p.z).length()<1.2:
				blocked = true
				break
		if blocked:
			continue
		var river_distance := absf(x-TERRAIN.river_x(z))
		var near_bank := river_distance>TERRAIN.RIVER_HALF_WIDTH and river_distance<TERRAIN.RIVER_HALF_WIDTH+3.7
		var submerged := river_distance<TERRAIN.RIVER_HALF_WIDTH
		var kind := "grass"
		if submerged:
			kind = "aquatic" if i%3==0 else "reeds"
			if pos.y > TERRAIN.WATER_LEVEL+0.05:
				continue
		elif near_bank:
			kind = "reeds" if i%4!=0 else "moss"
		else:
			match i%13:
				0,1,2: kind = "moss"
				3,4: kind = "leaf"
				5: kind = "pebble"
				_: kind = "grass"
		var scale := rng.randf_range(.66,1.1) if kind=="grass" else rng.randf_range(.75,1.2)
		var basis := Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3(scale,scale,scale))
		pos.y += 0.018 if kind in ["moss","leaf","pebble"] else 0.0
		data[kind].append(Transform3D(basis,pos))
	for kind in data.keys():
		var transforms: Array = data[kind]
		if transforms.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _mesh(kind)
		mm.instance_count = transforms.size()
		for i in range(transforms.size()):
			mm.set_instance_transform(i,transforms[i])
		var mi := MultiMeshInstance3D.new()
		mi.name = "Cobertura_" + kind
		mi.multimesh = mm
		mi.material_override = _material(kind)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		chunk.add_child(mi)

static func _stem(parent: Node3D, from: Vector3, to: Vector3, radius: float, m: Material) -> void:
	WOOD.tapered(parent,from,to,radius,radius*0.35,m,5)

static func build_plant(parent: Node3D, kind: String, seed: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(seed))
	var green := _mat(Color("#476d3c"))
	var leaf := _mat(Color("#4e803f"))
	var leaf_alt := _mat(Color("#789950"))
	var bark := _mat(Color("#72563b"))
	var tall := kind=="river_reed"
	# Raizes expostas nas margens, curtas e contidas para nao atrapalhar trilhas.
	if tall:
		for root_index in range(4):
			var root_angle := TAU*float(root_index)/4.0+rng.randf_range(-.16,.16)
			var root_dir := Vector3(cos(root_angle),0,sin(root_angle))
			_stem(parent,Vector3.UP*.12,root_dir*rng.randf_range(.16,.28)+Vector3.UP*.012,.033,bark)
	var count := 7 if tall else 6 if kind=="fern" else 8
	for i in range(count):
		var angle := TAU*float(i)/float(count)+rng.randf_range(-.20,.20)
		var direction := Vector3(cos(angle),0,sin(angle))
		if tall:
			var h := rng.randf_range(.55,1.15)
			var tip := direction*rng.randf_range(.09,.25)+Vector3.UP*h
			_stem(parent,Vector3.UP*.04,tip,.013,green)
			var blade := MeshInstance3D.new()
			blade.mesh = _mesh("reeds")
			blade.material_override = leaf_alt if i%2==0 else leaf
			blade.position = direction*.10+Vector3.UP*.1
			blade.rotation.y = angle
			blade.scale = Vector3(1.2,1.3,1.2)
			parent.add_child(blade)
		else:
			var length := rng.randf_range(.27,.58) if kind=="fern" else rng.randf_range(.25,.45)
			var end := direction*length+Vector3.UP*rng.randf_range(.16,.42)
			_stem(parent,Vector3.UP*.06,end,.016 if kind=="fern" else .024,green if kind=="fern" else bark)
			for j in range(4 if kind=="fern" else 3):
				var t := (float(j)+1.0)/5.0
				var p := Vector3.UP*.06+(end-Vector3.UP*.06)*t
				for side in [-1.0,1.0]:
					var blade := MeshInstance3D.new()
					blade.mesh = _mesh("leaf")
					blade.material_override = leaf if (i+j)%2==0 else leaf_alt
					blade.position = p+Vector3(-direction.z,0,direction.x)*side*.07
					blade.rotation.y = angle+side*.6
					blade.scale = Vector3(.82,1.0,.95)
					parent.add_child(blade)
	if kind=="forest_shrub":
		for i in range(3):
			var cap := MeshInstance3D.new()
			var mesh := SphereMesh.new()
			mesh.radius = .21
			mesh.height = .27
			mesh.radial_segments = 7
			mesh.rings = 3
			cap.mesh = mesh
			cap.material_override = leaf if i%2==0 else leaf_alt
			cap.position = Vector3(cos(float(i)*TAU/3.0)*.18,.27,sin(float(i)*TAU/3.0)*.18)
			parent.add_child(cap)
