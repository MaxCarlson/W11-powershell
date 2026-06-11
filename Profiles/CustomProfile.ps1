$script:IsSshSession = [bool](
    $env:SSH_CONNECTION -or
    $env:SSH_CLIENT -or
    $env:SSH_TTY
)

$script:PowerShellArguments = [Environment]::GetCommandLineArgs()

$script:IsExplicitAutomationShell = [bool](
    $env:CI -eq "true" -or
    $env:CODEX_SANDBOX -or
    $env:GITHUB_ACTIONS -eq "true" -or
    $env:TF_BUILD -eq "true" -or
    $env:TEAMCITY_VERSION -or
    $env:JENKINS_URL -or
    $env:MAX_FORCE_AUTOMATION_PWSH -eq "1" -or
    $script:PowerShellArguments -contains "-NonInteractive" -or
    $script:PowerShellArguments -contains "-Command" -or
    $script:PowerShellArguments -contains "-EncodedCommand" -or
    $script:PowerShellArguments -contains "-File" -or
    $script:PowerShellArguments -contains "-c" -or
    $script:PowerShellArguments -contains "-e" -or
    $script:PowerShellArguments -contains "-f"
)

$script:IsNonInteractiveDotNetSession = [bool](
    -not $script:IsSshSession -and
    -not [Environment]::UserInteractive
)

$script:IsRedirectedNonSshConsole = [bool](
    -not $script:IsSshSession -and
    (
        [Console]::IsInputRedirected -or
        [Console]::IsOutputRedirected
    )
)

$script:IsUnsupportedNonSshHost = [bool](
    -not $script:IsSshSession -and
    $Host.Name -notin @(
        "ConsoleHost",
        "Visual Studio Code Host"
    )
)

$script:IsAutomationShell = [bool](
    $script:IsExplicitAutomationShell -or
    $script:IsNonInteractiveDotNetSession -or
    $script:IsRedirectedNonSshConsole -or
    $script:IsUnsupportedNonSshHost
)

if ($env:MAX_FORCE_INTERACTIVE_PWSH -eq "1") {
    $script:IsAutomationShell = $false
}

if ($script:IsAutomationShell) {
    $InformationPreference = "SilentlyContinue"
    $VerbosePreference = "SilentlyContinue"
    $DebugPreference = "SilentlyContinue"
    $ProgressPreference = "SilentlyContinue"
    $WarningPreference = "SilentlyContinue"
    $ErrorActionPreference = "SilentlyContinue"

    return
}

# Debug output is opt-in only
$script:DebugProfile = $env:POWERSHELL_PROFILE_DEBUG -eq "1"
# -------------------------------------------------------


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
# Dynamically detect W11-powershell repo location
if ($env:PWSH_REPO -and (Test-Path $env:PWSH_REPO -PathType Container)) {
    # Use environment variable if set
    $global:PWSH_REPO = $env:PWSH_REPO
} elseif ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "..\Config\Modules"))) {
    # Detect from profile script location (if hard-linked from W11-powershell\Profiles\)
    $global:PWSH_REPO = Split-Path $PSScriptRoot -Parent
} else {
    # Fallback: try common locations
    $possiblePaths = @(
        "$env:USERPROFILE\src\W11-powershell"
        "$env:USERPROFILE\Repos\W11-powershell"
        "C:\Projects\W11-powershell"
    )
    $found = $false
    foreach ($path in $possiblePaths) {
        if (Test-Path $path -PathType Container) {
            $global:PWSH_REPO = $path
            $found = $true
            break
        }
    }
    if (-not $found) {
        Write-Warning "W11-powershell repository path not found. Checked: $($possiblePaths -join ', ')"
        Write-Warning "Set `$env:PWSH_REPO manually or ensure profile is in W11-powershell\Profiles\"
        $global:PWSH_REPO = "$env:USERPROFILE\Repos\W11-powershell"  # Last resort default
    }
}
if (-not (Test-Path $global:PWSH_REPO -PathType Container)) {
    Write-Warning "Repository path not found: $($global:PWSH_REPO)"
}
$Global:ProfileRepoPath    = $global:PWSH_REPO
$Global:ProfileModulesPath = Join-Path $Global:ProfileRepoPath 'Config\Modules'
if (-not (Test-Path $Global:ProfileModulesPath -PathType Container)) {
    Write-Error "Module directory not found: '$($Global:ProfileModulesPath)'. Cannot load custom modules."
    return
}

# Dynamically detect scripts repo location
if ($env:SCRIPTS_REPO -and (Test-Path $env:SCRIPTS_REPO -PathType Container)) {
    $global:SCRIPTS_REPO = $env:SCRIPTS_REPO
} else {
    $possibleScriptsPaths = @(
        "$env:USERPROFILE\src\scripts"
        "$env:USERPROFILE\Repos\scripts"
        "C:\Projects\scripts"
    )
    $scriptsFound = $false
    foreach ($path in $possibleScriptsPaths) {
        if (Test-Path $path -PathType Container) {
            $global:SCRIPTS_REPO = $path
            $scriptsFound = $true
            break
        }
    }
    if (-not $scriptsFound) {
        $global:SCRIPTS_REPO = "$env:USERPROFILE\Repos\scripts"  # Default fallback
    }
}

# Dynamically detect dotfiles repo location
if ($env:DOTFILES_REPO -and (Test-Path $env:DOTFILES_REPO -PathType Container)) {
    $global:DOTFILES_REPO = $env:DOTFILES_REPO
} else {
    $possibleDotfilesPaths = @(
        "$env:USERPROFILE\src\dotfiles"
        "$env:USERPROFILE\Repos\dotfiles"
        "$env:USERPROFILE\dotfiles"
        "C:\dotfiles"
    )
    $dotfilesFound = $false
    foreach ($path in $possibleDotfilesPaths) {
        if (Test-Path $path -PathType Container) {
            $global:DOTFILES_REPO = $path
            $dotfilesFound = $true
            break
        }
    }
    if (-not $dotfilesFound) {
        $global:DOTFILES_REPO = "$env:USERPROFILE\dotfiles"  # Default fallback
    }
}

# Derive parent Repos/src directory from detected paths
$global:REPOS_DIR = if (Test-Path (Join-Path $global:PWSH_REPO "..\scripts")) {
    Split-Path $global:PWSH_REPO -Parent
} elseif (Test-Path (Join-Path $global:SCRIPTS_REPO "..\W11-powershell")) {
    Split-Path $global:SCRIPTS_REPO -Parent
} else {
    "$env:USERPROFILE\Repos"
}

# --- Ensure critical PATH entries for tools/CLIs ---
function Add-PathIfMissing {
    param([string]$PathToAdd)
    if (-not $PathToAdd) { return }
    $normalized = $PathToAdd.TrimEnd('\','/')
    if (-not (Test-Path $normalized)) { return }
    $parts = ($env:PATH -split ';') | Where-Object { $_ -ne '' }
    if ($parts -notcontains $normalized) {
        $env:PATH = "$normalized;$env:PATH"
    }
}

$pathsToEnsure = @(
    (Join-Path $Global:ProfileRepoPath 'bin'),
    (Join-Path $global:SCRIPTS_REPO 'bin'),
    (Join-Path $global:SCRIPTS_REPO '.venv\Scripts'),
    (Join-Path $env:APPDATA 'Python\Python312\Scripts'),
    (Join-Path $env:USERPROFILE '.local\bin')
)
$pathsToEnsure | ForEach-Object { Add-PathIfMissing $_ }

# --- Global Variables ---
# Legacy variables for backward compatibility
$global:OBSIDIAN = 'C:\Users\mcarls\Documents\Obsidian-Vault\'
$global:SCRIPTS  = $global:PWSH_REPO  # Point to W11-powershell for legacy compat

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

# Modules registered with lightweight wrapper functions and imported on first use.
# Keep modules here when they provide occasional commands or expensive import-time setup.
$Global:LazyModules = @(
    'BackupAndRestore',
    'Cheatsh',
    'Coloring',
    'Downloader',
    'Extractor',
    'GitHubExplorer',
    'Installer',
    'JobsModule',
    'LinkManager',
    'Monitoring',
    'PSProfiler',
    'TmuxModule'
)
$Global:LazyModuleFunctions = @{
    BackupAndRestore = @(
        'Backup-All',
        'Restore-All',
        'Backup-EnvironmentVariables',
        'Restore-EnvironmentVariables',
        'Backup-FirewallRules',
        'Restore-FirewallRules',
        'Backup-RegistryKeys',
        'Restore-RegistryKeys',
        'Backup-ScheduledTasks',
        'Restore-ScheduledTasks'
    )
    Cheatsh = @('cht')
    Coloring = @('Write-Color')
    Downloader = @('Get-File')
    Extractor = @('Expand-CustomArchive')
    GitHubExplorer = @('Start-GitHubExplorer')
    Installer = @(
        'Test-ProgramInstallation',
        'Install-WingetPackageManager',
        'Install-ChocolateyPackageManager',
        'Install-ScoopPackageManager',
        'Install-Program'
    )
    JobsModule = @('Start-BackgroundJob','Get-ActiveJobs','Get-JobOutput','Stop-JobByIdOrName','Stop-AllJobs')
    LinkManager = @('New-Link','Remove-Link')
    Monitoring = @('Get-LogFileList','Watch-LogFile','Watch-CommonLog')
    PSProfiler = @(
        'New-PSProfilerStopwatch',
        'Start-PSProfilerStopwatch',
        'Stop-PSProfilerStopwatch',
        'Reset-PSProfilerStopwatch',
        'Get-PSProfilerElapsedTime',
        'New-PSProfilerTimer',
        'Get-PSProfilerTimerRemaining',
        'Get-PSProfilerTimerExpired',
        'Measure-PSProfiler',
        'New-PSProfiler',
        'Invoke-PSProfilerBlock',
        'Get-PSProfilerReport',
        'Wait-PSProfilerTimeLimit',
        'Get-Stopwatch'
    )
    TmuxModule = @('Test-Tmux','ts','tsl','tsn','tsf','tsd','tsr','tsnxt','tsrename','tmd')
}
Write-Debug "Lazy modules set: $($Global:LazyModules -join ', ')" -Channel Debug -Condition $global:DebugProfile

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
        fnm env 2>$null | ForEach-Object { Invoke-Expression $_ }
        Log-Time 'FNM initialized'
    } catch {
        Write-Warning "Failed FNM init: $($_.Exception.Message)"
        Log-Time 'FNM init failed'
    }
} else {
    Write-Debug "fnm not found, skipping." -Channel Information -Condition $global:DebugProfile
    Log-Time 'FNM skipped'
}

# SSH/TMUX SETUP
## Detect “am I over SSH?” by presence of SSH_CLIENT or SSH_CONNECTION
# Add this to your Microsoft.PowerShell_profile.ps1
# Enable ANSI / VT100 support for console title updates
# ~/.config/powershell/Microsoft.PowerShell_profile.ps1

# Enable ANSI / VT100 support for console title updates
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class Win32 {
  public const int STD_OUTPUT_HANDLE = -11;
  public const uint ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;
  [DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int nStdHandle);
  [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
  [DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
}
"@ -PassThru | Out-Null

$hOut = [Win32]::GetStdHandle([Win32]::STD_OUTPUT_HANDLE)
[uint32]$mode = 0
[Win32]::GetConsoleMode($hOut, [ref]$mode)    | Out-Null
[Win32]::SetConsoleMode($hOut, $mode -bor [Win32]::ENABLE_VIRTUAL_TERMINAL_PROCESSING) | Out-Null

# Always update tmux pane title to remote cwd on each prompt
function global:prompt {
  $esc = [char]27
  $bel = [char]7
  $cwd = (Get-Location).Path
  # DCS passthrough to tmux: ESC P tmux; ESC ]2;title BEL ESC \
  Write-Host -NoNewline ("${esc}Ptmux;${esc}]2;${cwd}${bel}${esc}\\")
  "PS $cwd> "
}
Log-Time 'TmuxSSH setup finished'

if ($env:ChocolateyInstall) {
    $ChocolateyProfile = Join-Path $env:ChocolateyInstall 'helpers\chocolateyProfile.psm1'
    Import-ProfileModule -Path $ChocolateyProfile -Name 'Chocolatey Profile'
} else {
    Write-Debug "Chocolatey not installed, skipping." -Channel Information -Condition $global:DebugProfile
}
Log-Time 'choco setup finished'


# Micromamba initialization (safe)
$mm = Get-Command micromamba -ErrorAction SilentlyContinue
if ($mm) {
    try {
        $root = $env:MAMBA_ROOT_PREFIX
        if (-not $root) {
            $root = Join-Path $env:USERPROFILE "micromamba"
        }

        $hook = & micromamba shell hook -s powershell -r $root 2>$null
        if ($LASTEXITCODE -eq 0 -and $hook) {
            Invoke-Expression $hook
        }
    } catch {
        # swallow errors to avoid breaking the profile
    }
	Log-Time 'Micro-mamba Setup finished.'
} else {
    Write-Debug "micromamba not found; skipping init." -Channel Information -Condition $global:DebugProfile
    Log-Time 'Micro-mamba Setup finished.'
}


# Oh-My-Posh
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    try {
        # Use custom atomic theme with cleaner shell indicator
        $customTheme = Join-Path $global:SCRIPTS_REPO 'pscripts\atomic-custom.omp.json'
        if (Test-Path $customTheme) {
            $ompTheme = $customTheme
        } else {
            # Fallback to upstream atomic theme
            $ompTheme = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/atomic.omp.json'
        }
        oh-my-posh init pwsh --config $ompTheme | Invoke-Expression
        Log-Time 'oh-my-posh init finished'
    } catch {
        Write-Warning "Failed OMP init: $($_.Exception.Message)"
        Log-Time 'oh-my-posh init failed'
    }
} else {
    Write-Debug "oh-my-posh not found, skipping." -Channel Information -Condition $global:DebugProfile
    Log-Time 'oh-my-posh skipped'
}

# === BEGIN: Generated Python tool aliases/functions for PowerShell ===
# These files are generated by scripts/pyscripts/setup.py from alias_and_func_defs.txt.
# We load them explicitly—no scripts auto-edit the profile.
# Uses $global:DOTFILES_REPO detected earlier in the profile

if ($global:DOTFILES_REPO -and (Test-Path $global:DOTFILES_REPO)) {
    $dyn = Join-Path $global:DOTFILES_REPO 'dynamic'
    $psAliases = Join-Path $dyn 'setup_pyscripts_aliases.ps1'
    $psFuncs   = Join-Path $dyn 'setup_pyscripts_functions.ps1'
    $venvActivation = Join-Path $dyn 'venv_auto_activation.ps1'

    if (Test-Path $psAliases) { . $psAliases }
    if (Test-Path $psFuncs)   { . $psFuncs   }
    if (Test-Path $venvActivation) { . $venvActivation }
} else {
    Write-Debug "DOTFILES_REPO not found, skipping pyscripts setup." -Channel Information -Condition $global:DebugProfile
}
# === END: Generated Python tool aliases/functions for PowerShell ===

# --- Final Module Loader Summary as last output ---
if (-not $Global:ModuleLoaderFailed -and (Get-Command 'Show-ModuleLoaderSummary' -ErrorAction SilentlyContinue)) {
    Show-ModuleLoaderSummary
}

# --- Finalization ---
$script:ProfileStartTime.Stop()
$TotalProfileTime = $script:ProfileStartTime.Elapsed.TotalMilliseconds
$finalMessage    = "Finished loading PROFILE (Total Time: $($TotalProfileTime.ToString(`"F4`")) ms)"
if ($global:DebugProfile) {
    Write-Debug -Message $finalMessage -Channel Information
} else {
    Write-Host $finalMessage
}

# --- END OF PROFILE ---

# Machine/local extras generated by scripts_setup/setup_pwsh_profile.py
$setupPwshSnippet = $null
if ($global:DOTFILES_REPO -and (Test-Path $global:DOTFILES_REPO -PathType Container)) {
    $setupPwshSnippet = Join-Path $global:DOTFILES_REPO 'dynamic\setup_pwsh_profile.generated.ps1'
} elseif ($env:DOTFILES_REPO -and (Test-Path $env:DOTFILES_REPO -PathType Container)) {
    $setupPwshSnippet = Join-Path $env:DOTFILES_REPO 'dynamic\setup_pwsh_profile.generated.ps1'
}

if ($setupPwshSnippet -and (Test-Path $setupPwshSnippet -PathType Leaf)) {
    . $setupPwshSnippet
} else {
    $clipboardModulePath = $null
    if ($global:SCRIPTS_REPO -and (Test-Path $global:SCRIPTS_REPO -PathType Container)) {
        $clipboardModulePath = Join-Path $global:SCRIPTS_REPO 'pwsh\ClipboardModule.psm1'
    } elseif ($env:SCRIPTS_REPO -and (Test-Path $env:SCRIPTS_REPO -PathType Container)) {
        $clipboardModulePath = Join-Path $env:SCRIPTS_REPO 'pwsh\ClipboardModule.psm1'
    }

    if ($clipboardModulePath -and (Test-Path $clipboardModulePath -PathType Leaf)) {
        Import-Module $clipboardModulePath -ErrorAction SilentlyContinue
    } else {
        Write-Debug "setup_pwsh_profile snippet missing; skipped ClipboardModule import." -Channel Information -Condition $global:DebugProfile
    }
}
