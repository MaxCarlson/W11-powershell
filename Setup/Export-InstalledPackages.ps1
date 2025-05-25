<#
.SYNOPSIS
    Exports installed-package lists for Winget, Chocolatey, and Cygwin.
.DESCRIPTION
    - Winget: `winget list --source winget`
    - Chocolatey: `choco list --local-only`
    - Cygwin: parses `C:\cygwin64\etc\setup\installed.db`
.PARAMETER OutputDir
    Folder where the lists will be written. Defaults to `<SetupFolder>\InstalledPackages`.
#>
param(
    [string]$OutputDir = "$PSScriptRoot\InstalledPackages"
)

# 1) Ensure the output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# 2) Winget
$wingetFile = Join-Path $OutputDir 'winget_packages.txt'
Write-Host "Exporting Winget packages → $wingetFile"
winget list --source winget |
  Select-String -Pattern '^\S+' |
  ForEach-Object { ($_ -split '\s+')[0] } |
  Set-Content $wingetFile

# 3) Chocolatey
$chocoFile = Join-Path $OutputDir 'choco_packages.txt'
Write-Host "Exporting Chocolatey packages → $chocoFile"
choco list --local-only --no-color |
  ForEach-Object {
    if ($_ -match '^(?<name>[^|]+)\|') { $Matches['name'] }
  } | Set-Content $chocoFile

# 4) Cygwin
$rawFile   = Join-Path $OutputDir 'cygwin_installed.db'
$pkgFile   = Join-Path $OutputDir 'cygwin_packages.txt'
$cleanFile = Join-Path $OutputDir 'cygwin_pkg_clean.txt'

Write-Host "Copying Cygwin installed.db → $rawFile"
Copy-Item 'C:\cygwin64\etc\setup\installed.db' -Destination $rawFile -Force

Write-Host "Filtering raw Cygwin list → $pkgFile"
Get-Content $rawFile |
  Where-Object { $_ -and -not ($_.StartsWith('#')) } |
  Set-Content $pkgFile

Write-Host "Extracting clean package names → $cleanFile"
Get-Content $pkgFile |
  ForEach-Object { ($_ -split "`t")[0] } |
  Sort-Object -Unique |
  Set-Content $cleanFile

Write-Host "All package lists are now in: $OutputDir"

