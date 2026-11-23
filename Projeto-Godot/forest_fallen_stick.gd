extends RefCounted
## Graveto caido: casca fotografica, silhueta irregular, nos e pontas lascadas.
const WOOD := preload("res://forest_wood_geometry.gd")
const BARK := preload("res://tree_bark_texture.gd")
static var bark_material: StandardMaterial3D
static var core_material: StandardMaterial3D
static var moss_material: StandardMaterial3D

static func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.97
	return m

static func _bark() -> StandardMaterial3D:
	if bark_material == null:
		bark_material = _mat(Color("#a18a6c"))
		bark_material.albedo_texture = BARK.make_texture()
		bark_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return bark_material

static func build(parent: Node3D, id: String) -> void:
	if core_material == null:
		core_material = _mat(Color("#b99867"))
	if moss_material == null:
		moss_material = _mat(Color("#586e38"))
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(id+"-graveto-realista"))
	var a := Vector3(-0.31,0.064,-0.035)
	var b := Vector3(-0.13,0.087,0.025)
	var c := Vector3(0.10,0.074,0.037)
	var d := Vector3(0.31,0.057,-0.015)
	WOOD.tapered(parent,a,b,0.052,0.050,_bark(),10)
	WOOD.tapered(parent,b-Vector3(0.008,0,0),c,0.051,0.040,_bark(),10)
	WOOD.tapered(parent,c-Vector3(0.008,0,0),d,0.041,0.028,_bark(),10)
	var branch_root := Vector3(-0.045,0.101,0.035)
	WOOD.tapered(parent,branch_root,branch_root+Vector3(0.041,0.099,-0.033),0.030,0.006,_bark(),8)
	for i in range(4):
		var angle := TAU*float(i)/4.0
		var offset := Vector3(0,cos(angle)*0.017,sin(angle)*0.017)
		WOOD.tapered(parent,a+offset,a+offset*0.65-Vector3(rng.randf_range(0.026,0.065),0,0),0.009,0.001,core_material,5)
		WOOD.tapered(parent,d+offset,d+offset*0.5+Vector3(rng.randf_range(0.025,0.055),0,0),0.007,0.001,core_material,5)
	for i in range(3):
		var knot := MeshInstance3D.new()
		var km := SphereMesh.new()
		km.radius = rng.randf_range(0.013,0.022)
		km.height = 0.035
		km.radial_segments = 7
		km.rings = 3
		knot.mesh = km
		knot.material_override = _bark()
		knot.position = Vector3(rng.randf_range(-0.22,0.20),rng.randf_range(0.100,0.124),rng.randf_range(-0.025,0.052))
		knot.scale = Vector3(1.3,0.5,0.9)
		parent.add_child(knot)
	for i in range(4):
		var patch := MeshInstance3D.new()
		var pm := SphereMesh.new()
		pm.radius = rng.randf_range(0.011,0.021)
		pm.height = 0.026
		pm.radial_segments = 6
		pm.rings = 2
		patch.mesh = pm
		patch.material_override = moss_material
		patch.position = Vector3(rng.randf_range(-0.23,0.23),rng.randf_range(0.110,0.131),rng.randf_range(-0.015,0.032))
		patch.scale = Vector3(1.5,0.25,0.7)
		parent.add_child(patch)
