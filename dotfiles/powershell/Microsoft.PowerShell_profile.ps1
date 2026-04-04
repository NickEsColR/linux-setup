# =============================================================================
# PowerShell Profile
# =============================================================================
# Location:
#   - PowerShell 7+:  $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
#   - Windows PS 5.1: $HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
#
# To edit:  code $PROFILE
# To reload: . $PROFILE
# =============================================================================

# ─── Aliases ─────────────────────────────────────────────────────────────────
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name .. -Value { Set-Location .. }
Set-Alias -Name ... -Value { Set-Location ../.. }

# ─── Git shortcuts ───────────────────────────────────────────────────────────
function gs { git status @args }
function gd { git diff @args }
function gc { git commit -m $args[0] }
function gco { git checkout @args }
function gp { git push @args }
function gl { git log --oneline -20 }

# ─── Directory navigation ────────────────────────────────────────────────────
function mkcd {
    param([string]$Path)
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Set-Location $Path
}

# ─── Quick tools ─────────────────────────────────────────────────────────────
function serve {
    param([int]$Port = 8080)
    python -m http.server $Port
}
