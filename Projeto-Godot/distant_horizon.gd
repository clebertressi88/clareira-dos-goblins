extends RefCounted
## Horizonte visual de baixo custo: continua o relevo alem dos chunks jogaveis.
## Sem colisao, NPCs, recursos ou estados de rede; a distancia e so visual.
const TERRAIN := preload("res://landscape_terrain.gd")
const OUTER_CHUNKS := 10
const SUBDIVISIONS_PER_CHUNK := 2
const FADE_END := 164.0
const QUAD_ORDER := [
	Vector2i(0,0), Vector2i(1,0), Vector2i(0,1),
	Vector2i(1,0), Vector2i(1,1), Vector2i(0,1)
]

static func build(center: Vector2i, loaded_radius: int, chunk_size: int) -> MeshInstance3D:
	var horizon := MeshInstance3D.new()
	horizon.name = "HorizonteDistante"
	horizon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var step := float(chunk_size)/float(SUBDIVISIONS_PER_CHUNK)
	var grid_count := (OUTER_CHUNKS*2+1)*SUBDIVISIONS_PER_CHUNK
	var first_x := float((center.x-OUTER_CHUNKS)*chunk_size)
	var first_z := float((center.y-OUTER_CHUNKS)*chunk_size)
	var near_left := float((center.x-loaded_radius)*chunk_size)
	var near_right := float((center.x+loaded_radius+1)*chunk_size)
	var near_top := float((center.y-loaded_radius)*chunk_size)
	var near_bottom := float((center.y+loaded_radius+1)*chunk_size)
	var origin := Vector2((float(center.x)+.5)*float(chunk_size),(float(center.y)+.5)*float(chunk_size))
	var fade_start := maxf(96.0,float(loaded_radius+1)*float(chunk_size)+10.0)

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# As alturas sao calculadas apenas uma vez por vertice (nao por triangulo).
	var cached_vertices: Dictionary = {}
	for z_index in range(grid_count):
		var z := first_z+float(z_index)*step
		for x_index in range(grid_count):
			var x := first_x+float(x_index)*step
			# Nunca cobrir ou duplicar a malha do terreno jogavel.
			if x>=near_left and x+step<=near_right and z>=near_top and z+step<=near_bottom:
				continue
			for corner in QUAD_ORDER:
				var grid_key := Vector2i(x_index,z_index)+corner
				if not cached_vertices.has(grid_key):
					var vx := first_x+float(grid_key.x)*step
					var vz := first_z+float(grid_key.y)*step
					var y := TERRAIN.height_at(vx,vz)
					var distance := maxf(absf(vx-origin.x),absf(vz-origin.y))
					var color := Color("#6c876d").lerp(Color("#86938c"),clampf((y-3.0)/13.0,0.0,1.0))
					color.a = 1.0-smoothstep(fade_start,FADE_END,distance)
					cached_vertices[grid_key] = [Vector3(vx,y,vz),color]
				var vertex_data: Array = cached_vertices[grid_key]
				var vertex_position: Vector3 = vertex_data[0]
				var vertex_color: Color = vertex_data[1]
				surface.set_uv(Vector2(vertex_position.x,vertex_position.z)*.025)
				surface.set_color(vertex_color)
				surface.add_vertex(vertex_position)
	surface.generate_normals()
	horizon.mesh = surface.commit()

	var background := StandardMaterial3D.new()
	background.albedo_color = Color.WHITE
	background.vertex_color_use_as_albedo = true
	background.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	background.cull_mode = BaseMaterial3D.CULL_DISABLED
	background.roughness = 1.0
	horizon.material_override = background
	return horizon
