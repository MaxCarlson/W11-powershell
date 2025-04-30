# ModuleLoader.psm1 — real import errors, clean summary

# Prevent double-import
if (-not $global:ModuleLoaderImported) {
    $global:ModuleLoaderImported = $true
} else {
    return
}

# Tracking
$script:ModuleLoadFailures = @()
$script:ModuleLoadStats    = @{}

function Initialize-Module {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Path
    )
    try {
        # load by file-path
        Import-Module $Path -ErrorAction Stop

        # count exported functions & aliases
        $mod = Get-Module $Name -ErrorAction SilentlyContinue
        if ($mod) {
            $exports    = $mod.ExportedCommands.Values
            $funcCount  = ($exports | Where CommandType -eq 'Function').Count
            $aliasCount = ($exports | Where CommandType -eq 'Alias').Count
            $script:ModuleLoadStats[$Name] = @{Functions=$funcCount;Aliases=$aliasCount}
        }
    }
    catch {
        # show the *actual* import error
        Write-Host "Error loading module '$Name': $($_.Exception.Message)" -ForegroundColor Red
        $script:ModuleLoadFailures += $Name
    }
}

# find all .psm1 except self & DebugUtils
$current = [IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
$all     = Get-ChildItem $Global:ProfileModulesPath -Filter '*.psm1' |
           Where-Object { $_.BaseName -notin $current,'DebugUtils' }

# load each
foreach ($file in $all) {
    Initialize-Module -Name $file.BaseName -Path $file.FullName
}

# public summary function
function Show-ModuleLoaderSummary {
    Write-Host "Module Load Summary:" -ForegroundColor Cyan
    foreach ($e in $script:ModuleLoadStats.GetEnumerator() | Sort Name) {
        Write-Host " - $($e.Key): $($e.Value.Functions) functions, $($e.Value.Aliases) aliases"
    }
    if ($script:ModuleLoadFailures.Count) {
        Write-Host "`nModules Failed to Load:" -ForegroundColor Yellow
        $script:ModuleLoadFailures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    }
}

Export-ModuleMember -Function Show-ModuleLoaderSummary
