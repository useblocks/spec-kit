#!/usr/bin/env pwsh
# Format toggle helper — analogous to scripts/bash/format.sh.
#
# Get-SpeckitFormatExt resolves the project's spec/plan/tasks file extension.
#
# Priority:
#   1. SPECIFY_FORMAT env var (if set and valid)
#   2. .specify/config.toml 'format' key (if file exists and valid)
#   3. Default: "md"
#
# Valid values: "md" or "rst". Anything else falls back to "md".

function Get-SpeckitFormatExt {
    param([string]$RepoRoot = ".")

    $candidate = ""

    # Env var wins
    if ($env:SPECIFY_FORMAT) {
        $candidate = $env:SPECIFY_FORMAT
    }
    else {
        $configPath = Join-Path $RepoRoot ".specify/config.toml"
        if (Test-Path -LiteralPath $configPath) {
            try {
                # Minimal TOML reader: scan top-level lines for `format = "..."`
                $content = Get-Content -LiteralPath $configPath -Raw -ErrorAction Stop
                if ($content -match '(?m)^\s*format\s*=\s*"([^"]+)"') {
                    $candidate = $Matches[1]
                }
                elseif ($content -match "(?m)^\s*format\s*=\s*'([^']+)'") {
                    $candidate = $Matches[1]
                }
            }
            catch {
                # config unreadable — fall through to default
            }
        }
    }

    $normalised = $candidate.Trim().ToLowerInvariant()
    switch ($normalised) {
        "rst" { return "rst" }
        default { return "md" }
    }
}
