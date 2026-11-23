extends RefCounted
# Pele de coelho estendida sobre o solo: silhueta irregular e tufos de pelo.
# Malha gerada por vertices coloridos; sem materiais externos ou colisao adicional.

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

func build(parent: Node3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Tres camadas visuais formam couro, bordas claras e pelagem central.
	var center := Vector2(0.0,0.01)
	for i in range(OUTLINE.size()):
		var a: Vector2 = OUTLINE[i]
		var b: Vector2 = OUTLINE[(i+1)%OUTLINE.size()]
		var inner_a := center + (a-center)*0.66
		var inner_b := center + (b-center)*0.66
		var brightness := 0.91 + 0.065*sin(float(i)*2.73)
		tri(surface,center,inner_a,inner_b,0.052,
			Color("#93613d")*brightness,Color("#aa7650")*brightness,Color("#a5744e")*brightness)
		tri(surface,inner_a,a,b,0.049,
			Color("#ac805d"),Color("#dfc6a7"),Color("#d0aa84"))
		tri(surface,inner_a,b,inner_b,0.049,
			Color("#ac805d"),Color("#d0aa84"),Color("#aa7850"))
		# Tufos triangulares saem da borda e quebram o contorno artificial.
		var midpoint := (a+b)*0.5
		var outward := (midpoint-center).normalized()
		var fringe_tip := midpoint + outward*(0.05 + 0.028*absf(sin(float(i)*4.61)))
		tri(surface,a,fringe_tip,b,0.045,
			Color("#b98d65"),Color("#dac0a0"),Color("#aa7954"))
	# Fios finos em direcoes alternadas: textura em relevo superficial.
	for i in range(82):
		var angle := float(i)*2.39996
		var radius := sqrt(float(i+1)/83.0)*0.34
		var p := Vector2(cos(angle)*radius,sin(angle)*radius*1.15)
		var length := 0.055 + 0.025*absf(sin(float(i)*1.91))
		var tip := p + Vector2(0.011*sin(float(i)*2.1),-length)
		var fur_color := Color("#dfc09b") if i%5==0 else Color("#b6855f") if i%3==0 else Color("#c99b73")
		tri(surface,p+Vector2(-0.008,0),tip,p+Vector2(0.008,0),0.057,
			fur_color,fur_color.lightened(0.10),fur_color)
	surface.generate_normals()
	var mesh := surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.96
	var visual := MeshInstance3D.new()
	visual.name = "PeleCoelhoEstendida"
	visual.mesh = mesh
	visual.material_override = material
	parent.add_child(visual)

func tri(surface: SurfaceTool, a: Vector2, b: Vector2, c: Vector2, y: float, ca: Color, cb: Color, cc: Color) -> void:
	for v in [Vector3(a.x,y,a.y),Vector3(b.x,y,b.y),Vector3(c.x,y,c.y)]:
		var color := ca if v.x==a.x and v.z==a.y else cb if v.x==b.x and v.z==b.y else cc
		surface.set_color(color)
		surface.add_vertex(v)
