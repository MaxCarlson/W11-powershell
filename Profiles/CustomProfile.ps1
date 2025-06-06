# Profile for Current User & Current Host
Write-Host "`nProfile script execution started."

# --- Profile Load Guard ---
if ($global:ProfileLoaded) {
    Write-Host "Profile already loaded (skipped execution)."
    return
}
$global:ProfileLoaded = $true
Write-Host "ProfileLoaded flag is being set."

# --- Initial Setup & Configuration ---
$global:SessionStartTime = Get-Date
# Toggle verbose debug output here
$global:DebugProfile = $false

# --- Base Paths ---
$global:PWSH_REPO = "$env:USERPROFILE\Repos\W11-powershell"
if (-not (Test-Path $global:PWSH_REPO -PathType Container)) {
    Write-Warning "Repository path not found: $($global:PWSH_REPO)"
}
$Global:ProfileRepoPath    = $global:PWSH_REPO
$Global:ProfileModulesPath = Join-Path $Global:ProfileRepoPath 'Config\Modules'
if (-not (Test-Path $Global:ProfileModulesPath -PathType Container)) {
    Write-Error "Module directory not found: '$($Global:ProfileModulesPath)'. Cannot load custom modules."
    return
}

# --- Global Variables ---
$global:OBSIDIAN = 'C:\Users\mcarls\Documents\Obsidian-Vault\'
$global:SCRIPTS  = 'C:\Projects\W11-powershell\'

# --- Utility Functions Defined in Profile ---
function global:Reload-Profile {
    Write-Warning "Attempting profile reload ($PROFILE). Close/reopen shell recommended."
    $global:ProfileLoaded = $false
    . $PROFILE
}

function script:Write-Debug {
    param(
        [string]$Message = '',
        [ValidateSet('Error','Warning','Verbose','Information','Debug')][string]$Channel = 'Debug',
        [AllowNull()][object]$Condition = $true,
        [switch]$FileAndLine
    )
    if (-not $global:DebugProfile) { return }
    try {
        if ($Condition -and -not [bool]$Condition) { return }
    } catch {
        Write-Warning "[Profile Write-Debug] Invalid Condition: '$Condition'"
        return
    }

    $output = $Message
    if ($FileAndLine) {
        $c = Get-PSCallStack | Select-Object -Skip 1 -First 1
        if ($c.ScriptName) {
            $f = Split-Path $c.ScriptName -Leaf
            $l = $c.ScriptLineNumber
            $output = "[${f}:${l}] $Message"
        }
    }

    $colorMap = @{
        Error       = 'Red'
        Warning     = 'Yellow'
        Verbose     = 'Gray'
        Information = 'Cyan'
        Debug       = 'Green'
    }
    if ($colorMap.ContainsKey($Channel)) {
        Write-Host $output -ForegroundColor $colorMap[$Channel]
    } else {
        Write-Warning "[Profile Write-Debug] Invalid channel: ${Channel}"
    }
}

# --- Timing Setup ---
$script:ProfileStartTime = [System.Diagnostics.Stopwatch]::StartNew()

function Log-Time {
    param(
        [string]$Message,
        [ValidateSet('Cumulative','Incremental')][string]$Type = 'Incremental'
    )
    if (-not $script:LastLogTime) {
        $script:LastLogTime = $script:ProfileStartTime.Elapsed
    }
    $now = $script:ProfileStartTime.Elapsed
    $delta = if ($Type -eq 'Cumulative') {
        $now.TotalMilliseconds
    }
    else {
        ($now - $script:LastLogTime).TotalMilliseconds
    }
    $label = if ($Type -eq 'Cumulative') { 'Total' } else { 'Step' }
    $timeString = "{0:N4} ms ($label)" -f $delta

    Write-Debug "$Message took $timeString" -Channel Information -Condition $global:DebugProfile
    $script:LastLogTime = $now
}

Log-Time 'Starting PROFILE Logging'

# --- Helper: Import a module safely ---
function Import-ProfileModule {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [switch]$Critical
    )
    if (Test-Path $Path) {
        try {
            Write-Debug "Importing ${Name}..." -Channel Verbose -Condition $global:DebugProfile
            Import-Module $Path -ErrorAction Stop
            Log-Time "${Name} Imported"
        }
        catch {
            Write-Warning "Failed to import ${Name}: $($_.Exception.Message)"
            Log-Time "${Name} Import Failed"
            if ($Critical) { $global:ModuleLoaderFailed = $true }
        }
    }
    else {
        Write-Warning "${Name} not found at '$Path'"
        Log-Time "${Name} skipped (not found)"
        if ($Critical) { $global:ModuleLoaderFailed = $true }
    }
}

# --- Add custom modules path to PSModulePath ---
if ($env:PSModulePath -notlike "*$Global:ProfileModulesPath*") {
    $env:PSModulePath += ";$Global:ProfileModulesPath"
    Write-Debug "Added '$Global:ProfileModulesPath' to PSModulePath" -Channel Debug -Condition $global:DebugProfile
}
Log-Time 'PSModulePath updated'

# --- Define module load order here ---
$Global:OrderedModules = @()
Write-Debug "Ordered modules set: $($Global:OrderedModules -join ', ')" -Channel Debug -Condition $global:DebugProfile
Log-Time 'Module order configured'

# --- Load Core Utility Modules ---
$DebugUtilsPath = Join-Path $Global:ProfileModulesPath 'DebugUtils.psm1'
Import-ProfileModule -Path $DebugUtilsPath -Name 'DebugUtils'

# --- Load AutoExportModule so it’s available for every module ---
$AutoExportPath = Join-Path $Global:ProfileModulesPath 'AutoExportModule.psm1'
Import-ProfileModule -Path $AutoExportPath -Name 'AutoExportModule'

# --- Load and Run ModuleLoader ---
$Global:ModuleLoaderLogicHasRun = $false
$Global:ModuleLoaderFailed     = $false
$ModuleLoaderPath              = Join-Path $Global:ProfileModulesPath 'ModuleLoader.psm1'
Import-ProfileModule -Path $ModuleLoaderPath -Name 'ModuleLoader' -Critical

# --- Load Other Standard/External Modules ---
try {
    Import-Module -Name Microsoft.WinGet.CommandNotFound -ErrorAction Stop
    Log-Time 'PowerToys CommandNotFound Imported'
} catch {
    Write-Warning "Failed to import Microsoft.WinGet.CommandNotFound: $($_.Exception.Message)"
    Log-Time 'PowerToys Import Failed'
}

if (Get-Command fnm -ErrorAction SilentlyContinue) {
    try {
        fnm env | ForEach-Object { Invoke-Expression $_ }
        Log-Time 'FNM initialized'
    } catch {
        Write-Warning "Failed FNM init: $($_.Exception.Message)"
        Log-Time 'FNM init failed'
    }
} else {
    Write-Debug "fnm not found, skipping." -Channel Information -Condition $global:DebugProfile
    Log-Time 'FNM skipped'
}

$ChocolateyProfile = Join-Path $env:ChocolateyInstall 'helpers\chocolateyProfile.psm1'
Import-ProfileModule -Path $ChocolateyProfile -Name 'Chocolatey Profile'

# Conda initialization (uncomment if desired)
# (& 'C:\Users\mcarls\anaconda3\shell\condabin\conda-hook.ps1') | Out-Null
# conda activate base
# Log-Time 'Conda Initialized'

# Oh-My-Posh
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ompTheme = "$env:POSH_THEMES_PATH\atomic.omp.json"
    if (Test-Path $ompTheme) {
        try {
            oh-my-posh init pwsh --config $ompTheme | Invoke-Expression
            Log-Time 'oh-my-posh init finished'
        } catch {
            Write-Warning "Failed OMP init: $($_.Exception.Message)"
            Log-Time 'oh-my-posh init failed'
        }
    } else {
        Write-Warning "OMP theme not found: $ompTheme"
        Log-Time 'oh-my-posh skipped (theme missing)'
    }
} else {
    Write-Debug "oh-my-posh not found, skipping." -Channel Information -Condition $global:DebugProfile
    Log-Time 'oh-my-posh skipped'
}

# --- Final Module Loader Summary as last output ---
if (-not $Global:ModuleLoaderFailed -and (Get-Command 'Show-ModuleLoaderSummary' -ErrorAction SilentlyContinue)) {
    Show-ModuleLoaderSummary
}

# --- Finalization ---
$script:ProfileStartTime.Stop()
$TotalProfileTime = $script:ProfileStartTime.Elapsed.TotalMilliseconds
$finalMessage    = "Finished loading PROFILE (Total Time: $($TotalProfileTime.ToString('F4')) ms)"
if ($global:DebugProfile) {
    Write-Debug -Message $finalMessage -Channel Information
} else {
    Write-Host $finalMessage
}

# --- END OF PROFILE ---
