extends Node
## Consulta a Release oficial, baixa sem carregar o ZIP em memoria e executa
## o instalador externo SOMENTE depois de validar a assinatura SHA-256.
signal status_changed(state: Dictionary)
signal install_ready

const RELEASE_API := "https://api.github.com/repos/clebertressi88/clareira-dos-goblins/releases/tags/jogo-windows"
const RELEASE_ZIP := "https://github.com/clebertressi88/clareira-dos-goblins/releases/download/jogo-windows/Clareira-dos-Goblins-Windows.zip"
const ZIP_NAME := "Clareira-dos-Goblins-Windows.zip"
const REPOSITORY := "clebertressi88/clareira-dos-goblins"
const RELEASE_TAG := "jogo-windows"
const ANDROID_BUILD := preload("res://sistemas/atualizacao/android_build.gd")
const ANDROID_TAG := "jogo-android-lan-v12"
const ANDROID_API := "https://api.github.com/repos/clebertressi88/clareira-dos-goblins/releases/tags/jogo-android-lan-v12"
const ANDROID_APK := "https://github.com/clebertressi88/clareira-dos-goblins/releases/download/jogo-android-lan-v12/Clareira-dos-Goblins-Android.apk"
const ANDROID_APK_NAME := "Clareira-dos-Goblins-Android.apk"
var android_release_code := 0
const PRIVATE_REPO_MESSAGE := "Este jogo está em um repositório GitHub privado. Para consultar, instale o GitHub CLI e execute gh auth login com uma conta autorizada. Para todos os jogadores atualizarem sem login, publique os ZIPs em um repositório público de downloads."
const UPDATE_FOLDER := "user://clareira-atualizador"
const INSTALL_SCRIPT := """
param(
    [Parameter(Mandatory=$true)][string]$ZipPath,
    [Parameter(Mandatory=$true)][string]$GameExe,
    [Parameter(Mandatory=$true)][int]$GamePid,
    [Parameter(Mandatory=$true)][string]$ExpectedSha256,
    [Parameter(Mandatory=$true)][string]$LogPath
)
$ErrorActionPreference = 'Stop'
function Write-Status([string]$Text) {
    $line = ('{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Text)
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}
$extract = $null
$backup = $GameExe + '.backup'
try {
    Write-Status 'Iniciando instalacao do Clareira dos Goblins.'
    if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) { throw 'ZIP de atualizacao nao encontrado.' }
    if (-not (Test-Path -LiteralPath $GameExe -PathType Leaf)) { throw 'Executavel atual nao encontrado.' }
    if ((Split-Path -Leaf $GameExe) -ne 'Clareira-dos-Goblins.exe') { throw 'Nome de executavel inesperado.' }
    $actualZipHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualZipHash -ne $ExpectedSha256.ToLowerInvariant()) { throw 'SHA-256 do ZIP nao confere com a Release.' }
    $extract = Join-Path $env:TEMP ('Clareira-Update-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $extract -Force | Out-Null
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $extract -Force
    $newExe = Join-Path $extract 'Clareira-dos-Goblins.exe'
    $newHashFile = Join-Path $extract 'SHA256SUMS.txt'
    $newVersionFile = Join-Path $extract 'versao-github.txt'
    if (-not (Test-Path -LiteralPath $newExe -PathType Leaf) -or
        -not (Test-Path -LiteralPath $newHashFile -PathType Leaf) -or
        -not (Test-Path -LiteralPath $newVersionFile -PathType Leaf)) {
        throw 'O ZIP nao contem os tres arquivos esperados.'
    }
    $sumLine = Get-Content -LiteralPath $newHashFile | Where-Object { $_.Trim().EndsWith('Clareira-dos-Goblins.exe') } | Select-Object -First 1
    if (-not $sumLine -or $sumLine.Length -lt 64) { throw 'Arquivo SHA256SUMS.txt invalido.' }
    $expectedExeHash = $sumLine.Substring(0,64).ToLowerInvariant()
    if ($expectedExeHash.Length -ne 64) { throw 'Hash do executavel invalido.' }
    $actualExeHash = (Get-FileHash -LiteralPath $newExe -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualExeHash -ne $expectedExeHash) { throw 'Executavel extraido nao passou na verificacao SHA-256.' }
    $newVersion = (Get-Content -LiteralPath $newVersionFile -Raw).Trim()
    if ($newVersion -notmatch '^[0-9a-fA-F]{40}$') { throw 'Identificador da versao invalido.' }
    Write-Status 'ZIP e arquivos internos validados. Aguardando o jogo fechar.'
    for ($attempt=0; $attempt -lt 120; $attempt++) {
        if (-not (Get-Process -Id $GamePid -ErrorAction SilentlyContinue)) { break }
        Start-Sleep -Milliseconds 500
    }
    if (Get-Process -Id $GamePid -ErrorAction SilentlyContinue) { throw 'O jogo nao fechou; instalacao cancelada.' }
    $folder = Split-Path -Parent $GameExe
    Copy-Item -LiteralPath $GameExe -Destination $backup -Force
    Write-Status 'Backup da versao anterior salvo.'
    try {
        $installed = $false
        for ($attempt=0; $attempt -lt 12; $attempt++) {
            try {
                Copy-Item -LiteralPath $newExe -Destination $GameExe -Force
                $installed = $true
                break
            } catch {
                Start-Sleep -Milliseconds 500
            }
        }
        if (-not $installed) { throw 'Nao foi possivel substituir o jogo. Verifique as permissoes da pasta.' }
        if ((Get-FileHash -LiteralPath $GameExe -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedExeHash) {
            throw 'Falha na verificacao do novo executavel instalado.'
        }
        Copy-Item -LiteralPath $newVersionFile -Destination (Join-Path $folder 'versao-github.txt') -Force
        Copy-Item -LiteralPath $newHashFile -Destination (Join-Path $folder 'SHA256SUMS.txt') -Force
    } catch {
        Write-Status ('Falha ao instalar; restaurando backup: ' + $_.Exception.Message)
        Copy-Item -LiteralPath $backup -Destination $GameExe -Force
        throw
    }
    Write-Status ('Instalacao concluida: ' + $newVersion)
    Start-Process -FilePath $GameExe -WorkingDirectory $folder
    Remove-Item -LiteralPath $ZipPath -Force -ErrorAction SilentlyContinue
} catch {
    Write-Status ('ERRO: ' + $_.Exception.Message)
    exit 1
} finally {
    if ($extract -and (Test-Path -LiteralPath $extract)) {
        Remove-Item -LiteralPath $extract -Recurse -Force -ErrorAction SilentlyContinue
    }
}
"""
const MAX_ZIP_SIZE := 300 * 1024 * 1024
const AUTO_CHECK_SECONDS := 300.0 # Cinco minutos.

var state: Dictionary = {"phase":"idle","message":"Confira se há uma nova versão do jogo.","percent":0}
var asset_size := 0
var asset_sha256 := ""
var release_commit := ""
var local_commit := ""
var api_request: HTTPRequest
var zip_request: HTTPRequest
var last_percent := -1
var download_method := "http"
var gh_cli_path := ""
var gh_download_pid := 0
var auto_check_enabled := true
var update_available := false
var _checking_silently := false
var _periodic_timer: Timer

func _ready() -> void:
	api_request = HTTPRequest.new()
	api_request.timeout = 20.0
	api_request.use_threads = true
	add_child(api_request)
	api_request.request_completed.connect(_on_api_finished)
	zip_request = HTTPRequest.new()
	zip_request.timeout = 0.0
	zip_request.use_threads = true
	add_child(zip_request)
	zip_request.request_completed.connect(_on_zip_finished)
	local_commit = _local_version()
	if auto_check_enabled:
		_periodic_timer = Timer.new()
		_periodic_timer.name = "VerificadorAtualizacoes"
		_periodic_timer.wait_time = AUTO_CHECK_SECONDS
		_periodic_timer.one_shot = false
		_periodic_timer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_periodic_timer)
		_periodic_timer.timeout.connect(_on_periodic_update_check)
		_periodic_timer.start()
		# A primeira consulta ocorre sem abrir qualquer tela.
		call_deferred("_on_periodic_update_check")

func _on_periodic_update_check() -> void:
	if str(state.get("phase","")) in ["checking","downloading","verified","installing"]:
		return
	check_updates(true)

func get_state() -> Dictionary:
	return state.duplicate(true)

func _set_phase(phase_name: String,message: String,percent: int = 0) -> void:
	# O marcador permanece aceso durante consultas periodicas ou falhas temporarias.
	if phase_name=="ready":
		update_available = true
	elif phase_name in ["current","installing"]:
		update_available = false
	state = {"phase":phase_name,"message":message,"percent":percent,
		"local_commit":local_commit,"release_commit":release_commit,
		"bytes":asset_size,"update_available":update_available}
	status_changed.emit(get_state())

func check_updates(silent: bool = false) -> void:
	if str(state.get("phase","")) in ["checking","downloading","verified","installing"]:
		return
	_checking_silently = silent
	if not OS.has_feature("windows") and not OS.has_feature("android"):
		_set_phase("error","Atualizações disponíveis no Windows e Android.")
		return
	download_method = "http"
	gh_download_pid = 0
	var android := OS.has_feature("android")
	_set_phase("checking","Consultando a versão Android no GitHub..." if android else "Consultando a versão Windows no GitHub...")
	var result := api_request.request(ANDROID_API if android else RELEASE_API,
		PackedStringArray(["User-Agent: Clareira-dos-Goblins","Accept: application/vnd.github+json"]))
	if result!=OK:
		_set_phase("error","Não foi possível consultar as atualizações. Erro %d." % result)

func _valid_hex(value: String,length_required: int) -> bool:
	if value.length()!=length_required:
		return false
	for i in range(value.length()):
		if not "0123456789abcdef".contains(value.substr(i,1).to_lower()):
			return false
	return true

func _parse_release(data: Dictionary) -> bool:
	if OS.has_feature("android"):
		return _parse_android_release(data)
	asset_sha256 = ""
	asset_size = 0
	release_commit = ""
	if str(data.get("tag_name",""))!="jogo-windows":
		return false
	var body: String = str(data.get("body",""))
	var at: int = body.find("commit ")
	if at<0:
		return false
	var possible: String = body.substr(at+7,40).to_lower()
	if not _valid_hex(possible,40):
		return false
	var assets: Variant = data.get("assets",[])
	if not assets is Array:
		return false
	for item in assets:
		if not item is Dictionary:
			continue
		if str(item.get("name",""))!=ZIP_NAME:
			continue
		if str(item.get("browser_download_url",""))!=RELEASE_ZIP:
			continue
		var size_bytes := int(item.get("size",0))
		var digest: String = str(item.get("digest",""))
		if size_bytes<1024*1024 or size_bytes>MAX_ZIP_SIZE:
			return false
		if not digest.begins_with("sha256:") or not _valid_hex(digest.substr(7),64):
			return false
		asset_size = size_bytes
		asset_sha256 = digest.substr(7).to_lower()
		release_commit = possible
		return true
	return false

func _parse_android_release(data: Dictionary) -> bool:
	asset_size = 0
	asset_sha256 = ""
	release_commit = ""
	android_release_code = 0
	if str(data.get("tag_name",""))!=ANDROID_TAG or bool(data.get("draft",false)):
		return false
	var body := str(data.get("body",""))
	var marker := "android-version-code "
	var start := body.find(marker)
	if start<0:
		return false
	var code_text := body.substr(start+marker.length()).get_slice("\n",0).strip_edges()
	if not code_text.is_valid_int():
		return false
	var code := int(code_text)
	if code<1 or code>2100000000:
		return false
	var assets: Variant = data.get("assets",[])
	if not assets is Array:
		return false
	for item in assets:
		if not item is Dictionary:
			continue
		if str(item.get("name",""))!=ANDROID_APK_NAME or str(item.get("browser_download_url",""))!=ANDROID_APK:
			continue
		var size_bytes := int(item.get("size",0))
		var digest := str(item.get("digest",""))
		if size_bytes<1024*1024 or size_bytes>MAX_ZIP_SIZE or not digest.begins_with("sha256:") or not _valid_hex(digest.substr(7),64):
			return false
		asset_size = size_bytes
		asset_sha256 = digest.substr(7).to_lower()
		android_release_code = code
		release_commit = str(code)
		return true
	return false

func _on_api_finished(result: int,http_code: int,_headers: PackedStringArray,body: PackedByteArray) -> void:
	if str(state.get("phase",""))!="checking":
		return
	if result!=HTTPRequest.RESULT_SUCCESS or http_code!=200:
		if OS.has_feature("android"):
			_set_phase("error","Não foi possível consultar a versão Android (HTTP %d). Tente novamente." % http_code)
			return
		if http_code in [401,403,404]:
			# Em segundo plano, nunca iniciar gh via OS.execute: isso bloquearia o jogo.
			if _checking_silently:
				_set_phase("error","Não foi possível consultar a Release (HTTP %d)." % http_code)
				return
			# Uma Release privada responde 404 para chamadas anonimas.
			# O GitHub CLI usa somente as credenciais guardadas no proprio PC.
			if _try_authenticated_release():
				return
			_set_phase("error",PRIVATE_REPO_MESSAGE)
			return
		_set_phase("error","Não foi possível consultar a Release (HTTP %d). Confira a conexão e tente novamente." % http_code)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary or not _parse_release(parsed):
		_set_phase("error","A versão Android ainda não possui um APK com metadados válidos." if OS.has_feature("android") else "A Release do jogo não contém um ZIP válido e assinado.")
		return
	_complete_release_check()


func _complete_release_check() -> void:
	local_commit = _local_version()
	if OS.has_feature("android"):
		if android_release_code<=ANDROID_BUILD.VERSION_CODE:
			_set_phase("current","Seu jogo já está na versão mais recente.")
		else:
			_set_phase("ready","Nova versão Android disponível: %0.1f MB. Confirme a instalação pelo sistema." % (float(asset_size)/(1024.0*1024.0)))
		return
	if not local_commit.is_empty() and local_commit==release_commit:
		_set_phase("current","Seu jogo já está na versão mais recente.")
	else:
		var suffix := " (acesso GitHub autenticado)" if download_method=="gh" else ""
		_set_phase("ready","Nova versão disponível: %0.1f MB%s." % [float(asset_size)/(1024.0*1024.0),suffix])

func _find_gh_cli() -> String:
	# Prefere o executavel assinado instalado no local padrao do Windows.
	var locations := PackedStringArray()
	for env_name in ["ProgramFiles","ProgramW6432"]:
		var directory := OS.get_environment(env_name)
		if not directory.is_empty():
			locations.append(directory.path_join("GitHub CLI/gh.exe"))
	for candidate in locations:
		if FileAccess.file_exists(candidate):
			return candidate
	# O instalador oficial pode estar no PATH de outro diretorio.
	var output: Array = []
	var code := OS.execute("gh.exe",PackedStringArray(["--version"]),output,false,false)
	if code==0:
		return "gh.exe"
	return ""

func _try_authenticated_release() -> bool:
	if not OS.has_feature("windows"):
		return false
	gh_cli_path = _find_gh_cli()
	if gh_cli_path.is_empty():
		return false
	var output: Array = []
	var code := OS.execute(gh_cli_path,
		PackedStringArray(["api","-H","Accept: application/vnd.github+json",
			"repos/"+REPOSITORY+"/releases/tags/"+RELEASE_TAG]),output,false,false)
	if code!=0 or output.is_empty():
		return false
	var parsed: Variant = JSON.parse_string(str(output[0]))
	if not parsed is Dictionary or not _parse_release(parsed):
		return false
	download_method = "gh"
	_complete_release_check()
	return true

func _private_download_path() -> String:
	return ProjectSettings.globalize_path(UPDATE_FOLDER.path_join(ZIP_NAME))

func _start_gh_download() -> void:
	if gh_cli_path.is_empty():
		gh_cli_path = _find_gh_cli()
	if gh_cli_path.is_empty():
		_set_phase("error",PRIVATE_REPO_MESSAGE)
		return
	var path := _private_download_path()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	last_percent = -1
	_set_phase("downloading","Baixando arquivo privado pela conta GitHub autenticada...",0)
	gh_download_pid = OS.create_process(gh_cli_path,PackedStringArray([
		"release","download",RELEASE_TAG,"--repo",REPOSITORY,
		"--pattern",ZIP_NAME,"--dir",path.get_base_dir(),"--clobber"]))
	if gh_download_pid<=0:
		gh_download_pid = 0
		_set_phase("error","O GitHub CLI não iniciou o download. Verifique a autenticação com gh auth status.")

func _verify_downloaded_zip() -> void:
	var path := _private_download_path()
	var file := FileAccess.open(path,FileAccess.READ)
	if file==null:
		_set_phase("error","O ZIP não foi recebido. Verifique o acesso à Release usando gh auth status.")
		return
	var actual_size := file.get_length()
	file.close()
	if actual_size!=asset_size:
		_set_phase("error","Download incompleto: o tamanho não corresponde ao arquivo da Release.")
		return
	var digest := FileAccess.get_sha256(path).to_lower()
	if digest!=asset_sha256:
		_set_phase("error","Falha na verificação SHA-256. Instalação cancelada por segurança.")
		return
	_set_phase("verified","Download validado. Salvando o progresso para instalar...",100)
	install_ready.emit()

func download_and_install() -> void:
	if str(state.get("phase",""))!="ready":
		return
	if OS.has_feature("android"):
		if android_release_code<=ANDROID_BUILD.VERSION_CODE or not _valid_hex(asset_sha256,64):
			_set_phase("error","Consulte a nova versão novamente.")
			return
		_set_phase("verified","Dados da versão conferidos. Salvando o progresso antes de abrir o download...",0)
		install_ready.emit()
		return
	if not OS.has_feature("windows"):
		_set_phase("error","Instalação automática disponível apenas no Windows.")
		return
	var game_path := OS.get_executable_path()
	if game_path.get_file().to_lower()!="clareira-dos-goblins.exe":
		_set_phase("error","Para atualizar, execute o Clareira-dos-Goblins.exe instalado, não o editor Godot.")
		return
	if not _valid_hex(asset_sha256,64) or asset_size<=0:
		_set_phase("error","Informações da atualização inválidas; consulte novamente.")
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(UPDATE_FOLDER))!=OK:
		_set_phase("error","Sem permissão para criar a pasta de atualização.")
		return
	var zip_path := ProjectSettings.globalize_path(UPDATE_FOLDER.path_join(ZIP_NAME))
	if FileAccess.file_exists(zip_path):
		DirAccess.remove_absolute(zip_path)
	if download_method=="gh":
		_start_gh_download()
		return
	zip_request.download_file = zip_path
	last_percent = -1
	_set_phase("downloading","Baixando atualização do GitHub... 0%",0)
	var result := zip_request.request(RELEASE_ZIP,PackedStringArray(["User-Agent: Clareira-dos-Goblins"]))
	if result!=OK:
		_set_phase("error","Não foi possível iniciar o download. Erro %d." % result)

func _process(_delta: float) -> void:
	if str(state.get("phase",""))!="downloading" or asset_size<=0:
		return
	var downloaded := 0
	if download_method=="gh":
		if gh_download_pid<=0:
			return
		if not OS.is_process_running(gh_download_pid):
			gh_download_pid = 0
			_verify_downloaded_zip()
			return
		var partial := FileAccess.open(_private_download_path(),FileAccess.READ)
		if partial!=null:
			downloaded = partial.get_length()
			partial.close()
	else:
		downloaded = zip_request.get_downloaded_bytes()
	var percent: int = clampi(int(100.0*float(downloaded)/float(asset_size)),0,99)
	if percent==last_percent:
		return
	last_percent=percent
	_set_phase("downloading","Baixando atualização... %d%%" % percent,percent)

func _on_zip_finished(result: int,http_code: int,_headers: PackedStringArray,_body: PackedByteArray) -> void:
	if str(state.get("phase",""))!="downloading":
		return
	if result!=HTTPRequest.RESULT_SUCCESS or http_code!=200:
		if http_code in [401,403,404] and _try_authenticated_release():
			_start_gh_download()
			return
		_set_phase("error","Download indisponível (HTTP %d). Repositório privado: use uma conta GitHub autorizada." % http_code)
		return
	_verify_downloaded_zip()

func _local_version() -> String:
	if OS.has_feature("android"):
		return str(ANDROID_BUILD.VERSION_CODE)
	var version_path := OS.get_executable_path().get_base_dir().path_join("versao-github.txt")
	if not FileAccess.file_exists(version_path):
		return ""
	var version := FileAccess.get_file_as_string(version_path).strip_edges().to_lower()
	return version if _valid_hex(version,40) else ""

func abort_install(message: String) -> void:
	_set_phase("error",message)

func launch_installer() -> bool:
	if str(state.get("phase",""))!="verified":
		return false
	if OS.has_feature("android"):
		var err := OS.shell_open(ANDROID_APK)
		if err!=OK:
			_set_phase("error","Não foi possível abrir o download oficial. Use o link manual.")
			return false
		_set_phase("ready","Download aberto no navegador. Abra o APK baixado e confirme Atualizar. Não desinstale o jogo.",0)
		return true
	var game_path := OS.get_executable_path()
	if game_path.get_file().to_lower()!="clareira-dos-goblins.exe":
		_set_phase("error","Executável inesperado. A instalação foi cancelada.")
		return false
	var base_dir := ProjectSettings.globalize_path(UPDATE_FOLDER)
	var install_file := base_dir.path_join("instalar-clareira.ps1")
	var log_file := base_dir.path_join("instalacao.log")
	var script := FileAccess.open(install_file,FileAccess.WRITE)
	if script==null:
		_set_phase("error","Não foi possível preparar o instalador externo.")
		return false
	script.store_string(INSTALL_SCRIPT)
	script.flush()
	script.close()
	var windows_dir := OS.get_environment("SystemRoot")
	var ps_path := windows_dir.path_join("System32/WindowsPowerShell/v1.0/powershell.exe")
	if windows_dir.is_empty() or not FileAccess.file_exists(ps_path):
		ps_path = "powershell.exe"
	var args := PackedStringArray(["-NoProfile","-NonInteractive","-ExecutionPolicy","Bypass",
		"-WindowStyle","Hidden","-File",install_file,
		"-ZipPath",base_dir.path_join(ZIP_NAME),
		"-GameExe",game_path,"-GamePid",str(OS.get_process_id()),
		"-ExpectedSha256",asset_sha256,"-LogPath",log_file])
	var process_pid := OS.create_process(ps_path,args)
	if process_pid<=0:
		_set_phase("error","Falha ao iniciar o instalador externo. O jogo permanecerá aberto.")
		return false
	_set_phase("installing","Instalador iniciado. O jogo será fechado para atualização.",100)
	return true
