extends SceneTree
## Teste em Godot real: instancia o asset e verifica a escala normalizada.

func _initialize() -> void:
	call_deferred("_testar")

func _testar() -> void:
	var base := Node3D.new()
	base.name = "TesteGoblin"
	root.add_child(base)
	var integrador: Script = load("res://personagens/goblin_visual.gd")
	var ok: bool = integrador.anexar(base)
	if not ok:
		push_error("Falha ao instanciar o goblin importado")
		quit(1)
		return

	var suporte: Node3D = base.get_meta("goblin_glb_suporte", null) as Node3D
	if not is_instance_valid(suporte):
		push_error("Suporte do modelo nao encontrado")
		quit(1)
		return

	if suporte.scale.y <= 0.0 or suporte.scale.y >= 1.0:
		push_error("Escala do modelo nao normalizada: " + str(suporte.scale.y))
		quit(1)
		return

	integrador.animar(base, Vector3(1.0, 0.0, 0.0), 0.1)
	print("OK: importacao, escala e animacao simples do goblin 3D")
	quit(0)
