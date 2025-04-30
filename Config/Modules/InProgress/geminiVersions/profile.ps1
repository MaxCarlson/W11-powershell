# Profile for Current User Current Host located at $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1

Write-Host "`nProfile script execution started."

# --- Profile Load Guard ---
if ($global:ProfileLoaded) { Write-Host "Profile already loaded (skipped execution)."; return }
$global:ProfileLoaded = $true
Write-Host "ProfileLoaded flag is being set."

# --- Initial Setup & Configuration ---
$global:SessionStartTime = Get-Date
# --- !! SET DEBUG OUTPUT LEVEL HERE !! ---
$global:DebugProfile = $false # Set to $false for the desired clean final output
# --- Base Paths ---
$global:PWSH_REPO = "$env:USERPROFILE\Repos\W11-powershell"
if (-not (Test-Path $global:PWSH_REPO -PathType Container)) { Write-Warning "Repository path not found: $($global:PWSH_REPO)" }
$Global:ProfileRepoPath = $global:PWSH_REPO
$Global:ProfileModulesPath = Join-Path $Global:ProfileRepoPath "Config\Modules"
if (-not (Test-Path $Global:ProfileModulesPath -PathType Container)) { Write-Error "Module directory not found: '$($Global:ProfileModulesPath)'. Cannot load custom modules."; return }

# --- Global Variables ---
$global:OBSIDIAN = 'C:\Users\mcarls\Documents\Obsidian-Vault\'
$global:SCRIPTS = 'C:\Projects\W11-powershell\'

# --- Utility Functions Defined in Profile ---
function global:Reload-Profile { Write-Warning "Attempting profile reload ($PROFILE). Close/reopen shell recommended."; $global:ProfileLoaded = $false; . $PROFILE }
function script:Write-Debug { param([string]$Message="",[Parameter()][ValidateSet("Error", "Warning", "Verbose", "Information", "Debug")][string]$Channel="Debug",[AllowNull()][object]$Condition=$true,[switch]$FileAndLine)
    if (-not $global:DebugProfile){return}; $isConditionMet=$true; if($Condition -ne $null){try {$isConditionMet=[bool]$Condition}catch{Write-Warning "[Profile Write-Debug] Invalid Condition:'$Condition'"; $isConditionMet=$false}}; if(-not $isConditionMet){return}
    $outputMessage=$Message; if($FileAndLine){$caller=Get-PSCallStack|Select-Object -Skip 1 -First 1; if($caller -and $caller.ScriptName){$callerFile=Split-Path -Path $caller.ScriptName -Leaf;$callerLine=$caller.ScriptLineNumber;$outputMessage="[${callerFile}:${callerLine}] $Message"}else{$outputMessage="[?:?] $Message"}}
    $colorMap=@{"Error"="Red";"Warning"="Yellow";"Verbose"="Gray";"Information"="Cyan";"Debug"="Green"}; $color=$colorMap[$Channel]; if($color){Write-Host $outputMessage -ForegroundColor $color}else{Write-Warning "[Profile Write-Debug] Invalid channel: ${Channel}"}}

# --- Timing Setup ---
$script:ProfileStartTime = [System.Diagnostics.Stopwatch]::StartNew()
function Log-Time { param([string]$Message, [ValidateSet("Cumulative", "Incremental")][string]$Type = "Incremental")
    if ($null -eq $script:LastLogTime) { $script:LastLogTime = $script:ProfileStartTime.Elapsed }
    $currentTime = $script:ProfileStartTime.Elapsed; $totalElapsedMs = $currentTime.TotalMilliseconds; $incrementalMs = ($currentTime - $script:LastLogTime).TotalMilliseconds
    $timeString = if ($Type -eq "Cumulative") {"$($totalElapsedMs.ToString('F4')) ms (Total)"} else {"$($incrementalMs.ToString('F4')) ms (Step)"}
    if (Get-Command 'Write-Debug' -ErrorAction SilentlyContinue) { Write-Debug -Message "$Message took $timeString" -Channel "Information" -Condition $global:DebugProfile }
    elseif ($global:DebugProfile) { Write-Host "[INFO] $Message took $timeString" }
    $script:LastLogTime = $currentTime }

# --- Start Profile Execution ---
Log-Time "Starting PROFILE Logging"

# Add custom modules path to PSModulePath
if ($env:PSModulePath -notlike "*$($Global:ProfileModulesPath)*") { $env:PSModulePath = "$($env:PSModulePath);$($Global:ProfileModulesPath)"; Write-Debug "Added '$($Global:ProfileModulesPath)' to PSModulePath" -Channel Debug -Condition $global:DebugProfile }
Log-Time "PSModulePath updated"

# --- *** DEFINE MODULE LOAD ORDER HERE *** ---
$Global:OrderedModules = @( )
Write-Debug "Ordered modules set: $($Global:OrderedModules -join ', ')" -Channel Debug -Condition $global:DebugProfile
Log-Time "Module order configured"

# --- Load Core Utility Modules ---
$DebugUtilsPath = Join-Path $Global:ProfileModulesPath 'DebugUtils.psm1'
if (Test-Path $DebugUtilsPath) {
    try { Write-Debug "Importing DebugUtils..." -Channel Verbose -Condition $global:DebugProfile; Import-Module $DebugUtilsPath -ErrorAction Stop; Log-Time "DebugUtils Imported" }
    catch { Write-Warning "Failed to import DebugUtils: $($_.Exception.Message)"; Log-Time "DebugUtils Import Failed" }
} else { Write-Debug "DebugUtils module not found, skipping." -Channel Information -Condition $global:DebugProfile; Log-Time "DebugUtils skipped" }

# --- Load and Run ModuleLoader ---
$Global:ModuleLoaderLogicHasRun = $false # Reset session logic run flag
$Global:ModuleLoaderFailed = $false
$ModuleLoaderPath = Join-Path $Global:ProfileModulesPath 'ModuleLoader.psm1'
if (Test-Path $ModuleLoaderPath) {
    try { Write-Debug "Importing ModuleLoader..." -Channel Verbose -Condition $global:DebugProfile; Import-Module $ModuleLoaderPath -ErrorAction Stop }
    catch { Write-Warning "CRITICAL: ModuleLoader module failed to import: $($_.Exception.Message)"; $Global:ModuleLoaderFailed = $true; Log-Time "ModuleLoader Import Failed" }
} else { Write-Error "ModuleLoader.psm1 not found at '$ModuleLoaderPath'."; $Global:ModuleLoaderFailed = $true; Log-Time "ModuleLoader skipped (not found)" }

# --- Display Module Loader Summary ---
if (-not $Global:ModuleLoaderFailed -and (Get-Command 'Show-ModuleLoaderSummary' -ErrorAction SilentlyContinue)) { Show-ModuleLoaderSummary }
elseif (-not $Global:ModuleLoaderFailed) { Write-Warning "ModuleLoader loaded, but Show-ModuleLoaderSummary function unavailable." }
Log-Time "ModuleLoader processing and summary finished"

# --- Load Other Standard/External Modules ---

# PowerToys CommandNotFound
try { Import-Module -Name Microsoft.WinGet.CommandNotFound -ErrorAction Stop; Log-Time "PowerToys CommandNotFound Imported" }
catch { Write-Warning "Failed to import PowerToys CommandNotFound: $($_.Exception.Message)"; Log-Time "PowerToys Import Failed" }

# FNM
if (Get-Command fnm -ErrorAction SilentlyContinue) { try { fnm env | ForEach-Object { Invoke-Expression $_ }; Log-Time "FNM initialized" } catch { Write-Warning "Failed FNM init: $($_.Exception.Message)"; Log-Time "FNM init failed" } }
else { Write-Debug "fnm not found, skipping." -Channel Information -Condition $global:DebugProfile; Log-Time "FNM skipped" }

# Chocolatey
$ChocolateyProfile = Join-Path $env:ChocolateyInstall "helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) { try { Import-Module $ChocolateyProfile -ErrorAction Stop; Log-Time "Chocolatey Profile Imported" } catch { Write-Warning "Failed Choco profile: $($_.Exception.Message)"; Log-Time "Choco Profile Import Failed" } }
else { Write-Debug "Choco profile not found, skipping." -Channel Information -Condition $global:DebugProfile; Log-Time "Choco Profile skipped" }

# Conda (Keep commented/configured as needed)
# (& "C:\Users\mcarls\anaconda3\shell\condabin\conda-hook.ps1") | Out-Null; conda activate base; Log-Time "Conda Initialized"

# Oh-My-Posh
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ompTheme = "$env:POSH_THEMES_PATH\atomic.omp.json"; if (Test-Path $ompTheme) { try { oh-my-posh init pwsh --config $ompTheme | Invoke-Expression; Log-Time "oh-my-posh init finished" } catch { Write-Warning "Failed OMP init: $($_.Exception.Message)"; Log-Time "oh-my-posh init failed" } }
    else { Write-Warning "OMP theme not found: $ompTheme"; Log-Time "oh-my-posh skipped (theme missing)" }
} else { Write-Debug "oh-my-posh not found, skipping." -Channel Information -Condition $global:DebugProfile; Log-Time "oh-my-posh skipped" }

# --- Finalization ---
$script:ProfileStartTime.Stop()
$TotalProfileTime = $script:ProfileStartTime.Elapsed.TotalMilliseconds
$finalMessage = "Finished loading PROFILE (Total Time: $($TotalProfileTime.ToString('F4')) ms)"
if ($global:DebugProfile) { Write-Debug -Message $finalMessage -Channel "Information" } else { Write-Host $finalMessage }

# --- END OF PROFILE ---
