# Gate determinístico do ambiente Java (Windows).
# Uso:  .\agent-gate.ps1            (padrão: pula ITs)
#       .\agent-gate.ps1 -Full      (inclui ITs)
# Override por projeto: .agent-gate.ps1 na raiz do repo.

param([switch]$Full)

$ErrorActionPreference = "Stop"
$root = (git rev-parse --show-toplevel 2>$null)
if (-not $root) { $root = (Get-Location).Path }
Set-Location $root

$log = Join-Path $env:TEMP "agent-gate-$PID.log"
$sw  = [Diagnostics.Stopwatch]::StartNew()

function Run-Gate([string]$exe, [string[]]$argsList) {
    Write-Host "GATE: $exe $($argsList -join ' ')"
    $out = & $exe @argsList 2>&1
    $out | Out-File -FilePath $log -Encoding utf8
    if ($LASTEXITCODE -ne 0) {
        Write-Host "GATE_FAIL (exit $LASTEXITCODE)"
        Get-Content $log -Tail 40
        Write-Host "GATE_FAIL repo=$root cmd=$exe $($argsList -join ' ')"
        Remove-Item $log -ErrorAction SilentlyContinue
        exit $LASTEXITCODE
    }
}

if (Test-Path ".agent-gate.ps1") {
    Write-Host "GATE: override do projeto (.agent-gate.ps1)"
    & "./.agent-gate.ps1" @PSBoundParameters
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "GATE_OK override repo=$root"
    exit 0
}

if (Test-Path "pom.xml") {
    $mvn = if (Test-Path ".\mvnw.cmd") { ".\mvnw.cmd" } else { "mvn" }
    $a = @("-q","-B")
    if (-not $Full) { $a += "-DskipITs" }
    $a += "verify"
    Run-Gate $mvn $a
    Write-Host ("GATE_OK maven repo=$root {0:N0}s" -f $sw.Elapsed.TotalSeconds)
    Remove-Item $log -ErrorAction SilentlyContinue
    exit 0
}

if ((Test-Path "build.gradle") -or (Test-Path "build.gradle.kts")) {
    $gr = if (Test-Path ".\gradlew.bat") { ".\gradlew.bat" } else { "gradle" }
    Run-Gate $gr @("-q","test")
    Write-Host ("GATE_OK gradle repo=$root {0:N0}s" -f $sw.Elapsed.TotalSeconds)
    Remove-Item $log -ErrorAction SilentlyContinue
    exit 0
}

Write-Host "GATE_SKIP: nenhum build tool reconhecido em $root"
Remove-Item $log -ErrorAction SilentlyContinue
exit 3
