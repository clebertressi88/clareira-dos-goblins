extends RefCounted
## Relevo e malha de rochas.
## Chamado pelos wrappers em main.gd para preservar o comportamento do jogo.

static func make_rock(cell_size: float) -> ArrayMesh:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in range(3):
		for sign_value in [-1.0,1.0]:
			for j in range(5):
				for i in range(5):
					var u := float(i)/5
					var v := float(j)/5
					var corners := [Vector2(u,v),Vector2(u+.2,v),Vector2(u+.2,v+.2),Vector2(u,v+.2)]
					var order := [0,2,1,0,3,2] if sign_value > 0 else [0,1,2,0,2,3]
					for index in order:
						var uv: Vector2 = corners[index]
						var p := Vector3.ZERO
						p[axis] = sign_value
						p[(axis+1)%3] = uv.x*2-1
						p[(axis+2)%3] = uv.y*2-1
						var divisor := maxf(1.,maxf((p.x+.58*p.z+.35*p.y)/1.34,(-p.x-.75*p.z+.4*p.y)/1.39))
						p /= divisor
						p.x = p.x*(.92-.06*p.y)+.04*p.y
						p.z *= .94+.035*p.x
						mesh.set_uv(uv)
						mesh.add_vertex(p*cell_size/2.)
	mesh.generate_normals()
	return mesh.commit()

static func ground(x: float,z: float) -> float:
	var fade := smoothstep(16.,38.,Vector2(x,z).length())
	return (sin(x*.12)*1.2+cos(z*.14)*.87+sin((x+z)*.22)*.52)*fade
