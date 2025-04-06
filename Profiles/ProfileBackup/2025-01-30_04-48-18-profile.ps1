# Profile for Current User Current Host located at $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
# To use this profile rename it to Microsoft.PowerShell_profile.ps1 and move it to the above directory
# cp ProfileCUCH.ps1 $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 
#
# ~~~~~~~~~~~~~
#
# Potential Themes
# To Show All Themes run Powershell Module:
#
# `Get-PoshThemes`
#
# ~~~~~~~~~~~~~
#
# Apply a new theme to test temporarily
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression
#
# Where paradox is the theme name to try
#
# ~~~~~~~~~~~~~
#
# To edit a theme:
# nvim "$env:POSH_THEMES_PATH\theme_name.omp.json"
#
# ~~~~~~~~~~~~~
#
# atomic
# atomicBit
# clean-detailed
# cloud_context
# craver
# half-life
# huvix
# if_tea
# iterm2
# jblab_2021
# json
# kali
# nu4a
# powerlevel10k_modern
# powerlevel10_rainbow
# powerline
# quick-term
# robbyrussell
# slim
# space
# takuya
# tokyo
#
#
#

$env:EDITOR = "nvim"

$script:ThemeName = "$env:POSH_THEMES_PATH\atomic.omp.json"

Write-Host "Profile script execution started."

if (-not $global:ProfileLoaded) {
    $global:ProfileLoaded = $true
    Write-Host "ProfileLoaded flag is being set."
} else {
   # TODO: Write-Debug or Write-Host here to show we tried to load the $PROFILE twice
    Write-Host "Profile already loaded (skipped function definition section)."
    return
}

# Ensure dynamic global variables are loaded before anything else
$DynamicVariablesFile = "$PROFILE" -replace '\\[^\\]+$', '\dynamic\start_profile\dynamic_global_variables.ps1'

if (Test-Path $DynamicVariablesFile) {
    Write-Output "🔹 Loading dynamic global variables: $DynamicVariablesFile"
    . $DynamicVariablesFile  # Load the global variables FIRST
} else {
    Write-Output "⚠️ Warning: Could not find dynamic global variables at: $DynamicVariablesFile"
}

# Dynamically determine the correct `dynamic/start_profile` directory
if ($global:PWSH_REPO) {
    $global:DynamicProfileDir = Join-Path $global:PWSH_REPO "dynamic/start_profile"
} else {
    Write-Output "❌ Error: PWSH_REPO is not set. Dynamic profiles cannot be loaded."
    return
}

# Ensure the dynamic profile directory exists and load all scripts
if (Test-Path $global:DynamicProfileDir) {
    Get-ChildItem -Path $global:DynamicProfileDir -Filter "*.ps1" | ForEach-Object {
        Write-Output "🔹 Loading: $_"
        . $_.FullName
    }
} else {
    Write-Output "⚠️ Warning: Dynamic profile directory not found at: $global:DynamicProfileDir"
}

# Record the time we init the session
$global:SessionStartTime = Get-Date
# Define Script scope DebugProfile variable
$global:DebugProfile = $true

# These should already be defined by the generated global variables
# Define base directory paths
#$global:PWSH_REPO = "$env:USERPROFILE\Repos\W11-powershell"
#$global:PWSH_SCRIPT_DIR = "$PWSH_REPO\Scripts"
#$global:PWSH_BIN_DIR = "$PWSH_REPO\bin"

if (-not $global:UserFunctionsBeforeModules ) {
    $global:UserFunctionsBeforeModules = Get-Command -CommandType Function | Select-Object -ExpandProperty Name
    $global:UserAliasesBeforeModules = Get-Alias | Select-Object -ExpandProperty Name
}

# Reload $PROFILE and work around the double load check..
# Not entirely working..? Beware modjles and functions won't loas again
# if they're already loaded.. 
# TODO: perhaps unloaded everything somehow to setup
# a reload functionm
function global:Reload-Profile {
    $global:ProfileLoaded = $false
    . $PROFILE
}

# Debug function for printing. Still is in DebugUtils, but it's nice to be able to use it before loading that module
function script:Write-Debug {
    param (
        [string]$Message = "",

        [Parameter()]
        [ValidateSet("Error", "Warning", "Verbose", "Information", "Debug")]
        [string]$Channel = "Debug",

        [AllowNull()]
        [object]$Condition = $true,

        [switch]$FileAndLine # Flag to include caller file and line number
    )

    # Ensure DebugProfile is enabled 
    if (-not $DebugProfile) {
        return
    }

    # Validate and convert the Condition parameter
    $isConditionMet = $true
    if ($Condition -ne $null) {
        try {
            $isConditionMet = [bool]$Condition
        } catch {
            Write-Warning "Invalid Condition value for Write-Debug: '${Condition}'. Defaulting to `${false}`."
            $isConditionMet = $false
        }
    }

    if (-not $isConditionMet) {
        return
    }

    # Prepare the message with optional caller information
    $outputMessage = $Message
    if ($FileAndLine) {
        # Get caller information for debugging
        $caller = Get-PSCallStack | Select-Object -Skip 1 -First 1
        $callerFile = $caller.ScriptName
        $callerLine = $caller.ScriptLineNumber
        $outputMessage = "[${callerFile}:${callerLine}] $Message"
    }

    # Define channel colors
    $colorMap = @{
        "Error"       = "Red"
        "Warning"     = "Yellow"
        "Verbose"     = "Gray"
        "Information" = "Cyan"
        "Debug"       = "Green"
    }

    $color = $colorMap[$Channel]
    if ($color) {
        Write-Host $outputMessage -ForegroundColor $color
    } else {
        Write-Warning "Invalid channel specified: ${Channel}"
    }



}


# Start Profiling Timer
$script:StartTime = Get-Date

# Measure specific parts of the profile
function Log-Time {
    param([string]$Message)
    $CurrentTime = Get-Date
    $ElapsedTime = ($CurrentTime - $StartTime).TotalMilliseconds
    Write-Debug -Message "$Message took $ElapsedTime ms" -Channel "Information"
    $StartTime = $CurrentTime
}

# Log the start time for oh-my-posh
Log-Time "Starting PROFILE Logging"


#$zoxideInit = (&zoxide init pwsh) -join "`n"
#Invoke-Expression $zoxideInit
#$zoxideInit = $false#(&zoxide init powershell) -join "`n"
#if ($zoxideInit) {
#    Invoke-Expression $zoxideInit
#    Write-Host "zoxide initialized successfully" -ForegroundColor Green
#} else {
#    Write-Host "zoxide initialization failed" -ForegroundColor Red
#}
#
#zoxide init powershell
#Invoke-Expression (&zoxide init powershell)
#Invoke-Expression (&zoxide init powershell --no-cmd | Out-String)
#
#Log-Time "Zoxide init finished"
#
## Global variables for paths
#if (-not $HOME) { 
#    if ($DebugProfile) {Write-Host "Variable \$HOME not set. Setting now."}
#    $Global:HOME = $Env:USERPROFILE 
#}

# Variables Added to Profile from Add-Variable.ps1 script. TODO: Aforementioned Script needs to be adjusted to the current setup
# ~~~~   Global Variables   ~~~~ #
$global:OBSIDIAN = 'C:\Users\mcarls\Documents\Obsidian-Vault\'
$global:SCRIPTS = 'C:\Projects\W11-powershell\'
# ~~~~ End Global Variables ~~~~ #

Log-Time "Global variables set"

# Add custom modules path to PSModulePath
$env:PSModulePath += ";`"$Global:PWSH_MODULES_PATH`""
# Define a prioritized order for some modules (script-scoped)
$Script:OrderedModules = @() #, "Other-Modules", ..., )

#Import-Module (Join-Path $PWSH_MODULES_PATH Module-Loader.psm1)


#$script:job = Get-Job -Name "PersistentModuleLoader" -ErrorAction SilentlyContinue
function script:Start-PersistentSession {
    # Check if the persistent process is already running
    #$ExistingProcess = Get-Process -Name "pwsh" -ErrorAction SilentlyContinue | Where-Object {
    #    $_.CommandLine -like "*ModuleLoader.psm1*"
    #}
    $ExistingProcess = Get-Process -Name "pwsh" -ErrorAction SilentlyContinue | Where-Object CommandLine -Match "ModuleLoader\.psm1"

    if (-not $ExistingProcess) {
        # Start the persistent process
        Start-Process -FilePath "pwsh.exe" -ArgumentList "-NoExit", "-Command & {
            Import-Module (Join-Path $PWSH_MODULES_PATH 'DebugUtils.psm1')
            Import-Module (Join-Path $PWSH_MODULES_PATH 'ModuleLoader.psm1')

            while ($true) { Start-Sleep -Seconds 60 }
        }" -WindowStyle Hidden
        # Log the job creation
        Log-Time "Started persistent job 'PersistentModuleLoader' - Importing DebugUtils.psm1, ModuleLoader.psm1 and all other associated modules."
        Write-Debug -Message "Started persistent background process for module loading." -Channel "Debug"
    } else {
        Write-Debug -Message "Not loading ModuleLoader or other Profile associated modules as they're already loaded and running" -Channel "Debug"
        Log-Time "Finished skipping loading ModuleLoader and associated modules"
    }
}
function global:Find-PersistentSession {
    Get-Process -Name "pwsh" | Where-Object { $_.CommandLine -like "*ModuleLoader.psm1*" }
}

function global:Kill-PersistentSession {
    Find-PersistentSession | Stop-Process
    $FindResults = Find-PersistentSession
    Write-Debug -Message "PersistantSession killed. Attempting to find session for debug: \n ${FindResults}"
}

# Ensure the persistent session is running
# TODO: NOT WORKING - Modules are not loaded in mew sessions:wq
#
#Start-PersistentSession

Import-Module (Join-Path $PWSH_MODULES_PATH 'DebugUtils.psm1')
Import-Module (Join-Path $PWSH_MODULES_PATH 'ModuleLoader.psm1')

#Start-AtuinHistory


# PowerToys CommandNotFound module (Optional: comment out if causing issues)
#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module
Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58

# Initialize fnm (Fast Node Manager) environment variables
fnm env | ForEach-Object { Invoke-Expression $_ }
Log-Time "Fast Node Manager initialized"




# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
Log-Time "Finished Importing ChocolateyProfile Module"


# >>> conda initialize >>>
# CONDA IS ACTIVATED IN $PROFILE.CurrentUserCurrentHost
# this is $PROFILE.AllUsersAllHosts
# !! Contents within this block are managed by 'conda init' !!
#(& "C:\Users\mcarls\anaconda3\shell\condabin\conda-hook.ps1") #| Out-Null
#conda activate base
# <<< conda initialize <<<


# ~~~~ END OF PROFILE ~~~~
#
#
# Initialize Oh-My-Posh with the desired theme
oh-my-posh init pwsh --config "$ThemeName" | Invoke-Expression
Log-Time "oh-my-posh init finished"

Write-Debug -Message "Finished loading PROFILE" -Channel "Debug" -Condition $DebugProfile

# ~~~~ NOTHING AFTER THIS LINE ~~~~


#function __zoxide_z {
#    if ($args.Length -eq 0) {
#        Write-Host "Navigating to home (~)" -ForegroundColor Cyan
#        __zoxide_cd ~ $true
#    }
#    elseif ($args.Length -eq 1 -and ($args[0] -eq '-' -or $args[0] -eq '+')) {
#        Write-Host "Navigating to: $args[0]" -ForegroundColor Cyan
#        __zoxide_cd $args[0] $false
#    }
#    elseif ($args.Length -eq 1 -and (Test-Path $args[0] -PathType Container)) {
#        Write-Host "Direct path detected: $args[0]" -ForegroundColor Cyan
#        __zoxide_cd $args[0] $true
#    }
#    else {
#        Write-Host "Running zoxide query for pattern: $args" -ForegroundColor Cyan
#        $result = __zoxide_pwd
#        if ($null -ne $result) {
#            $result = __zoxide_bin query --exclude $result "--" @args
#        } else {
#            $result = __zoxide_bin query "--" @args
#        }
#
#        if ($LASTEXITCODE -eq 0) {
#            Write-Host "zoxide query result: $result" -ForegroundColor Green
#            __zoxide_cd $result $true
#        } else {
#            Write-Host "zoxide query failed for pattern: $args" -ForegroundColor Red
#        }
#    }
#}
#
#function __zoxide_cd($dir, $literal) {
#    Write-Host "Attempting to navigate to: $dir" -ForegroundColor Cyan
#
#    try {
#        if ($literal) {
#            Write-Host "Navigating literally to: $dir" -ForegroundColor Yellow
#            Set-Location -LiteralPath $dir -Passthru -ErrorAction Stop
#        } else {
#            Write-Host "Navigating to: $dir" -ForegroundColor Yellow
#            Set-Location -Path $dir -Passthru -ErrorAction Stop
#        }
#    } catch {
#        Write-Host "Error navigating to: $dir. $_" -ForegroundColor Red
#    }
#}
