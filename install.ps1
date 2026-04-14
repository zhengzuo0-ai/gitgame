# gitgame installer (PowerShell) — bootstraps a clone for play.
# Idempotent. Run from the repo root: .\install.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "━━━━━━ gitgame install ━━━━━━"

# 1. git repo
$inRepo = $false
try { git rev-parse --git-dir 2>$null | Out-Null; $inRepo = $LASTEXITCODE -eq 0 } catch {}
if (-not $inRepo) {
    Write-Host "  ✗ not in a git repo — initializing"
    git init -q
    git add -A | Out-Null
    git commit -q -m "Initial commit" 2>$null | Out-Null
} else {
    Write-Host "  ✓ git repo present"
}

# 2. git config
if (-not (git config user.name 2>$null)) {
    Write-Host "  ! git user.name not set — using 'gitgame player'"
    git config user.name "gitgame player"
}
if (-not (git config user.email 2>$null)) {
    Write-Host "  ! git user.email not set — using 'player@gitgame.local'"
    git config user.email "player@gitgame.local"
}

# 3. line-ending normalization
if (-not (Test-Path ".gitattributes")) {
    "* text=auto eol=lf" | Out-File -Encoding ascii ".gitattributes"
    Write-Host "  + wrote .gitattributes"
}

# 4. Python detection — skip MS Store stubs by running a real eval
$py = $null
foreach ($cand in @("py", "python3", "python")) {
    $cmd = Get-Command $cand -ErrorAction SilentlyContinue
    if (-not $cmd) { continue }
    try {
        & $cand -c "import sys; sys.exit(0)" 2>$null
        if ($LASTEXITCODE -eq 0) { $py = $cand; break }
    } catch {}
}
if (-not $py) {
    Write-Host "  ✗ no working Python found."
    Write-Host "    Install: winget install Python.Python.3.12"
    exit 1
}
$ver = & $py -c "import sys; print(sys.version.split()[0])"
Write-Host "  ✓ python: $py ($ver)"

# 5. Smoke test dice.py
$out = & $py .claude/scripts/dice.py abc123 1 install-test 2>&1
if ($LASTEXITCODE -ne 0 -or $out -notmatch '^\d+$') {
    Write-Host "  ✗ dice.py smoke test failed: $out"
    exit 1
}
Write-Host "  ✓ dice.py runs"

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "  Ready. In Claude Code:  /roll-character"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
