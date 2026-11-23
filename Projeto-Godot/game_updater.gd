extends Node
## Consulta a Release oficial, baixa sem carregar o ZIP em memoria e executa
## o instalador externo SOMENTE depois de validar a assinatura SHA-256.
signal status_changed(state: Dictionary)
signal install_ready

const RELEASE_API := "https://api.github.com/repos/clebertressi88/clareira-dos-goblins/releases/tags/jogo-windows"
const RELEASE_ZIP := "https://github.com/clebertressi88/clareira-dos-goblins/releases/download/jogo-windows/Clareira-dos-Goblins-Windows.zip"
const ZIP_NAME := "Clareira-dos-Goblins-Windows.zip"
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

var state: Dictionary = {"phase":"idle","message":"Confira se há uma nova versão do jogo.","percent":0}
var asset_size := 0
var asset_sha256 := ""
var release_commit := ""
var local_commit := ""
var api_request: HTTPRequest
var zip_request: HTTPRequest
var last_percent := -1

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

func get_state() -> Dictionary:
	return state.duplicate(true)

func _set_phase(phase_name: String,message: String,percent: int = 0) -> void:
	state = {"phase":phase_name,"message":message,"percent":percent,
		"local_commit":local_commit,"release_commit":release_commit,"bytes":asset_size}
	status_changed.emit(get_state())

func check_updates() -> void:
	if str(state.get("phase","")) in ["checking","downloading","installing"]:
		return
	if not OS.has_feature("windows"):
		_set_phase("error","A instalação automática está disponível somente no Windows.")
		return
	_set_phase("checking","Consultando a versão Windows no GitHub...")
	var result := api_request.request(RELEASE_API,
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

func _on_api_finished(result: int,http_code: int,_headers: PackedStringArray,body: PackedByteArray) -> void:
	if str(state.get("phase",""))!="checking":
		return
	if result!=HTTPRequest.RESULT_SUCCESS or http_code!=200:
		_set_phase("error","Falha ao consultar o GitHub (HTTP %d). Confira sua conexão." % http_code)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary or not _parse_release(parsed):
		_set_phase("error","A Release do jogo não contém um ZIP válido e assinado.")
		return
	local_commit = _local_version()
	if not local_commit.is_empty() and local_commit==release_commit:
		_set_phase("current","Seu jogo já está na versão mais recente.")
	else:
		_set_phase("ready","Nova versão disponível para baixar (%0.1f MB)." % (float(asset_size)/(1024.0*1024.0)))

func download_and_install() -> void:
	if str(state.get("phase",""))!="ready":
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
	zip_request.download_file = zip_path
	last_percent = -1
	_set_phase("downloading","Baixando atualização do GitHub... 0%",0)
	var result := zip_request.request(RELEASE_ZIP,PackedStringArray(["User-Agent: Clareira-dos-Goblins"]))
	if result!=OK:
		_set_phase("error","Não foi possível iniciar o download. Erro %d." % result)

func _process(_delta: float) -> void:
	if str(state.get("phase",""))!="downloading" or asset_size<=0:
		return
	var downloaded := zip_request.get_downloaded_bytes()
	var percent: int = clampi(int(100.0*float(downloaded)/float(asset_size)),0,99)
	if percent==last_percent:
		return
	last_percent=percent
	_set_phase("downloading","Baixando atualização... %d%%" % percent,percent)

func _on_zip_finished(result: int,http_code: int,_headers: PackedStringArray,_body: PackedByteArray) -> void:
	if str(state.get("phase",""))!="downloading":
		return
	if result!=HTTPRequest.RESULT_SUCCESS or http_code!=200:
		_set_phase("error","Download interrompido (HTTP %d). Tente novamente." % http_code)
		return
	var zip_path := ProjectSettings.globalize_path(UPDATE_FOLDER.path_join(ZIP_NAME))
	var file := FileAccess.open(zip_path,FileAccess.READ)
	if file==null:
		_set_phase("error","Não foi possível abrir o ZIP baixado.")
		return
	var actual_size := file.get_length()
	file.close()
	if actual_size!=asset_size:
		_set_phase("error","Tamanho do ZIP diferente do publicado. Tente novamente.")
		return
	var actual_sha := FileAccess.get_sha256(zip_path).to_lower()
	if actual_sha!=asset_sha256:
		_set_phase("error","Assinatura SHA-256 inválida. A instalação foi cancelada.")
		return
	_set_phase("verified","Download validado. Salvando o jogo para instalar...",100)
	install_ready.emit()

func _local_version() -> String:
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
) { throw 'Identificador da versao invalido.' }\n    Write-Status 'ZIP e arquivos internos validados. Aguardando o jogo fechar.'\n    for ($attempt=0; $attempt -lt 120; $attempt++) {\n        if (-not (Get-Process -Id $GamePid -ErrorAction SilentlyContinue)) { break }\n        Start-Sleep -Milliseconds 500\n    }\n    if (Get-Process -Id $GamePid -ErrorAction SilentlyContinue) { throw 'O jogo nao fechou; instalacao cancelada.' }\n    $folder = Split-Path -Parent $GameExe\n    Copy-Item -LiteralPath $GameExe -Destination $backup -Force\n    Write-Status 'Backup da versao anterior salvo.'\n    try {\n        $installed = $false\n        for ($attempt=0; $attempt -lt 12; $attempt++) {\n            try {\n                Copy-Item -LiteralPath $newExe -Destination $GameExe -Force\n                $installed = $true\n                break\n            } catch {\n                Start-Sleep -Milliseconds 500\n            }\n        }\n        if (-not $installed) { throw 'Nao foi possivel substituir o jogo. Verifique as permissoes da pasta.' }\n        if ((Get-FileHash -LiteralPath $GameExe -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedExeHash) {\n            throw 'Falha na verificacao do novo executavel instalado.'\n        }\n        Copy-Item -LiteralPath $newVersionFile -Destination (Join-Path $folder 'versao-github.txt') -Force\n        Copy-Item -LiteralPath $newHashFile -Destination (Join-Path $folder 'SHA256SUMS.txt') -Force\n    } catch {\n        Write-Status ('Falha ao instalar; restaurando backup: ' + $_.Exception.Message)\n        Copy-Item -LiteralPath $backup -Destination $GameExe -Force\n        throw\n    }\n    Write-Status ('Instalacao concluida: ' + $newVersion)\n    Start-Process -FilePath $GameExe -WorkingDirectory $folder\n    Remove-Item -LiteralPath $ZipPath -Force -ErrorAction SilentlyContinue\n} catch {\n    Write-Status ('ERRO: ' + $_.Exception.Message)\n    exit 1\n} finally {\n    if ($extract -and (Test-Path -LiteralPath $extract)) {\n        Remove-Item -LiteralPath $extract -Recurse -Force -ErrorAction SilentlyContinue\n    }\n}"
const MAX_ZIP_SIZE := 300 * 1024 * 1024

var state: Dictionary = {"phase":"idle","message":"Confira se há uma nova versão do jogo.","percent":0}
var asset_size := 0
var asset_sha256 := ""
var release_commit := ""
var local_commit := ""
var api_request: HTTPRequest
var zip_request: HTTPRequest
var last_percent := -1

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

func get_state() -> Dictionary:
	return state.duplicate(true)

func _set_phase(phase_name: String,message: String,percent: int = 0) -> void:
	state = {"phase":phase_name,"message":message,"percent":percent,
		"local_commit":local_commit,"release_commit":release_commit,"bytes":asset_size}
	status_changed.emit(get_state())

func check_updates() -> void:
	if str(state.get("phase","")) in ["checking","downloading","installing"]:
		return
	if not OS.has_feature("windows"):
		_set_phase("error","A instalação automática está disponível somente no Windows.")
		return
	_set_phase("checking","Consultando a versão Windows no GitHub...")
	var result := api_request.request(RELEASE_API,
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

func _on_api_finished(result: int,http_code: int,_headers: PackedStringArray,body: PackedByteArray) -> void:
	if str(state.get("phase",""))!="checking":
		return
	if result!=HTTPRequest.RESULT_SUCCESS or http_code!=200:
		_set_phase("error","Falha ao consultar o GitHub (HTTP %d). Confira sua conexão." % http_code)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary or not _parse_release(parsed):
		_set_phase("error","A Release do jogo não contém um ZIP válido e assinado.")
		return
	local_commit = _local_version()
	if not local_commit.is_empty() and local_commit==release_commit:
		_set_phase("current","Seu jogo já está na versão mais recente.")
	else:
		_set_phase("ready","Nova versão disponível para baixar (%0.1f MB)." % (float(asset_size)/(1024.0*1024.0)))

func download_and_install() -> void:
	if str(state.get("phase",""))!="ready":
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
	zip_request.download_file = zip_path
	last_percent = -1
	_set_phase("downloading","Baixando atualização do GitHub... 0%",0)
	var result := zip_request.request(RELEASE_ZIP,PackedStringArray(["User-Agent: Clareira-dos-Goblins"]))
	if result!=OK:
		_set_phase("error","Não foi possível iniciar o download. Erro %d." % result)

func _process(_delta: float) -> void:
	if str(state.get("phase",""))!="downloading" or asset_size<=0:
		return
	var downloaded := zip_request.get_downloaded_bytes()
	var percent: int = clampi(int(100.0*float(downloaded)/float(asset_size)),0,99)
	if percent==last_percent:
		return
	last_percent=percent
	_set_phase("downloading","Baixando atualização... %d%%" % percent,percent)

func _on_zip_finished(result: int,http_code: int,_headers: PackedStringArray,_body: PackedByteArray) -> void:
	if str(state.get("phase",""))!="downloading":
		return
	if result!=HTTPRequest.RESULT_SUCCESS or http_code!=200:
		_set_phase("error","Download interrompido (HTTP %d). Tente novamente." % http_code)
		return
	var zip_path := ProjectSettings.globalize_path(UPDATE_FOLDER.path_join(ZIP_NAME))
	var file := FileAccess.open(zip_path,FileAccess.READ)
	if file==null:
		_set_phase("error","Não foi possível abrir o ZIP baixado.")
		return
	var actual_size := file.get_length()
	file.close()
	if actual_size!=asset_size:
		_set_phase("error","Tamanho do ZIP diferente do publicado. Tente novamente.")
		return
	var actual_sha := FileAccess.get_sha256(zip_path).to_lower()
	if actual_sha!=asset_sha256:
		_set_phase("error","Assinatura SHA-256 inválida. A instalação foi cancelada.")
		return
	_set_phase("verified","Download validado. Salvando o jogo para instalar...",100)
	install_ready.emit()

func _local_version() -> String:
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
