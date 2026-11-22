extends RefCounted
## Materiais V4: paleta PBR com manchas sutis, poros e couro gasto.
## Shader sem dependencias de texturas externas nem coordenadas UV.
const SURFACE = preload("res://experimentos/goblin_v4_surface.gdshader")

static func make(color_code: String, kind: String, roughness: float, metallic: float = 0.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SURFACE
	material.set_shader_parameter("tint", Color(color_code))
	material.set_shader_parameter("surface_roughness", roughness)
	material.set_shader_parameter("surface_metallic", metallic)
	var scale := 35.0
	var strength := 0.13
	var flecks := 0.04
	var scratches := 0.0
	match kind:
		"skin":
			scale = 46.0
			strength = 0.17
			flecks = 0.065
		"skin_detail":
			scale = 60.0
			strength = 0.10
			flecks = 0.035
		"leather":
			scale = 36.0
			strength = 0.22
			flecks = 0.07
			scratches = 0.10
		"boot":
			scale = 31.0
			strength = 0.21
			flecks = 0.05
			scratches = 0.09
		"metal":
			scale = 57.0
			strength = 0.06
			flecks = 0.02
		"eye":
			scale = 18.0
			strength = 0.025
			flecks = 0.0
	material.set_shader_parameter("grain_scale", scale)
	material.set_shader_parameter("grain_strength", strength)
	material.set_shader_parameter("fleck_strength", flecks)
	material.set_shader_parameter("scratch_strength", scratches)
	return material
