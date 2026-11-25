extends RefCounted
## Montagem da arvore; nomes dos nos e IDs preservados para crescimento, corte e rede.
static func build(game, o: StaticBody3D, id: String, bark: Material) -> void:
	var visual := Node3D.new()
	visual.name = "Visual"
	o.add_child(visual)
	# Base e raizes SAO AS MESMAS antes e depois de cortar.
	# Nao e criado um outro tronco mais grosso quando vira toco.
	var base := Node3D.new()
	base.name = "BaseTronco"
	visual.add_child(base)
	# Base alargada e raizes afuniladas, ligadas dentro do tronco.
	var wood_geo := preload("res://forest_wood_geometry.gd")
	wood_geo.make_trunk(base,bark,false)
	wood_geo.make_roots(base,bark,id)
	var growth := Node3D.new()
	growth.name = "Crescimento"
	visual.add_child(growth)
	# Tronco adulto unico desde o solo ate a copa: elimina a emenda
	# visivel entre dois cilindros sobrepostos no ponto de corte.
	wood_geo.make_trunk(growth,bark,true)
	# Copas detalhadas, galhos e variacao deterministica por ID.
	# O tronco continua sendo a unica colisao da arvore.
	preload("res://forest_tree_visual.gd").decorate(growth,bark,id)
	var hanging_vines := Node3D.new()
	hanging_vines.name = "Vinhas"
	growth.add_child(hanging_vines)
	var stump := Node3D.new()
	stump.name = "Toco"
	visual.add_child(stump)
	# So o corte transversal aparece; as raizes e base nunca mudam.
	game.cylinder(stump,Vector3(0,.527,0),.234,.028,"cut_wood",Color("#c6a273"))
	var sprout := Node3D.new()
	sprout.name = "Broto"
	visual.add_child(sprout)
	# Broto de apenas alguns centimetros, sem haste verde alta.
	preload("res://tree_growth_stages.gd").make_bud(sprout,id)
	# Muda e jovem usam modelos proprios, com base local zero no corte.
	var sapling_stage := Node3D.new()
	sapling_stage.name = "Muda"
	visual.add_child(sapling_stage)
	preload("res://tree_growth_stages.gd").make_stage(sapling_stage,bark,id,false)
	var young_stage := Node3D.new()
	young_stage.name = "Jovem"
	visual.add_child(young_stage)
	preload("res://tree_growth_stages.gd").make_stage(young_stage,bark,id,true)
	game.collider(o,Vector3(.43,2.7,.43),Vector3.UP*1.35)
	game.update_tree_visual(o)
