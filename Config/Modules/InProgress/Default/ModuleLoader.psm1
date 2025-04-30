# Module-Loader.psm1
#Write-Host "Inside ModuleLoader"
if (-not $global:ModuleImportedModuleLoader) {
    $global:ModuleImportedModuleLoader = $true
} else {
    Write-Debug -Message "Attempting to import module twice!" -Channel "Error" -Condition $DebugProfile -FileAndLine
    return
}

# Define custom failure actions for specific modules
$Script:FailureActions = @{
    "WriteDebug" = {
        # Fallback Write-Debug function
        function Write-Debug {
            param (
                [string]$Message = "",
                [string]$Channel = "",
                [AllowNull()]
                [object]$Condition = $null
            )
            if (-not $DebugProfile) {
                return
            }
            Write-Host "[Fallback $Channel] $Message" -ForegroundColor Gray
        }
    }
    # Example for other failure actions
     "ls-aliases" = {
        Write-Warning "Custom action: ls-aliases failed to load. Check if it's installed correctly."
    }
}

# Function to load a module, explicitly script-scoped
function script:Initialize-Module {
    param (
        [string]$ModuleName,
        [string]$ModulePath
    )

    try {
        #Write-Debug -Message "Entering Pre-Action try for ${ModuleName}" -Channel "Verbose" -Condition $DebugProfile
        #Debug-Action -VerboseAction -SupressOutput -Action {
            #Import-Module -Name $ModulePath -ErrorAction Stop -Verbose
        #}
        if ($DebugProfile){
            Import-Module -Name $ModulePath -ErrorAction Stop -Verbose
        } else {
            Import-Module -Name $ModulePath -ErrorAction Stop
        }
        Write-Debug -Message "Successfully imported module: $ModuleName" -Channel "Debug" -Condition $DebugProfile
    } catch {
        Write-Debug -Message "ModuleLoader: Failed try for module: $ModuleName, in catch" -Channel "Error" -Condition $DebugProfile -FileAndLine
        # Log error details with caller context
        #$callerFile = $MyInvocation.ScriptName
        #$callerLine = $MyInvocation.ScriptLineNumber

        #Write-Debug -Message "[${callerFile}:${callerLine}] Failed to import module: $ModuleName. Error: $($_.Exception.Message)" -Channel "Warning" -Condition ($DebugProfile -ne $null -and $DebugProfile -ne "")
        Write-Debug -Message "Failed to import module: ${ModuleName}. Error: $($_Exception.Message)" -Channel "Warning" -Condition $DebugProfile -FileAndLine

        # Check for custom failure action
        if ($FailureActions.ContainsKey($ModuleName)) {
            & $FailureActions[$ModuleName]
        }
    }
}

# Get the current script name (this file) dynamically
$currentModuleName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)

# Check what module name is being returned (for debugging purposes)
#Write-Host "Current module name: $currentModuleName"

# Get all module files from the directory
$Script:AllModules = Get-ChildItem -Path $Global:ProfileModulesPath -Filter *.psm1

# Check the modules before filtering (for debugging purposes)
#Write-Host "All modules before filtering: $($AllModules | ForEach-Object { $_.BaseName })"

# Exclude the current module (ModuleLoader.psm1) from the list of modules to load
$Script:AllModules = $AllModules | Where-Object { $_.BaseName -ne $currentModuleName }
$Script:AllModules = $AllModules | Where-Object { $_.BaseName -ne "DebugUtils" }

# Check the modules after filtering (for debugging purposes)
#Write-Host "All modules after filtering: $($AllModules | ForEach-Object { $_.BaseName })"

# Split modules into ordered and unordered
$Script:ModulesToLoadFirst = $AllModules | Where-Object { $OrderedModules -contains $_.BaseName }
$Script:RemainingModules = $AllModules | Where-Object { $OrderedModules -notcontains $_.BaseName }

# Load ordered modules first
#Write-Debug -Message "Loading Orderes Modules: ${OrderedModules}" -Channel "Debug" -Condition $DebugProfile
foreach ($ModuleName in $OrderedModules) {
    $Module = $ModulesToLoadFirst | Where-Object { $_.BaseName -eq $ModuleName }
    if ($Module) {
        Initialize-Module -ModuleName $Module.BaseName -ModulePath $Module.FullName
    } else {
        Write-Debug -Message "Ordered module '$ModuleName' not found." -Channel "Warning" -Condition $DebugProfile
    }
}

# Load remaining modules
#Write-Debug -Message "Loading Remaining Modules: ${RemainingModules}" -Channel "Debug" -Condition $DebugProfile
foreach ($Module in $RemainingModules) {
    Initialize-Module -ModuleName $Module.BaseName -ModulePath $Module.FullName
}

#Write-Host "Exiting ModuleLoader, finished running"
