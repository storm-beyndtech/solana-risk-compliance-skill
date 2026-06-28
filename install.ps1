# Installer for solana-risk-compliance-skill (Claude Code skill addon) — Windows / PowerShell
# Usage:  pwsh ./install.ps1     (or right-click > Run with PowerShell)
#         Same result as ./install.sh on macOS/Linux.
$ErrorActionPreference = "Stop"

$SkillName = "solana-risk-compliance"
$Src  = $PSScriptRoot
$Dest = Join-Path $HOME ".claude\skills\$SkillName"

Write-Host "Installing $SkillName -> $Dest"

if (Test-Path $Dest) { Remove-Item -Recurse -Force $Dest }
New-Item -ItemType Directory -Force -Path (Join-Path $Dest "skill") | Out-Null

# SKILL.md must sit at the skill-folder ROOT for Claude Code to discover it.
Copy-Item (Join-Path $Src "skill\SKILL.md") (Join-Path $Dest "SKILL.md")

# The sub-skills stay under skill/ (SKILL.md references them as skill/<file>.md).
Get-ChildItem (Join-Path $Src "skill") -File |
  Where-Object { $_.Name -ne "SKILL.md" } |
  ForEach-Object { Copy-Item $_.FullName (Join-Path $Dest "skill") }

# Agents, commands, rules sit alongside (referenced as agents/… rules/… etc.).
foreach ($d in @("agents", "commands", "rules")) {
  Copy-Item (Join-Path $Src $d) $Dest -Recurse
}
foreach ($f in @("README.md", "LICENSE", "EXAMPLES.md")) {
  $p = Join-Path $Src $f
  if (Test-Path $p) { Copy-Item $p $Dest }
}

Write-Host "Done. The skill is installed at: $Dest"
Write-Host "Entry point: $Dest\SKILL.md   (invocable as /$SkillName)"
Write-Host "Restart Claude Code (or /reload) so it picks up the new skill."
Write-Host "Optional: set RUGBURN_API_URL / RUGBURN_API_KEY to enable engine integration."
