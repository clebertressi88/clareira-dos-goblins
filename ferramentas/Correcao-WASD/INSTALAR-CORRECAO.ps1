$ErrorActionPreference = 'Stop'
try {
    Add-Type -AssemblyName System.Windows.Forms
    $source = Join-Path $PSScriptRoot 'Clareira-dos-Goblins.exe'
    if (!(Test-Path -LiteralPath $source)) { throw 'O EXE novo nao esta junto do instalador.' }
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = 'Selecione o EXECUTAVEL ANTIGO do jogo dentro da pasta Jogo-Windows'
    $dialog.FileName = 'Clareira-dos-Goblins.exe'
    $dialog.Filter = 'Executavel do jogo (Clareira-dos-Goblins.exe)|Clareira-dos-Goblins.exe'
    $dialog.CheckFileExists = $true
    $dialog.Multiselect = $false
    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host 'Instalacao cancelada. Nada foi alterado.'
        return
    }
    $dest = $dialog.FileName
    if ([IO.Path]::GetFileName($dest) -ine 'Clareira-dos-Goblins.exe') {
        throw 'Arquivo selecionado incorreto.'
    }
    if ([IO.Path]::GetFullPath($dest) -ieq [IO.Path]::GetFullPath($source)) {
        throw 'Selecione o EXE ANTIGO, na pasta Jogo-Windows do jogo instalado.'
    }
    $process = Get-Process -Name 'Clareira-dos-Goblins' -ErrorAction SilentlyContinue
    if ($process) {
        throw 'Feche o jogo antes de aplicar a correcao.'
    }
    $backup = $dest + '.backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
    Copy-Item -LiteralPath $dest -Destination $backup -ErrorAction Stop
    Write-Host ('Backup do EXE antigo: ' + $backup)
    Copy-Item -LiteralPath $source -Destination $dest -Force -ErrorAction Stop
    if ((Get-Item -LiteralPath $source).Length -ne (Get-Item -LiteralPath $dest).Length) {
        throw 'Falha na verificacao de tamanho do executavel copiado. Backup preservado.'
    }
    Write-Host 'Correção instalada na MESMA pasta.' -ForegroundColor Green
    Write-Host 'Abra JOGAR.cmd, clique Jogar/continuar ou pressione WASD/setas.'
    Write-Host 'F10 retorna a clareira se a posicao antiga estiver presa em uma montanha.'
} catch {
    Write-Host ('ERRO: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host 'Se o executavel foi alterado, a versao anterior continua no arquivo .backup.'
}
