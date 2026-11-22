# Clareira dos Goblins - gerador Windows com logs e codigo de saida confiavel.
# Coloque este arquivo na pasta que contem o projeto baixado.
# Exemplo: powershell -ExecutionPolicy Bypass -File .\GERAR-EXE-WINDOWS-CORRIGIDO.ps1
# Opcional: -GodotExe "C:\Caminho\Godot_v4.7.2-stable_win64_console.exe"
param(
    [string]$Projeto = $PSScriptRoot,
    [string]$GodotExe = ""
)

$ErrorActionPreference = 'Stop'

function Falhar([string]$Mensagem) {
    Write-Host "" 
    Write-Host "ERRO: $Mensagem" -ForegroundColor Red
    exit 1
}

function Procurar-Godot([string]$PastaBase) {
    $candidatos = New-Object 'System.Collections.Generic.List[string]'
    foreach ($nome in @('godot', 'godot4', 'godot.exe', 'godot4.exe')) {
        $cmd = Get-Command $nome -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source -PathType Leaf)) {
            $candidatos.Add($cmd.Source)
        }
    }
    $pastas = @(
        $PastaBase,
        (Split-Path -Path $PastaBase -Parent),
        (Join-Path $PastaBase 'Godot'),
        (Join-Path $PastaBase 'tools'),
        (Join-Path $PastaBase 'bin'),
        (Join-Path $env:LOCALAPPDATA 'Programs'),
        (Join-Path $env:USERPROFILE 'Downloads'),
        (Join-Path $env:USERPROFILE 'Desktop'),
        (Join-Path $env:PUBLIC 'Desktop'),
        (Join-Path $env:LOCALAPPDATA 'Programs'),
        (Join-Path $env:USERPROFILE 'Documents')
    )
    if ($env:ProgramFiles) { $pastas += (Join-Path $env:ProgramFiles 'Godot') }
    $pastas = $pastas | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Container) } | Select-Object -Unique
    foreach ($pasta in $pastas) {
        # Procura somente executaveis com Godot no nome.
        Get-ChildItem -LiteralPath $pasta -File -Filter '*Godot*.exe' -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^(?i:Godot).*\.exe$' } |
            ForEach-Object { $candidatos.Add($_.FullName) }
    }
    $encontrados = @($candidatos | Select-Object -Unique)
    if ($encontrados.Count -eq 0) { return $null }
    # Preferir o console, que e feito para rodar comandos e registrar logs.
    $preferido = $encontrados |
        Sort-Object -Property @{Expression={ if ($_ -match '(?i)4[._-]7[._-]2') { 0 } else { 1 } }},
                              @{Expression={ if ($_ -match '(?i)_console\.exe$') { 0 } else { 1 } }} |
        Select-Object -First 1
    return [string]$preferido
}

function Invocar-Godot([string]$Executavel, [string]$PastaProjeto, [string[]]$Argumentos, [string]$Log) {
    # System.Diagnostics.Process captura ExitCode mesmo se Godot for executavel GUI.
    # Saida e erro sao lidos ao mesmo tempo para evitar bloqueio de buffers.
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Executavel
    $psi.WorkingDirectory = $PastaProjeto
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.Arguments = (($Argumentos | ForEach-Object {
        if ($_ -match '\s|"') { '"' + $_.Replace('"', '\"') + '"' } else { $_ }
    }) -join ' ')

    $processo = New-Object System.Diagnostics.Process
    $processo.StartInfo = $psi
    try {
        if (-not $processo.Start()) { throw 'O Godot nao iniciou.' }
        $tarefaSaida = $processo.StandardOutput.ReadToEndAsync()
        $tarefaErro = $processo.StandardError.ReadToEndAsync()
        $processo.WaitForExit()
        $saida = $tarefaSaida.GetAwaiter().GetResult()
        $erro = $tarefaErro.GetAwaiter().GetResult()
        $codigo = $processo.ExitCode
        $texto = "COMANDO: $Executavel $($psi.Arguments)`r`nCODIGO DE SAIDA: $codigo`r`n`r`n=== STDOUT ===`r`n$saida`r`n=== STDERR ===`r`n$erro"
        [System.IO.File]::WriteAllText($Log, $texto, [System.Text.Encoding]::UTF8)
        if ($saida.Trim()) { Write-Host $saida.Trim() }
        if ($erro.Trim()) { Write-Host $erro.Trim() -ForegroundColor Yellow }
        return [pscustomobject]@{ Codigo = $codigo; Texto = $saida + "`n" + $erro; Log = $Log }
    } finally {
        $processo.Dispose()
    }
}

try {
    Write-Host '=== CLAREIRA DOS GOBLINS - GERAR WINDOWS (CORRIGIDO) ===' -ForegroundColor Cyan
    $base = (Resolve-Path -LiteralPath $Projeto).Path

    # A pasta pode conter o projeto diretamente ou em uma subpasta.
    $arquivoProjeto = Join-Path $base 'project.godot'
    if (-not (Test-Path -LiteralPath $arquivoProjeto -PathType Leaf)) {
        $arquivoProjeto = Get-ChildItem -LiteralPath $base -Filter 'project.godot' -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '(?i)[\\/](?:\.godot|Windows-Atualizado|\.git)[\\/]' } |
            Select-Object -ExpandProperty FullName -First 1
    }
    if (-not $arquivoProjeto) { Falhar "Arquivo project.godot nao encontrado em $base. Extraia o projeto completo antes de executar." }
    $pastaProjeto = Split-Path -Parent $arquivoProjeto
    Write-Host "Projeto: $pastaProjeto"

    if ($GodotExe) {
        if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
            Falhar "Godot nao encontrado em: $GodotExe"
        }
        $executavel = (Resolve-Path -LiteralPath $GodotExe).Path
    } else {
        $executavel = Procurar-Godot $base
    }
    if (-not $executavel) {
        Write-Host 'Godot nao localizado nas pastas usuais. Selecione o executavel do Godot na janela que sera aberta.' -ForegroundColor Yellow
        try {
            Add-Type -AssemblyName System.Windows.Forms
            $dialogo = New-Object System.Windows.Forms.OpenFileDialog
            $dialogo.Title = 'Localizar Godot 4 - selecione Godot*.exe'
            $dialogo.Filter = 'Godot (Godot*.exe)|Godot*.exe|Executaveis (*.exe)|*.exe'
            $dialogo.CheckFileExists = $true
            $dialogo.Multiselect = $false
            if ($dialogo.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $executavel = $dialogo.FileName
            }
            $dialogo.Dispose()
        } catch {
            Write-Host "Nao foi possivel abrir o seletor de arquivos: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    if (-not $executavel) {
        Falhar 'Godot 4 nao encontrado. Instale/extraia Godot 4 no computador e execute novamente. O atualizador de arquivos funcionou; somente a geracao do EXE depende do Godot.'
    }
    Write-Host "Godot: $executavel"

    $pastaLogs = Join-Path $base 'logs-geracao'
    New-Item -ItemType Directory -Path $pastaLogs -Force | Out-Null
    $logImport = Join-Path $pastaLogs 'importacao-godot.log'
    $logExport = Join-Path $pastaLogs 'exportacao-godot.log'

    Write-Host "`nETAPA 1/2: Importando imagens e scripts..." -ForegroundColor Cyan
    $import = Invocar-Godot $executavel $pastaProjeto @('--headless', '--path', $pastaProjeto, '--import') $logImport
    if ($import.Codigo -ne 0) { Falhar "Importacao devolveu codigo $($import.Codigo). Veja: $logImport" }
    if ($import.Texto -match '(?im)^\s*(?:SCRIPT\s+)?ERROR\s*:') {
        Falhar "O Godot encontrou erro durante a importacao. Veja: $logImport"
    }
    Write-Host 'Importacao concluida.' -ForegroundColor Green

    $configPreset = Join-Path $pastaProjeto 'export_presets.cfg'
    if (-not (Test-Path -LiteralPath $configPreset -PathType Leaf)) {
        Falhar 'Falta export_presets.cfg. Abra o projeto no Godot: Projeto > Exportar, adicione Windows Desktop e salve o preset.'
    }
    $config = Get-Content -LiteralPath $configPreset -Raw
    $blocos = [regex]::Matches($config, '(?ms)^\[preset\.\d+\]\s*\r?\n(.*?)(?=^\[preset\.\d+(?:\.options)?\]|\z)')
    $nomePreset = $null
    foreach ($bloco in $blocos) {
        if ($bloco.Value -match '(?m)^platform="Windows Desktop"\s*$' -and
            $bloco.Value -match '(?m)^name="([^"]+)"\s*$') {
            $nomePreset = $Matches[1]
            break
        }
    }
    if (-not $nomePreset) { Falhar 'Nao encontrei um preset Windows Desktop em export_presets.cfg. Configure no Godot: Projeto > Exportar.' }
    Write-Host "Preset: $nomePreset"

    $pastaSaida = Join-Path $base 'Windows-Atualizado'
    New-Item -ItemType Directory -Path $pastaSaida -Force | Out-Null
    $exe = Join-Path $pastaSaida 'Clareira-dos-Goblins.exe'

    Write-Host "`nETAPA 2/2: Exportando para Windows..." -ForegroundColor Cyan
    $export = Invocar-Godot $executavel $pastaProjeto @('--headless', '--path', $pastaProjeto, '--export-release', $nomePreset, $exe) $logExport
    if ($export.Codigo -ne 0 -or -not (Test-Path -LiteralPath $exe -PathType Leaf)) {
        Falhar "Exportacao falhou (codigo $($export.Codigo)). Veja: $logExport. Se faltarem templates, instale em Editor > Gerenciar Templates de Exportacao."
    }
    if ($export.Texto -match '(?im)^\s*(?:SCRIPT\s+)?ERROR\s*:') {
        Falhar "Exportacao apresentou erros. Confira: $logExport"
    }

    $arquivoZip = Join-Path $base 'Clareira-dos-Goblins-Windows-Atualizado.zip'
    if (Test-Path -LiteralPath $arquivoZip) { Remove-Item -LiteralPath $arquivoZip -Force }
    Compress-Archive -Path (Join-Path $pastaSaida '*') -DestinationPath $arquivoZip -Force

    Write-Host "`nSUCESSO!" -ForegroundColor Green
    Write-Host "EXE: $exe"
    Write-Host "ZIP para compartilhar: $arquivoZip"
    Write-Host "Logs: $pastaLogs"
    exit 0
} catch {
    Write-Host "`nERRO INESPERADO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace
    exit 1
}
