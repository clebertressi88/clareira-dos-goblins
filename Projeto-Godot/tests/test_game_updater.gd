extends SceneTree
## Consulta da release, verificacao de assinatura e estado sem baixar arquivos.
const UPDATER := preload("res://game_updater.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var updater = UPDATER.new()
	root.add_child(updater)
	await process_frame
	var sha := "abcdef0123456789abcdef0123456789abcdef01"
	var digest := "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
	var manifest := {
		"tag_name":"jogo-windows",
		"body":"Build Windows gerado do commit " + sha + ". Baixe o ZIP e extraia antes de jogar.",
		"assets":[{
			"name":"Clareira-dos-Goblins-Windows.zip",
			"browser_download_url":updater.RELEASE_ZIP,
			"size":46877839,
			"digest":"sha256:"+digest
		}]
	}
	if not updater._parse_release(manifest):
		_fail("manifesto valido da Release nao foi aceito")
		return
	if updater.release_commit!=sha or updater.asset_sha256!=digest or updater.asset_size!=46877839:
		_fail("versao, checksum ou tamanho nao foram processados")
		return
	if updater._valid_hex("0g",2) or updater._valid_hex("../",3):
		_fail("validador aceitou hash invalido")
		return
	var tampered := manifest.duplicate(true)
	var assets := tampered["assets"] as Array
	(assets[0] as Dictionary)["digest"]="sha256:bad"
	if updater._parse_release(tampered):
		_fail("release com assinatura invalida foi aceita")
		return
	var untrusted := manifest.duplicate(true)
	var other_assets := untrusted["assets"] as Array
	(other_assets[0] as Dictionary)["browser_download_url"]="https://example.com/infected.zip"
	if updater._parse_release(untrusted):
		_fail("URL fora do repositorio oficial foi aceita")
		return
	if not updater.INSTALL_SCRIPT.contains("Expand-Archive") or not updater.INSTALL_SCRIPT.contains("Get-FileHash") or not updater.INSTALL_SCRIPT.contains("Start-Process"):
		_fail("instalador externo nao valida e reinicia o jogo")
		return
	if not updater.PRIVATE_REPO_MESSAGE.contains("repositório GitHub privado"):
		_fail("erro 404 nao explica que o repositorio e privado")
		return
	if updater.REPOSITORY!="clebertressi88/clareira-dos-goblins" or updater.RELEASE_TAG!="jogo-windows":
		_fail("fallback autenticado aponta para outro repositorio")
		return
	if updater.launch_installer():
		_fail("instalador iniciou antes do download ser validado")
		return
	print("GAME UPDATE OK: release, SHA-256, URL oficial e instalacao protegida")
	quit(0)

func _fail(reason: String) -> void:
	push_error("GAME UPDATE FAIL: "+reason)
	quit(1)
