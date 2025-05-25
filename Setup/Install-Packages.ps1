<#
.SYNOPSIS
  Installs any missing packages from master + machine-override lists.
.DESCRIPTION
  - Reads Setup/Lists/master.packages.txt  
  - Reads Setup/Lists/machine.$env:COMPUTERNAME.packages.txt (if exists)  
  - Merges them (dedup), then:
      • Installs via Winget, Chocolatey, and Cygwin  
  - On subsequent runs:  
      • Detects “installed vs desired” drift  
      • Prompts user to install missing or update lists
#>
[CmdletBinding()]
param()
$listsDir = Join-Path $PSScriptRoot 'Lists'
$master   = Join-Path $listsDir 'master.packages.txt'
$machine  = Join-Path $listsDir "machine.$env:COMPUTERNAME.packages.txt"

# 1) Load lists
$masterList  = Get-Content $master -ErrorAction Stop
$machineList = if (Test-Path $machine) { Get-Content $machine } else { @() }

# 2) Desired = union(master, machine)
$desired = ($masterList + $machineList) | Sort-Object -Unique

# 3) Detect what's installed
$wingetInstalled = winget list --source winget | Select-String '^\S+' | ForEach-Object { ($_ -split '\s+')[0] }
$chocoInstalled  = choco list --local-only --no-color | ForEach-Object { if ($_ -match '^(?<n>[^|]+)\|') { $Matches['n'] } }
$cygwinInstalled = Get-Content 'C:\cygwin64\etc\setup\installed.db' |
                      Where-Object {$_ -notmatch '^#'} |
                      ForEach-Object { ($_ -split "\t")[0] }

$installed = ($wingetInstalled + $chocoInstalled + $cygwinInstalled) | Sort-Object -Unique

# 4) What’s missing?
$missing = $desired | Where-Object { $_ -notin $installed }

if ($missing) {
  Write-Host "The following packages are missing:`n  $($missing -join ", ")"
  $choice = Read-Host "1=Install missing; 2=Skip; 3=Add missing to machine list and skip"
  switch ($choice) {
    '1' {
      foreach ($pkg in $missing) {
        if ($masterList -contains $pkg) { winget install --id $pkg -e -h } 
        elseif (Test-Path 'C:\cygwin64\setup-x86_64.exe') { & 'C:\cygwin64\setup-x86_64.exe' -q -P $pkg }
        else { choco install $pkg -y }
      }
    }
    '3' {
      Add-Content $machine $missing
      Write-Host "Appended missing to $machine"
    }
    default { Write-Host "Skipping install." }
  }
} else {
  Write-Host "All desired packages are already installed."
}

