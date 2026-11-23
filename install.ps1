# Instala o Agent Kit Java no config GLOBAL do OpenCode (Windows).
# Uso: powershell -ExecutionPolicy Bypass -File install.ps1 [-Force]

param([switch]$Force)

$ErrorActionPreference = "Stop"
$src  = $PSScriptRoot
$dest = Join-Path $HOME ".config\opencode"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "origem:  $src"
Write-Host "destino: $dest"

New-Item -ItemType Directory -Force -Path $dest | Out-Null

$existingConfig = Join-Path $dest "opencode.json"
if ((Test-Path $existingConfig) -or (Test-Path (Join-Path $dest "agents"))) {
    $bk = Join-Path $dest ".backup-$stamp"
    New-Item -ItemType Directory -Force -Path $bk | Out-Null
    foreach ($f in @("opencode.json","AGENTS.md","agents","skills","commands","scripts")) {
        $p = Join-Path $dest $f
        if (Test-Path $p) { Copy-Item $p -Destination $bk -Recurse -Force }
    }
    Write-Host "backup:  $bk"
}

foreach ($d in @("agents","skills","commands","scripts")) {
    $target = Join-Path $dest $d
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Copy-Item (Join-Path $src "global\$d\*") -Destination $target -Recurse -Force
}

Copy-Item (Join-Path $src "global\AGENTS.md") -Destination (Join-Path $dest "AGENTS.md") -Force

if ((Test-Path $existingConfig) -and (-not $Force)) {
    Copy-Item (Join-Path $src "global\opencode.json") -Destination "$existingConfig.new" -Force
    Write-Host ""
    Write-Host "ATENCAO: ja existe $existingConfig - nao mexi nele." -ForegroundColor Yellow
    Write-Host "Mescle os blocos 'subagent_depth', 'instructions' e 'agent' de:"
    Write-Host "  $existingConfig.new"
    Write-Host "(ou rode com -Force para sobrescrever, perdendo provider/API key)"
} else {
    Copy-Item (Join-Path $src "global\opencode.json") -Destination $existingConfig -Force
    Write-Host "config:  $existingConfig"
}

Write-Host ""
Write-Host "verifique com:  opencode agent list" -ForegroundColor Green
