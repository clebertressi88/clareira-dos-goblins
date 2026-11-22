extends Node3D

const FLAMES := preload("res://fogueira_chamas.gdshader")
var glow: OmniLight3D
var phase := 0.0

func _ready() -> void:
	for i in range(3):
		var flame := MeshInstance3D.new()
		var plane := QuadMesh.new()
		plane.size = Vector2(.72,.92)
		flame.mesh = plane
		flame.position.y = .53
		flame.rotation.y = i*PI/3
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var shader_material := ShaderMaterial.new()
		shader_material.shader = FLAMES
		shader_material.set_shader_parameter("seed",i*3.7+global_position.x*.31)
		flame.material_override = shader_material
		add_child(flame)
	emit_particles(false)
	emit_particles(true)
	glow = OmniLight3D.new()
	glow.position.y = .43
	glow.light_color = Color("#ff9a50")
	glow.omni_range = 3.2
	glow.light_energy = 1.1
	add_child(glow)
	phase = randf()*TAU

func _process(delta: float) -> void:
	phase = fmod(phase+delta,TAU*10.0)
	glow.light_energy = 1.1+sin(phase*7.)*.17+sin(phase*13.7)*.10+sin(phase*19.1)*.05

func emit_particles(smoke: bool) -> void:
	var particles := CPUParticles3D.new()
	particles.name = "Fumaca" if smoke else "Brasas"
	particles.position.y = .49 if smoke else .23
	particles.amount = 9 if smoke else 19
	particles.lifetime = 2.1 if smoke else .93
	particles.randomness = .55
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = .13
	particles.direction = Vector3(.19,1,.08)
	particles.spread = 26. if smoke else 43.
	particles.gravity = Vector3(.12,.16,.035) if smoke else Vector3(0,-.53,0)
	particles.initial_velocity_min = .27 if smoke else .49
	particles.initial_velocity_max = .49 if smoke else 1.55
	particles.scale_amount_min = .65
	particles.scale_amount_max = 1.35
	var scale_curve := Curve.new()
	scale_curve.max_value = 2.6
	scale_curve.add_point(Vector2(0,.50 if smoke else 1.))
	scale_curve.add_point(Vector2(1,2.45 if smoke else .14))
	particles.scale_amount_curve = scale_curve
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.,.19,1.])
	fade.colors = PackedColorArray([Color(.57,.52,.49,0.),Color(.55,.51,.48,.25),Color(.49,.49,.50,0.)]) if smoke else PackedColorArray([Color("#ffd47d"),Color("#ff913f"),Color(1.,.27,.02,0.)])
	particles.color_ramp = fade
	var sprite := QuadMesh.new()
	sprite.size = Vector2.ONE*(.31 if smoke else .029)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var radial := GradientTexture2D.new()
	radial.width = 32
	radial.height = 32
	radial.fill = GradientTexture2D.FILL_RADIAL
	radial.fill_from = Vector2(.5,.5)
	radial.fill_to = Vector2(.98,.5)
	var edge := Gradient.new()
	edge.colors = PackedColorArray([Color.WHITE,Color(1,1,1,0)])
	radial.gradient = edge
	mat.albedo_texture = radial
	sprite.material = mat
	particles.mesh = sprite
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
