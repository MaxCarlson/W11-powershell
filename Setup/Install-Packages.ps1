<#
.SYNOPSIS
  Installs any missing packages from master + machine-override lists, or shows what would be done.
.DESCRIPTION
  - Reads Setup/InstalledPackages/Lists/master.packages.txt
  - Reads Setup/InstalledPackages/Lists/machine.$env:COMPUTERNAME.packages.txt (if exists)
  - Merges them (dedup), then installs missing packages via Winget, Chocolatey, Cygwin, Cargo, PowerShell Get, or Mamba env.
.PARAMETER DryRun
  If specified, the script will only report what actions it would take without actually installing anything.
#>
[CmdletBinding(SupportsShouldProcess=$true)] # SupportsShouldProcess enables -WhatIf, which is similar to a dry run for cmdlets that support it. We'll do custom dry run for logic.
param(
    [switch]$DryRun
)

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$listsDir = Join-Path $PSScriptRoot "InstalledPackages" "Lists" # Corrected path
$masterFile = Join-Path $listsDir 'master.packages.txt'
$machineFile = Join-Path $listsDir "machine.$($env:COMPUTERNAME).packages.txt"

if ($DryRun) {
    Write-Host "--- DRY RUN MODE ENABLED --- No changes will be made." -ForegroundColor Magenta
}

# 1) Load desired package lists
if (-not (Test-Path $masterFile)) {
    Write-Warning "Master package list not found: $masterFile. Cannot proceed."
    return
}
$masterList  = Get-Content $masterFile -ErrorAction SilentlyContinue | Where-Object { $_ -match "^\w+:.+" -and $_ -notmatch "^\s*#" }
$machineList = if (Test-Path $machineFile) { Get-Content $machineFile -ErrorAction SilentlyContinue | Where-Object { $_ -match "^\w+:.+" -and $_ -notmatch "^\s*#" } } else { @() }

$desiredPackagesAndEnvs = ($masterList + $machineList) | Sort-Object -Unique

if ($desiredPackagesAndEnvs.Count -eq 0) {
    Write-Host "No desired packages or environment definitions found in lists."
    return
}
Write-Host "Total unique desired packages/env definitions: $($desiredPackagesAndEnvs.Count)"

# 2) Detect what's currently installed or Mamba envs defined
$installedOrDefinedItems = [System.Collections.Generic.List[string]]::new()
$exportScriptPath = Join-Path $PSScriptRoot "Export-InstalledPackages.ps1"
$machineSpecificInstalledFileDir = Join-Path $PSScriptRoot "InstalledPackages" $env:COMPUTERNAME
$machineSpecificInstalledFile = Join-Path $machineSpecificInstalledFileDir "current_installed_on_this_machine.packages.txt"

if (Test-Path $exportScriptPath) {
    Write-Host "Detecting installed packages by running Export-InstalledPackages.ps1 for this machine ($env:COMPUTERNAME)..."
    try {
        & $exportScriptPath -MachineName $env:COMPUTERNAME -OutputFileName "current_installed_on_this_machine.packages.txt" -ErrorAction Stop
        if (Test-Path $machineSpecificInstalledFile) {
            $installedOrDefinedItems.AddRange((Get-Content $machineSpecificInstalledFile | Where-Object { $_.Trim() -ne "" }))
        } else {
            Write-Warning "Export-InstalledPackages.ps1 did not produce the expected output file: $machineSpecificInstalledFile"
        }
    } catch {
        Write-Warning "Error running Export-InstalledPackages.ps1: $_."
    }
} else {
    Write-Warning "Export-InstalledPackages.ps1 not found at $exportScriptPath."
}

if (Get-Command mamba -ErrorAction SilentlyContinue) {
    try {
        $mambaEnvListJson = mamba env list --json
        $mambaEnvList = $mambaEnvListJson | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($mambaEnvList -and $mambaEnvList.envs) {
            $definedMambaEnvs = $mambaEnvList.envs | ForEach-Object { "mamba_env_name:" + ($_ -split '[/\\]')[-1] } 
            $installedOrDefinedItems.AddRange($definedMambaEnvs)
        }
    } catch { Write-Warning "Could not list mamba environments: $_" }
}
$uniqueInstalledOrDefined = $installedOrDefinedItems | Sort-Object -Unique
Write-Host "Currently detected installed packages & defined Mamba env names on this machine: $($uniqueInstalledOrDefined.Count)"

# 3) Determine actions for each desired item (install, update, already present)
Write-Host "`n--- Package & Environment Status ---"
$actionsToPerform = [System.Collections.Generic.List[hashtable]]::new() # Store items to actually install if not DryRun

foreach ($desiredEntry in $desiredPackagesAndEnvs) {
    $isMissing = $true # Assume missing initially
    $statusColor = "Green"
    $actionMessage = "Would install/create"

    if ($desiredEntry -match "^mamba_env:(.+)") {
        $envFileRelativePath = $Matches[1]
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
        $envFileFullPathForCheck = Join-Path $repoRoot $envFileRelativePath
        
        if (-not (Test-Path $envFileFullPathForCheck)) {
            Write-Host "$desiredEntry (Mamba Env YML MISSING: $envFileFullPathForCheck)" -ForegroundColor Red
            continue # Skip this desired entry
        }
        $expectedEnvName = (Get-Item $envFileFullPathForCheck).BaseName -replace '\.environment$', ''
        
        if ($uniqueInstalledOrDefined -contains "mamba_env_name:$expectedEnvName") {
            $isMissing = $false
            $statusColor = "Yellow"
            $actionMessage = "Mamba env '$expectedEnvName' already defined. Would update (if different from YML)."
        } else {
            $actionMessage = "Mamba env '$expectedEnvName' not found. Would create from $envFileRelativePath."
        }
    } elseif ($uniqueInstalledOrDefined -contains $desiredEntry) {
        $isMissing = $false
        $statusColor = "Yellow"
        $actionMessage = "Already installed/defined."
    } else {
        # Workaround for Mambaforge not being listed by `winget list`
        if ($desiredEntry -eq "winget:CondaForge.Mambaforge" -and (Test-Path "$env:USERPROFILE\mambaforge\condabin\mamba.bat")) {
            $isMissing = $false
            $statusColor = "DarkYellow" # Special color for this workaround case
            $actionMessage = "Physically found (Mambaforge workaround), considered installed."
        } else {
            $actionMessage = "Not found. Would install."
        }
    }

    Write-Host "$desiredEntry : $actionMessage" -ForegroundColor $statusColor
    if ($isMissing) {
        $actionsToPerform.Add(@{ Entry = $desiredEntry; Action = "Install" })
    }
}

# If DryRun, stop here after reporting
if ($DryRun) {
    Write-Host "`n--- DRY RUN FINISHED ---" -ForegroundColor Magenta
    if ($actionsToPerform.Count -eq 0) {
        Write-Host "No actions would be performed." -ForegroundColor Green
    }
    return
}

# If not DryRun, and there are actions, proceed with installations
if ($actionsToPerform.Count -eq 0) {
    Write-Host "`nAll desired packages/environments are already installed/defined on this machine."
    return
}

Write-Host "`n--- PERFORMING INSTALLATIONS/ENVIRONMENT SETUP ---"
$groupedActions = $actionsToPerform.Entry | Group-Object { ($_ -split ':', 2)[0].ToLower() }

foreach ($group in $groupedActions) {
    $manager = $group.Name
    $packageIdentifiers = $group.Group | ForEach-Object { ($_ -split ':', 2)[1] } 

    Write-Host "`nProcessing entries for manager: $manager"
    switch ($manager) {
        'winget' {
            foreach ($pkgId in $packageIdentifiers) {
                Write-Host "  Installing winget package: $pkgId"
                try {
                    winget install --id $pkgId -e -h --accept-package-agreements --accept-source-agreements --disable-interactivity
                } catch { Write-Error "    Winget install for $pkgId failed: $_" }
            }
        }
        'choco' {
            foreach ($pkgName in $packageIdentifiers) {
                Write-Host "  Installing choco package: $pkgName"
                try {
                    choco install $pkgName -y
                } catch { Write-Error "    Choco install for $pkgName failed: $_" }
            }
        }
        'cygwin' {
            $cygwinSetupExe = 'C:\cygwin64\setup-x86_64.exe'
            if (Test-Path $cygwinSetupExe) {
                $packageListString = $packageIdentifiers -join ',' 
                Write-Host "  Installing Cygwin packages: $packageListString"
                try {
                    Start-Process -FilePath $cygwinSetupExe -ArgumentList "-q -P $packageListString" -Wait -NoNewWindow
                    Write-Host "  Cygwin setup process completed for: $packageListString"
                } catch { Write-Error "    Cygwin install for ($packageListString) failed: $_" }
            } else {
                Write-Warning "  Cygwin setup.exe not found. Cannot install: $($packageIdentifiers -join ', ')"
            }
        }
        'cargo' {
            if (Get-Command cargo -ErrorAction SilentlyContinue) {
                foreach ($crateName in $packageIdentifiers) {
                    Write-Host "  Installing cargo crate: $crateName"
                    try {
                        cargo install $crateName
                    } catch { Write-Error "    Cargo install for $crateName failed: $_" }
                }
            } else {
                Write-Warning "  Cargo command not found. Ensure Rust is installed. Skipping: $($packageIdentifiers -join ', ')"
            }
        }
        'psmodule' {
            foreach ($moduleName in $packageIdentifiers) {
                Write-Host "  Installing PowerShell module: $moduleName"
                try {
                    Install-Module $moduleName -Scope CurrentUser -Force -Confirm:$false -AcceptLicense -ErrorAction Stop
                } catch { Write-Error "    Install-Module for $moduleName failed: $_" }
            }
        }
        'mamba_env' {
            if (Get-Command mamba -ErrorAction SilentlyContinue) {
                foreach ($envFileRelativePathFromRepoRoot in $packageIdentifiers) { 
                    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path 
                    $envFileFullPath = Join-Path $repoRoot $envFileRelativePathFromRepoRoot
                    
                    if (Test-Path $envFileFullPath) {
                        $envName = (Get-Item $envFileFullPath).BaseName -replace '\.environment$', '' 
                        Write-Host "  Updating/creating Mamba environment '$envName' from $envFileFullPath"
                        try {
                            # Re-check if env exists before create/update logic
                            $envListJson = mamba env list --json
                            $envList = $envListJson | ConvertFrom-Json -ErrorAction SilentlyContinue
                            $existingEnvPath = $null
                            if ($envList -and $envList.envs) {
                               $existingEnvPath = ($envList.envs | Where-Object { ($_ -split '[/\\]')[-1] -eq $envName } | Select-Object -First 1)
                            }

                            if ($existingEnvPath) {
                                Write-Host "    Environment '$envName' exists. Updating with --prune..."
                                mamba env update --name $envName --file $envFileFullPath --prune 
                            } else {
                                Write-Host "    Environment '$envName' does not exist. Creating..."
                                mamba env create --name $envName --file $envFileFullPath
                            }
                        } catch {
                            Write-Error "    Mamba env operation for '$envName' using $envFileFullPath failed: $_"
                        }
                    } else {
                        Write-Warning "  Mamba environment file not found: $envFileFullPath for entry '$envFileRelativePathFromRepoRoot'"
                    }
                }
            } else {
                Write-Warning "  Mamba command not found. Ensure Mambaforge is installed and shell initialized. Skipping Mamba env setup."
            }
        }
        default {
            Write-Warning "  Unknown package manager '$manager' for package identifiers: $($packageIdentifiers -join ', ')"
        }
    }
}

Write-Host "`nPackage installation/environment setup process finished."
