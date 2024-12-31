param (
    [Parameter(Mandatory = $true)]
    [string[]]$ModulePaths,  # Array of paths to the modules to reload

    [switch]$Force           # Optional flag to force re-import
)

# Import the Coloring module
Import-Module "$PSScriptRoot/Coloring.psm1"

function Reload-Module {
    param (
        [string]$Path,
        [switch]$Force
    )

    # Resolve module name from the path
    $ResolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
    if (-not $ResolvedPath) {
        Write-Color -Message "Module path '$Path' does not exist." -Color Red
        return
    }

    $ModuleName = (Get-Module -ListAvailable | Where-Object { $_.Path -eq $ResolvedPath }).Name
    if (-not $ModuleName) {
        $ModuleName = Split-Path -Leaf $ResolvedPath
        $ModuleName = $ModuleName -replace '\.psm1$', ''
    }

    # Step 1: Check if the module is already loaded
    $LoadedModule = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
    if ($LoadedModule) {
        Write-Color -Message "Module '$ModuleName' is already loaded. Removing it..." -Color Yellow
        Remove-Module -Name $ModuleName -Force
        Write-Color -Message "Module '$ModuleName' removed successfully." -Color Green
    } else {
        Write-Color -Message "Module '$ModuleName' is not currently loaded." -Color White
    }

    # Step 2: Re-import the module
    Write-Color -Message "Re-importing module from path: $ResolvedPath" -Color Yellow
    try {
        if ($Force) {
            Import-Module -Name $ResolvedPath -Force -Verbose
        } else {
            Import-Module -Name $ResolvedPath -Verbose
        }
        Write-Color -Message "Module '$ModuleName' re-imported successfully." -Color Green
    } catch {
        Write-Color -Message "Failed to import module '$ModuleName': $_" -Color Red
        return
    }

    # Step 3: Validate the module
    Write-Color -Message "Validating exported commands for module '$ModuleName'..." -Color Yellow
    $ExportedCommands = Get-Command -Module $ModuleName
    if ($ExportedCommands) {
        Write-Color -Message "Exported commands:" -Color Green
        $ExportedCommands | Format-Table -Property Name, CommandType -AutoSize
    } else {
        Write-Color -Message "No commands were exported from module '$ModuleName'." -Color Red
    }
}

# Main logic: Process all modules
foreach ($ModulePath in $ModulePaths) {
    Write-Color -Message "Processing module: $ModulePath" -Color Cyan
    Reload-Module -Path $ModulePath -Force:$Force
    Write-Color -Message "----------------------------------------" -Color White
}

