<#
.SYNOPSIS
    Exports installed-package lists for Winget, Chocolatey, Cygwin, Cargo, and PowerShell Modules.
.DESCRIPTION
    - Winget: Uses `winget export` to get a JSON list of packages known to Winget sources.
    - Chocolatey: `choco list --local-only`
    - Cygwin: parses `C:\cygwin64\etc\setup\installed.db`
    - Cargo: `cargo install --list`
    - PowerShell Modules: `Get-InstalledModule`
    Outputs packages in 'manager:PackageName' format to a machine-specific file.
    Optionally, can add newly discovered packages to the master package list.
.PARAMETER OutputDirBase
    Base folder where machine-specific output folders will be created.
    Defaults to '<PSScriptRoot>\InstalledPackages'.
.PARAMETER MachineName
    The name of the machine, used for the output subfolder. Defaults to $env:COMPUTERNAME.
.PARAMETER OutputFileName
    The name of the consolidated output file within the machine-specific folder.
    Defaults to 'current_installed_on_this_machine.packages.txt'.
.PARAMETER AddToMasterList
    If specified, any packages found on this machine that are not in the master list
    (Setup/InstalledPackages/Lists/master.packages.txt) will be appended to it.
.PARAMETER MasterListPath
    The path to the master package list.
    Defaults to '<PSScriptRoot>\InstalledPackages\Lists\master.packages.txt'.
#>
[CmdletBinding()]
param(
    [string]$OutputDirBase = (Join-Path $PSScriptRoot "InstalledPackages"),
    [string]$MachineName = $env:COMPUTERNAME,
    [string]$OutputFileName = "current_installed_on_this_machine.packages.txt",
    [switch]$AddToMasterList,
    [string]$MasterListPath = (Join-Path $PSScriptRoot "InstalledPackages" "Lists" "master.packages.txt")
)

# 1) Ensure the machine-specific output directory exists
$machineOutputDir = Join-Path -Path $OutputDirBase -ChildPath $MachineName
if (-not (Test-Path $machineOutputDir)) {
    Write-Host "Creating machine-specific output directory: $machineOutputDir"
    New-Item -ItemType Directory -Path $machineOutputDir -Force | Out-Null
}

$allPackagesOnThisMachine = [System.Collections.Generic.List[string]]::new()

# Helper function to safely add to list
function Add-PackagesToListLocal {
    param(
        [System.Collections.Generic.List[string]]$TargetList, 
        [string[]]$PackagesToAdd, 
        [string]$ManagerName
    )
    if ($null -ne $PackagesToAdd -and $PackagesToAdd.Length -gt 0) {
        $TargetList.AddRange($PackagesToAdd)
        Write-Host "Found $($PackagesToAdd.Length) $ManagerName packages on this machine."
    } else {
        Write-Host "No $ManagerName packages found or exported on this machine."
    }
}

# --- Start of Winget Section (USING winget export) ---
Write-Host "Exporting Winget packages using 'winget export'..."
[string[]]$wingetPackages = @() 
$tempWingetExportFile = Join-Path $machineOutputDir "winget_export_temp.json" # Place temp file in machine-specific dir
$stdErrLogPath = Join-Path $machineOutputDir "winget_export_stderr.log"
try {
    # Ensure any previous temp files are removed
    Remove-Item $tempWingetExportFile -ErrorAction SilentlyContinue
    Remove-Item $stdErrLogPath -ErrorAction SilentlyContinue

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "winget.exe"
    $psi.Arguments = "export -o `"$tempWingetExportFile`"" # Ensure path is quoted
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $false 
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    
    $process = [System.Diagnostics.Process]::Start($psi)
    $stdErrOutput = $process.StandardError.ReadToEnd() 
    $process.WaitForExit()

    if ($stdErrOutput) {
        $stdErrOutput | Out-File -FilePath $stdErrLogPath -Encoding utf8 -Append # Append in case of multiple calls or retries
        Write-Warning "Winget export process reported messages to stderr (see $stdErrLogPath for full details):"
        $stdErrOutput -split [System.Environment]::NewLine | Where-Object { $_.Trim() -ne "" } | Select-Object -First 5 | ForEach-Object { Write-Warning "  $_" }
    }
    
    if ($process.ExitCode -ne 0 -and -not (Test-Path $tempWingetExportFile) ) {
         Write-Warning "Winget export process failed with exit code $($process.ExitCode) and did not create the export file '$tempWingetExportFile'."
    } elseif (Test-Path $tempWingetExportFile) {
        $jsonString = Get-Content -Path $tempWingetExportFile -Raw -ErrorAction SilentlyContinue
        if ($jsonString) {
            $jsonContent = $jsonString | ConvertFrom-Json -ErrorAction Stop
            $parsedWingetPackagesList = [System.Collections.Generic.List[string]]::new() 
            if ($jsonContent.Sources) {
                foreach ($sourceEntry in $jsonContent.Sources) { 
                    if ($sourceEntry.Packages) {
                        foreach ($package in $sourceEntry.Packages) {
                            if ($package.PackageIdentifier) {
                                $parsedWingetPackagesList.Add("winget:$($package.PackageIdentifier)")
                            }
                        }
                    }
                }
            }
            $wingetPackages = $parsedWingetPackagesList.ToArray() | Sort-Object -Unique
        } else {
            Write-Warning "Winget export JSON file '$tempWingetExportFile' was empty or could not be read."
        }
        Remove-Item $tempWingetExportFile -ErrorAction SilentlyContinue 
    } else {
        Write-Warning "Winget export did not produce the expected JSON file: $tempWingetExportFile, but process exit code was $($process.ExitCode)."
    }
} catch {
    Write-Warning "Failed to export or parse Winget packages using 'winget export': $_"
} finally { # Ensure temp files are cleaned up even if an exception occurs mid-try
    if (Test-Path $tempWingetExportFile) { Remove-Item $tempWingetExportFile -ErrorAction SilentlyContinue }
    # Optionally keep stderr log for debugging: if (Test-Path $stdErrLogPath) { Remove-Item $stdErrLogPath -ErrorAction SilentlyContinue }
}
Add-PackagesToListLocal -TargetList $allPackagesOnThisMachine -PackagesToAdd $wingetPackages -ManagerName "Winget (from export)"
# --- End of Winget Section ---


# 3) Chocolatey
Write-Host "Exporting Chocolatey packages..."
[string[]]$chocoPackages = @()
try {
    $parsedChocoPackages = choco list --local-only --limit-output --exact |
      ForEach-Object {
        $name = ($_ -split '\|')[0].Trim()
        if ($name) { "choco:$name" }
      }
    $chocoPackages = @($parsedChocoPackages | Where-Object { $_ -is [string] -and $_.Trim() -ne "" })
} catch {
    Write-Warning "Failed to export Chocolatey packages: $_"
}
Add-PackagesToListLocal -TargetList $allPackagesOnThisMachine -PackagesToAdd $chocoPackages -ManagerName "Chocolatey"

# 4) Cygwin
Write-Host "Exporting Cygwin packages..."
[string[]]$cygwinPackages = @()
$cygwinInstalledDb = 'C:\cygwin64\etc\setup\installed.db'
if (Test-Path $cygwinInstalledDb) {
    try {
        $parsedCygwinPackages = Get-Content $cygwinInstalledDb |
          Where-Object { $_ -and -not ($_.StartsWith('#')) } |
          ForEach-Object {
            $lineParts = ($_ -split "`t")
            $nameAndVersionPlus = $lineParts[0].Trim()
            $pkgNameOnly = ($nameAndVersionPlus -split " ")[0].Trim() 
            if ($pkgNameOnly) { "cygwin:$pkgNameOnly" }
          }
        $cygwinPackages = @($parsedCygwinPackages | Where-Object { $_ -is [string] -and $_.Trim() -ne "" } | Sort-Object -Unique)
    } catch {
        Write-Warning "Failed to parse Cygwin installed.db: $_"
    }
} else {
    Write-Host "Cygwin installed.db not found at $cygwinInstalledDb. Skipping Cygwin export."
}
Add-PackagesToListLocal -TargetList $allPackagesOnThisMachine -PackagesToAdd $cygwinPackages -ManagerName "Cygwin"

# 5) Rust (Cargo)
Write-Host "Exporting Cargo packages..."
[string[]]$cargoPackages = @()
if (Get-Command cargo -ErrorAction SilentlyContinue) {
    try {
        $cargoOutput = cargo install --list
        $tempCargoList = [System.Collections.Generic.List[string]]::new()
        foreach ($line_cargo in ($cargoOutput -split [System.Environment]::NewLine)) {
            if ($line_cargo -match '^(\S+)\s+v[0-9]+\.[0-9]+\.[0-9]+.*:$') {
                $tempCargoList.Add("cargo:$($Matches[1].Trim())")
            }
        }
        $cargoPackages = $tempCargoList.ToArray() 
    } catch {
        Write-Warning "Failed to list cargo packages: $_"
    }
} else {
    Write-Host "Cargo not found. Skipping cargo package export."
}
Add-PackagesToListLocal -TargetList $allPackagesOnThisMachine -PackagesToAdd $cargoPackages -ManagerName "Cargo"

# 6) PowerShell Modules (user-installed from PSGallery)
Write-Host "Exporting PowerShell modules..."
[string[]]$psModules = @()
try {
    $parsedPsModules = Get-InstalledModule -ErrorAction SilentlyContinue | ForEach-Object { "psmodule:$($_.Name)" }
    $psModules = @($parsedPsModules | Where-Object { $_ -is [string] -and $_.Trim() -ne "" } | Sort-Object -Unique)
} catch {
    Write-Warning "Failed to list PowerShell modules: $_"
}
Add-PackagesToListLocal -TargetList $allPackagesOnThisMachine -PackagesToAdd $psModules -ManagerName "PowerShell module"

# Save machine-specific list
$machineSpecificFile = Join-Path $machineOutputDir $OutputFileName
$allPackagesOnThisMachineSorted = $allPackagesOnThisMachine.ToArray() | Sort-Object -Unique
$allPackagesOnThisMachineSorted | Set-Content -Path $machineSpecificFile -Force
Write-Host "All packages for machine '$MachineName' consolidated into: $machineSpecificFile"

# 7) Optionally add to master list
if ($AddToMasterList) {
    Write-Host "Comparing machine list with master list: $MasterListPath"
    if (-not (Test-Path $MasterListPath)) {
        Write-Warning "Master list file not found at '$MasterListPath'. Cannot add new packages. Creating an empty one."
        New-Item -Path $MasterListPath -ItemType File -Force | Out-Null
    }

    $currentMasterPackages = Get-Content $MasterListPath -ErrorAction SilentlyContinue | Where-Object { $_.Trim() -ne "" } | Sort-Object -Unique
    $newPackagesForMaster = $allPackagesOnThisMachineSorted | Where-Object { $pkg = $_; $currentMasterPackages -notcontains $pkg }

    if ($newPackagesForMaster.Count -gt 0) {
        Write-Host "Adding the following $($newPackagesForMaster.Count) new packages to master list:" -ForegroundColor Cyan
        $newPackagesForMaster | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }
        Add-Content -Path $MasterListPath -Value $newPackagesForMaster
        (Get-Content $MasterListPath | Sort-Object -Unique) | Set-Content -Path $MasterListPath
        Write-Host "Master list updated: $MasterListPath" -ForegroundColor Green
    } else {
        Write-Host "No new packages from this machine to add to the master list."
    }
}

Write-Host "Package export process finished."
