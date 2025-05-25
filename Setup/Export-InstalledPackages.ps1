<#
.SYNOPSIS
    Exports installed-package lists for Winget, Chocolatey, Cygwin, and Cargo.
.DESCRIPTION
    - Winget: `winget list --source winget`
    - Chocolatey: `choco list --local-only`
    - Cygwin: parses `C:\cygwin64\etc\setup\installed.db`
    - Cargo: `cargo install --list`
    - PowerShell Modules: `Get-InstalledModule`
    Outputs packages in 'manager:PackageName' format.
.PARAMETER OutputDir
    Folder where the lists will be written. Defaults to `<PSScriptRoot>\InstalledPackages`.
.PARAMETER OutputFile
    The name of the consolidated output file. Defaults to 'current_installed.packages.txt'.
#>
param(
    [string]$OutputDir = (Join-Path $PSScriptRoot "InstalledPackages"),
    [string]$OutputFile = "current_installed.packages.txt"
)

# 1) Ensure the output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$allPackages = [System.Collections.Generic.List[string]]::new()

# Helper function to safely add to $allPackages
function Add-PackagesToList {
    param(
        # Ensure the input is treated as a collection of strings
        [string[]]$PackagesToAdd,
        [string]$ManagerName
    )
    if ($null -ne $PackagesToAdd -and $PackagesToAdd.Length -gt 0) {
        # $allPackages is already List<string>, AddRange expects IEnumerable<string>
        # A [string[]] is an IEnumerable<string>
        $allPackages.AddRange($PackagesToAdd)
        Write-Host "Found $($PackagesToAdd.Length) $ManagerName packages."
    } else {
        Write-Host "No $ManagerName packages found or exported."
    }
}

# 2) Winget
Write-Host "Exporting Winget packages..."
[string[]]$wingetPackages = @() # Explicitly type as string array
try {
    $wingetOutputLines = winget list --source winget --accept-source-agreements | Select-Object -Skip 2
    
    $parsedWingetPackages = foreach ($line in $wingetOutputLines) {
        $trimmedLine = $line.Trim()
        if ($trimmedLine) {
            $columns = $trimmedLine -split '\s{2,}' | Where-Object { $_.Trim() -ne "" }
            if ($columns.Count -ge 2) {
                $id = $columns[1].Trim() 
                if ($id) { "winget:$id" }
            }
        }
    }
    # Ensure $parsedWingetPackages is an array of strings
    $wingetPackages = @($parsedWingetPackages | Where-Object { $_ -is [string] -and $_.Trim() -ne "" })
} catch {
    Write-Warning "Failed to export Winget packages: $_"
}
Add-PackagesToList -PackagesToAdd $wingetPackages -ManagerName "Winget"

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
Add-PackagesToList -PackagesToAdd $chocoPackages -ManagerName "Chocolatey"

# 4) Cygwin
Write-Host "Exporting Cygwin packages..."
[string[]]$cygwinPackages = @()
$cygwinInstalledDb = 'C:\cygwin64\etc\setup\installed.db'
if (Test-Path $cygwinInstalledDb) {
    try {
        $parsedCygwinPackages = Get-Content $cygwinInstalledDb |
          Where-Object { $_ -and -not ($_.StartsWith('#')) } |
          ForEach-Object {
            $name = ($_ -split "`t")[0].Trim()
            if ($name) { "cygwin:$name" }
          }
        $cygwinPackages = @($parsedCygwinPackages | Where-Object { $_ -is [string] -and $_.Trim() -ne "" } | Sort-Object -Unique)
    } catch {
        Write-Warning "Failed to parse Cygwin installed.db: $_"
    }
} else {
    Write-Host "Cygwin installed.db not found at $cygwinInstalledDb. Skipping Cygwin export."
}
Add-PackagesToList -PackagesToAdd $cygwinPackages -ManagerName "Cygwin"

# 5) Rust (Cargo)
Write-Host "Exporting Cargo packages..."
[string[]]$cargoPackages = @()
if (Get-Command cargo -ErrorAction SilentlyContinue) {
    try {
        $cargoOutput = cargo install --list
        # Use a temporary List<string> for parsing as it's efficient for adding one by one
        $tempCargoList = [System.Collections.Generic.List[string]]::new()
        foreach ($line_cargo in ($cargoOutput -split [System.Environment]::NewLine)) {
            if ($line_cargo -match '^(\S+)\s+v[0-9]+\.[0-9]+\.[0-9]+.*:$') {
                $tempCargoList.Add("cargo:$($Matches[1].Trim())")
            }
        }
        $cargoPackages = $tempCargoList.ToArray() # Convert List<string> to string[]
    } catch {
        Write-Warning "Failed to list cargo packages: $_"
    }
} else {
    Write-Host "Cargo not found. Skipping cargo package export."
}
Add-PackagesToList -PackagesToAdd $cargoPackages -ManagerName "Cargo"

# 6) PowerShell Modules (user-installed from PSGallery)
Write-Host "Exporting PowerShell modules..."
[string[]]$psModules = @()
try {
    $parsedPsModules = Get-InstalledModule -ErrorAction SilentlyContinue | ForEach-Object { "psmodule:$($_.Name)" }
    $psModules = @($parsedPsModules | Where-Object { $_ -is [string] -and $_.Trim() -ne "" } | Sort-Object -Unique)
} catch {
    Write-Warning "Failed to list PowerShell modules: $_"
}
Add-PackagesToList -PackagesToAdd $psModules -ManagerName "PowerShell module"

# Consolidate and Save
$finalOutputFile = Join-Path $OutputDir $OutputFile
# Ensure $allPackages (List<string>) is converted to string[] for Set-Content if it matters, though Set-Content is usually flexible
Set-Content -Path $finalOutputFile -Value ($allPackages.ToArray() | Sort-Object -Unique) -Force
Write-Host "All package lists consolidated into: $finalOutputFile"
