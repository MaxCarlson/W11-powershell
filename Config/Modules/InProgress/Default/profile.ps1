# Profile for Current User Current Host located at $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
# To use this profile rename it to Microsoft.PowerShell_profile.ps1 and move it to the above directory
# cp ProfileCUCH.ps1 $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 

Write-Host "Profile script execution started."

if (-not $global:ProfileLoaded) {
    $global:ProfileLoaded = $true
    Write-Host "ProfileLoaded flag is being set."
} else {
   # TODO: Write-Debug or Write-Host here to show we tried to load the $PROFILE twice
    Write-Host "Profile already loaded (skipped function definition section)."
    return
}

# Record the time we init the session
$global:SessionStartTime = Get-Date
# Define Script scope DebugProfile variable
$global:DebugProfile = $true
# Define base directory paths
$global:PWSH_REPO = "$env:USERPROFILE\Repos\W11-powershell"
$global:PWSH_SCRIPT_DIR = "$PWSH_REPO\Scripts"
$global:PWSH_BIN_DIR = "$PWSH_REPO\bin"

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

$Global:ProfileRepoPath = "${HOME}\Repos\W11-powershell"
$Global:ProfilePath = "${ProfileRepoPath}\Profiles"
$Global:ProfileModulesPath = Join-Path $Global:ProfileRepoPath "Config\Modules"

# Variables Added to Profile from Add-Variable.ps1 script. TODO: Aforementioned Script needs to be adjusted to the current setup
# ~~~~   Global Variables   ~~~~ #
$global:OBSIDIAN = 'C:\Users\mcarls\Documents\Obsidian-Vault\'
$global:SCRIPTS = 'C:\Projects\W11-powershell\'
# ~~~~ End Global Variables ~~~~ #

Log-Time "Global variables set"

# Add custom modules path to PSModulePath
$env:PSModulePath += ";`"$Global:ProfileModulesPath`""
# Define a prioritized order for some modules (script-scoped)
$Script:OrderedModules = @() #, "Other-Modules", ..., )

Import-Module (Join-Path $ProfileModulesPath 'DebugUtils.psm1')
Import-Module (Join-Path $ProfileModulesPath 'ModuleLoader.psm1')
#. (Join-Path $ProfileModulesPath 'ModuleLoader.psm1')
#Import-Module -LiteralPath "$ProfileModulesPath\ModuleLoader.psm1" -Force
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
# ~~~~ List of oh-my-posh Themes I like or have used
# jandedobbeleer.omp.json   - Old Slice theme
# atomic.omp.json           - Laptop theme 01/2025, now Slice theme as well
#
# Initialize Oh-My-Posh with the desired theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\atomic.omp.json" | Invoke-Expression
Log-Time "oh-my-posh init finished"


Show-ModuleLoaderSummary
Log-Time "ModuleLoader Summary"

Write-Debug -Message "Finished loading PROFILE" -Channel "Debug" -Condition $DebugProfile

# ~~~~ NOTHING AFTER THIS LINE ~~~~
