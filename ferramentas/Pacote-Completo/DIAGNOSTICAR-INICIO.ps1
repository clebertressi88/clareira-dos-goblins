param([switch]$Compatibilidade)
$ErrorActionPreference = 'Stop'
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$folder = Join-Path $base 'Logs-Inicio'
New-Item -Path $folder -ItemType Directory -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = Join-Path $folder ("godot-inicio-$stamp.log")
$report = Join-Path $folder ("relatorio-$stamp.txt")
$exe = Join-Path $base 'Jogo-Windows\Clareira-dos-Goblins.exe'
$engine = Join-Path $base 'Ferramentas\Godot.exe'
$proj = Join-Path $base 'Codigo-Fonte\Projeto-Godot'
$argsList = @('--verbose', '--log-file', ('"' + $log + '"'))
if ($Compatibilidade) { $argsList += @('--rendering-driver', 'opengl3') }
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('CLAREIRA DOS GOBLINS - DIAGNOSTICO')
$lines.Add('Data: ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))
$lines.Add('Pasta do pacote: ' + $base)
$lines.Add('Existe EXE jogo: ' + (Test-Path -LiteralPath $exe))
$lines.Add('Existe Godot portatil: ' + (Test-Path -LiteralPath $engine))
$lines.Add('Existe project.godot: ' + (Test-Path -LiteralPath (Join-Path $proj 'project.godot')))
$lines.Add('Windows: ' + [System.Environment]::OSVersion.VersionString)
try {
    $gpu = Get-CimInstance Win32_VideoController -ErrorAction Stop | Select-Object -ExpandProperty Name
    $lines.Add('GPU: ' + ($gpu -join '; '))
} catch { $lines.Add('GPU: nao identificada') }
$program = $null
$working = $null
if (Test-Path -LiteralPath $exe) {
    $program = $exe
    $working = Split-Path -Parent $exe
} elseif ((Test-Path -LiteralPath $engine) -and (Test-Path -LiteralPath (Join-Path $proj 'project.godot'))) {
    $program = $engine
    $working = $proj
    $argsList = @('--path', ('"' + $proj + '"')) + $argsList
} else {
    $lines.Add('ERRO: nao encontrei o jogo nesta pasta')
    $lines | Set-Content -LiteralPath $report -Encoding UTF8
    Write-Host 'Extraia os scripts na pasta que contem JOGAR.cmd, Jogo-Windows e Ferramentas.' -ForegroundColor Red
    exit 1
}
$lines.Add('Programa: ' + $program)
$lines.Add('Parametros: ' + ($argsList -join ' '))
Write-Host 'Executando jogo e registrando erros...' -ForegroundColor Cyan
Write-Host 'Se abrir, jogue normalmente; o relatorio sera salvo quando o jogo fechar.'
$start = Get-Date
try {
    $process = Start-Process -FilePath $program -WorkingDirectory $working -ArgumentList $argsList -PassThru -Wait -ErrorAction Stop
    $exitCode = $process.ExitCode
    $seconds = ((Get-Date) - $start).TotalSeconds
    $lines.Add('Duracao da execucao (segundos): ' + [math]::Round($seconds, 2))
    $lines.Add('Codigo de saida: ' + $exitCode)
    if ($seconds -lt 12) { $lines.Add('AVISO: processo encerrou em menos de 12 segundos.') }
    if ($exitCode -ne 0) { $lines.Add('AVISO: codigo de saida diferente de zero.') }
} catch { $lines.Add('ERRO ao iniciar: ' + $_.Exception.ToString()) }
$lines.Add('Log: ' + $log)
if (Test-Path -LiteralPath $log) {
    $lines.Add('=== ULTIMAS LINHAS DO GODOT ===')
    Get-Content -LiteralPath $log -Tail 150 | ForEach-Object { $lines.Add([string]$_) }
} else {
    $lines.Add('Log nao criado, falha pode ocorrer antes do Godot iniciar.')
}
$lines | Set-Content -LiteralPath $report -Encoding UTF8
Write-Host 'Envie no chat o arquivo:' -ForegroundColor Yellow
Write-Host $report -ForegroundColor Green
try { Start-Process 'explorer.exe' -ArgumentList ('"' + $folder + '"') } catch {}
