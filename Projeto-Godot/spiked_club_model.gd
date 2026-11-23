extends RefCounted
## Porrete de espinhos artesanal: tronco macico, cabo e presas de lobo.
## Eixo Y: cabo embaixo, cabeca de impacto em cima.

static func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.91
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

static func _tube(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material, sides: int = 10) -> void:
	var d: Vector3 = b-a
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius * 1.08
	m.height = d.length()
	m.radial_segments = sides
	var item := MeshInstance3D.new()
	item.mesh = m
	item.material_override = mat
	item.position = (a+b)*0.5
	item.quaternion = Quaternion(Vector3.UP,d.normalized())
	parent.add_child(item)

static func _sphere(parent: Node3D, pos: Vector3, scale_value: Vector3, mat: Material) -> void:
	var shape := SphereMesh.new()
	shape.radial_segments = 12
	shape.rings = 7
	var item := MeshInstance3D.new()
	item.mesh = shape
	item.position = pos
	item.scale = scale_value
	item.material_override = mat
	parent.add_child(item)

static func _fang(parent: Node3D, start: Vector3, direction: Vector3, size: float, mat: Material) -> void:
	var axis: Vector3 = direction.normalized()
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = size*0.25
	m.height = size
	m.radial_segments = 7
	var item := MeshInstance3D.new()
	item.mesh = m
	item.material_override = mat
	item.position = start+axis*size*0.5
	item.quaternion = Quaternion(Vector3.UP,axis)
	parent.add_child(item)
	_sphere(parent,start,Vector3.ONE*size*0.20,mat)

static func build(parent: Node3D) -> void:
	var bark := _mat(Color("#74452a"))
	var grain := _mat(Color("#a2764b"))
	var dark := _mat(Color("#46291b"))
	var cord := _mat(Color("#d5b77a"))
	# Marfim fosco com raiz escurecida: distingue os dentes da casca do tronco.
	var fang := _mat(Color("#ded0a9"))
	fang.roughness = 0.68
	var fang_tip := _mat(Color("#f5e9ce"))
	fang_tip.roughness = 0.55
	var fang_root := _mat(Color("#887257"))
	# Cabo afunilado e tronco pesado, diferentes de uma espada.
	_tube(parent,Vector3(0,-0.54,0),Vector3(0,0.08,0),0.051,bark,12)
	_tube(parent,Vector3(0,0.07,0),Vector3(0,0.62,0),0.158,bark,12)
	_sphere(parent,Vector3(0,0.62,0),Vector3(0.162,0.080,0.162),grain)
	_sphere(parent,Vector3(0,0.07,0),Vector3(0.158,0.070,0.158),dark)
	_sphere(parent,Vector3(0,-0.54,0),Vector3(0.065,0.066,0.065),dark)
	# Fibras longitudinais e irregularidades do tronco.
	for side in range(8):
		var theta: float = TAU*float(side)/8.0
		var x: float = cos(theta)
		var z: float = sin(theta)
		_tube(parent,Vector3(x*0.160,0.13,z*0.160),
			Vector3(x*0.163,0.53,z*0.163),0.006,grain,6)
		_tube(parent,Vector3(x*0.153,0.30,z*0.153),
			Vector3(x*0.158,0.40,z*0.158),0.003,dark,6)
	# Dentes pontudos nas faces externas; diversos angulos, sem sobrepor o cabo.
	for row in range(3):
		var y: float = 0.17+float(row)*0.165
		for col in range(6):
			var angle: float = TAU*(float(col)+float(row)*0.5)/6.0
			var outward := Vector3(cos(angle),0.23,sin(angle)).normalized()
			var base := Vector3(cos(angle)*0.151,y,sin(angle)*0.151)
			# Encaixe da presa na madeira, sem espinhos brancos flutuantes.
			_sphere(parent,base,Vector3.ONE*0.028,fang_root)
			_fang(parent,base,outward,0.125 if row==1 else 0.105,fang)
			_fang(parent,base+outward*0.055,outward,0.065,fang_tip)
	# Duas ligaduras nos extremos do tronco e uma no punho.
	for ring in [0.11,0.145,0.555,0.585]:
		for i in range(12):
			var a: float = TAU*float(i)/12.0
			var b: float = TAU*float(i+1)/12.0
			_tube(parent,Vector3(cos(a)*0.164,ring,sin(a)*0.164),
				Vector3(cos(b)*0.164,ring+0.002,sin(b)*0.164),0.013,cord,7)
	for ring in [-0.42,-0.39,-0.36]:
		for i in range(10):
			var a: float = TAU*float(i)/10.0
			var b: float = TAU*float(i+1)/10.0
			_tube(parent,Vector3(cos(a)*0.054,ring,sin(a)*0.054),
				Vector3(cos(b)*0.054,ring,sin(b)*0.054),0.008,cord,6)
