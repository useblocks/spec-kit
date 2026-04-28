# Bootstrap sphinx-needs RST scaffolding into the project root.
# Idempotent: existing files are left untouched.
[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

$PresetDir = Join-Path $ProjectRoot ".specify/presets/useblocks-vmodel"

if (-not (Test-Path $PresetDir)) {
    Write-Error "useblocks-vmodel preset not installed at $PresetDir`nrun: specify preset add useblocks-vmodel"
    exit 1
}

New-Item -ItemType Directory -Force -Path (Join-Path $ProjectRoot ".specify") | Out-Null

$created = 0

# Per-feature template files stay inside the preset directory so sphinx-build
# does not pick them up as orphan documents; command prompts reference them
# via the preset path.
foreach ($name in @("ubproject.toml", "conf.py", "coverage.rst")) {
    $src = Join-Path $PresetDir "scaffold/$name"
    $dst = Join-Path $ProjectRoot $name
    if ((Test-Path $src) -and (-not (Test-Path $dst))) {
        Copy-Item $src $dst
        Write-Host "created: $name"
        $created++
    }
}

$cfg = Join-Path $ProjectRoot ".specify/config.toml"
if (-not (Test-Path $cfg)) {
    Set-Content -Path $cfg -Value 'format = "rst"' -NoNewline
    Write-Host "created: .specify/config.toml"
    $created++
}

if ($created -eq 0) {
    Write-Host "scaffolding already present, nothing to do"
} else {
    Write-Host "bootstrap complete: $created file(s) created"
}
