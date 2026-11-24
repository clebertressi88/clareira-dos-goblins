extends SceneTree
## Smoke test para cobertura do solo, flora de rio e geracao fixa de biomas.
const BIOMES := preload("res://forest_biomes.gd")
const UNDERSTORY := preload("res://forest_understory.gd")

func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	var root_3d := Node3D.new()
	root.add_child(root_3d)
	var dense_count := 0
	for ix in range(-4,5):
		for iz in range(-4,5):
			var x := float(ix)*96.0+48.0
			var z := float(iz)*96.0+48.0
			if BIOMES.dense_forest(x,z):
				dense_count += 1
				if BIOMES.dense_forest(x,z)!=BIOMES.dense_forest(x,z):
					printerr("UNDERSTORY FAIL: biome inconsistente")
					quit(1)
					return
	if dense_count<5:
		printerr("UNDERSTORY FAIL: bioma de floresta densa nao gerado")
		quit(1)
		return
	UNDERSTORY.populate_chunk(root_3d,Vector2i(3,3))
	var batches := 0
	for child in root_3d.get_children():
		if child is MultiMeshInstance3D:
			batches += 1
			if child.multimesh==null or child.multimesh.instance_count<1:
				printerr("UNDERSTORY FAIL: cobertura vazia")
				quit(1)
				return
	if batches<3:
		printerr("UNDERSTORY FAIL: poucos lotes de vegetacao")
		quit(1)
		return
	for kind in ["fern","forest_shrub","river_reed"]:
		var plant := Node3D.new()
		root_3d.add_child(plant)
		UNDERSTORY.build_plant(plant,kind,"test-"+kind)
		if plant.get_child_count()<5:
			printerr("UNDERSTORY FAIL: malha vegetal ausente "+kind)
			quit(1)
			return
	print("UNDERSTORY BIOMES OK: lotes, mata densa, plantas e trilhas")
	quit(0)
