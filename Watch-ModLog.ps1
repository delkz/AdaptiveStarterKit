param(
    [string]$LogPath = (Join-Path $env:USERPROFILE 'Zomboid\console.txt'),
    [ValidateRange(0, 2147483647)]
    [int]$Tail = 100
)

Write-Host "AdaptiveStarterKit - acompanhando: $LogPath"
Write-Host 'Exibindo apenas mensagens do mod. Pressione Ctrl+C para encerrar.'
Write-Host 'Ative Exibir mensagens de diagnostico nas opcoes Sandbox do mod.'

try {
    if (-not (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
        Write-Host 'Aguardando o jogo criar o arquivo de log...'
        while (-not (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
            Start-Sleep -Seconds 1
        }
    }

    Get-Content -LiteralPath $LogPath -Tail $Tail -Wait -ErrorAction Stop |
        ForEach-Object {
            if ($_ -like '*[[]AdaptiveStarterKit[]]*') {
                Write-Host $_
            }
        }
}
catch {
    Write-Host "Nao foi possivel acompanhar o log: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
