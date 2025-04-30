# Module-Loader.psm1 — track real imports, defer summary

if (-not $global:ModuleImportedModuleLoader) {
    $global:ModuleImportedModuleLoader = $true
} else {
    Write-Debug -Message "Attempting to import module twice!" `
                -Channel "Error" -Condition $DebugProfile -FileAndLine
    return
}

# Define custom failure actions for specific modules
$script:FailureActions = @{
    "WriteDebug" = {
        function Write-Debug {
            param (
                [string] $Message = "",
                [string] $Channel = "",
                [AllowNull()][object] $Condition = $null
            )
            if (-not $DebugProfile) { return }
            Write-Host "[Fallback $Channel] $Message" -ForegroundColor Gray
        }
    }
    "ls-aliases" = {
        Write-Warning "Custom action: ls-aliases failed to load. Check if it's installed correctly."
    }
}

# Tracking collections
$script:ModuleLoadFailures = @()
$script:ModuleLoadStats    = @{}

function script:Initialize-Module {
    param (
        [string] $ModuleName,
        [string] $ModulePath
    )

    try {
        if ($DebugProfile) {
            Import-Module -Name $ModulePath -ErrorAction Stop -Verbose
        } else {
            Import-Module -Name $ModulePath -ErrorAction Stop
        }

        # Count exports
        $mod = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
        if ($mod) {
            $exports    = $mod.ExportedCommands.Values
            $funcCount  = ($exports | Where-Object CommandType -eq 'Function').Count
            $aliasCount = ($exports | Where-Object CommandType -eq 'Alias').Count
            $script:ModuleLoadStats[$ModuleName] = @{
                Functions = $funcCount
                Aliases   = $aliasCount
            }
        }

        Write-Debug -Message "Imported '${ModuleName}': $funcCount functions, $aliasCount aliases" `
                    -Channel "Debug" -Condition $DebugProfile
    }
    catch {
        Write-Debug -Message "ModuleLoader: Failed import of ${ModuleName}: $($_.Exception.Message)" `
                    -Channel "Error" -Condition $DebugProfile -FileAndLine

        if ($script:FailureActions.ContainsKey($ModuleName)) {
            & $script:FailureActions[$ModuleName]
        }
        $script:ModuleLoadFailures += $ModuleName
    }
}

# Discover modules to load (skip this loader and DebugUtils)
$currentName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
$allModules  = Get-ChildItem -Path $Global:ProfileModulesPath -Filter '*.psm1' |
               Where-Object { $_.BaseName -notin $currentName, 'DebugUtils' }

# Load ordered modules first
foreach ($name in $OrderedModules) {
    $m = $allModules | Where-Object { $_.BaseName -eq $name }
    if ($m) {
        Initialize-Module -ModuleName $m.BaseName -ModulePath $m.FullName
    } else {
        Write-Debug -Message "Ordered module '$name' not found." -Channel "Warning" -Condition $DebugProfile
    }
}

# Then load the rest
foreach ($m in $allModules | Where-Object { $OrderedModules -notcontains $_.BaseName }) {
    Initialize-Module -ModuleName $m.BaseName -ModulePath $m.FullName
}

# Summary function — invoke at the very end of your profile
function Show-ModuleLoaderSummary {
    Write-Host "Module Load Summary:" -ForegroundColor Cyan
    foreach ($entry in $script:ModuleLoadStats.GetEnumerator() | Sort-Object Name) {
        $n = $entry.Key
        $s = $entry.Value
        Write-Host " - $n: $($s.Functions) functions, $($s.Aliases) aliases"
    }
    if ($script:ModuleLoadFailures.Count -gt 0) {
        Write-Host "`nModules Failed to Load:" -ForegroundColor Yellow
        foreach ($fail in $script:ModuleLoadFailures) {
            Write-Host " - $fail" -ForegroundColor Red
        }
    }
}

Export-ModuleMember -Function Show-ModuleLoaderSummary
