extends RefCounted
## Pele pequena de coelho estendida e adaptada ao relevo, nao volumosa ou flutuante.
## Recebe a funcao ground(x,z) para apoiar cada vertice diretamente no terreno.

const PELT_SCALE := 0.48
const OUTLINE := [
	Vector2(-0.13,-0.53),Vector2(-0.27,-0.48),Vector2(-0.36,-0.35),
	Vector2(-0.53,-0.31),Vector2(-0.57,-0.18),Vector2(-0.43,-0.10),
	Vector2(-0.41,0.08),Vector2(-0.54,0.25),Vector2(-0.49,0.40),
	Vector2(-0.29,0.34),Vector2(-0.22,0.52),Vector2(0.0,0.46),
	Vector2(0.22,0.52),Vector2(0.29,0.34),Vector2(0.49,0.40),
	Vector2(0.54,0.25),Vector2(0.41,0.08),Vector2(0.43,-0.10),
	Vector2(0.57,-0.18),Vector2(0.53,-0.31),Vector2(0.36,-0.35),
	Vector2(0.27,-0.48),Vector2(0.13,-0.53)
]

func _point(parent: Node3D, p: Vector2, height_at: Callable, surface_offset: float) -> Vector3:
	var local := Vector3(p.x * PELT_SCALE,0.0,p.y * PELT_SCALE)
	if height_at.is_valid():
		var world: Vector3 = parent.to_global(local)
		var ground_y: float = float(height_at.call(world.x,world.z))
		local.y = parent.to_local(Vector3(world.x,ground_y+surface_offset,world.z)).y
	else:
		local.y = surface_offset
	return local

func _tri(surface: SurfaceTool, parent: Node3D, height_at: Callable,
		a: Vector2, b: Vector2, c: Vector2, ca: Color, cb: Color, cc: Color,
		surface_offset: float = 0.016) -> void:
	surface.set_color(ca)
	surface.add_vertex(_point(parent,a,height_at,surface_offset))
	surface.set_color(cb)
	surface.add_vertex(_point(parent,b,height_at,surface_offset))
	surface.set_color(cc)
	surface.add_vertex(_point(parent,c,height_at,surface_offset))

func build(parent: Node3D, height_at: Callable = Callable()) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector2.ZERO
	# Contorno de quatro patas e corpo estreito, com borda de pelagem clara.
	for i in range(OUTLINE.size()):
		var a: Vector2 = OUTLINE[i]
		var b: Vector2 = OUTLINE[(i+1)%OUTLINE.size()]
		var inner_a: Vector2 = a * 0.70
		var inner_b: Vector2 = b * 0.70
		var tone: float = 0.94 + 0.06*sin(float(i)*2.73)
		_tri(surface,parent,height_at,center,inner_a,inner_b,
			Color("#825638")*tone,Color("#9c6a44")*tone,Color("#a77750")*tone,0.017)
		_tri(surface,parent,height_at,inner_a,a,b,
			Color("#b48760"),Color("#dfc4a0"),Color("#ccaa81"),0.019)
		_tri(surface,parent,height_at,inner_a,b,inner_b,
			Color("#b48760"),Color("#d7b893"),Color("#ac7952"),0.018)
		var middle: Vector2 = (a+b)*0.5
		var direction: Vector2 = middle.normalized()
		var tip: Vector2 = middle+direction*(0.028+0.017*absf(sin(float(i)*3.73)))
		_tri(surface,parent,height_at,a,tip,b,
			Color("#b48a65"),Color("#dcc3a3"),Color("#a77650"),0.020)
	# Fibras curtas, quentes e discretas, deitadas acompanhando o solo.
	for i in range(52):
		var angle: float = float(i)*2.39996
		var radius: float = sqrt(float(i+1)/53.0)*0.30
		var base := Vector2(cos(angle)*radius,sin(angle)*radius*1.12)
		var length: float = 0.029 + 0.017*absf(sin(float(i)*1.81))
		var tip := base+Vector2(0.010*sin(float(i)*2.1),-length)
		var fiber: Color = Color("#d3ae81") if i%5==0 else Color("#bb8c61") if i%3==0 else Color("#ae7950")
		_tri(surface,parent,height_at,base+Vector2(-0.006,0),tip,base+Vector2(0.006,0),
			fiber,fiber.lightened(0.09),fiber,0.023)
	surface.generate_normals()
	var mesh := surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.98
	var visual := MeshInstance3D.new()
	visual.name = "PeleCoelhoNoSolo"
	visual.mesh = mesh
	visual.material_override = material
	parent.add_child(visual)
