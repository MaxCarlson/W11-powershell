<#
.SYNOPSIS
    Creates hard links or symbolic links for specified scripts and ensures a given path is in the user's or system's PATH.

.DESCRIPTION
    This script iterates over a list of predefined scripts, searches for them in a designated scripts directory, and creates hard or symbolic links in a bin directory.
    It also ensures that the bin directory is added to either the user's or the system's PATH safely. Debug output is available using the -Debug flag.

.PARAMETER Debug
    Enables verbose debug output.

.EXAMPLE
    .\SetupExecutables.ps1 -Debug
    Runs the setup script with debug messages enabled.

#>

param(
    [switch]$Debug
)

# Debugging flags
$script:MODULE_NAME = "SetupExecutables"
$script:DEBUG_SCRIPT = $Debug
$script:WRITE_TO_DEBUG = $DebugProfile -or $script:DEBUG_SCRIPT

# List of scripts to be linked
$scriptNames = @(
    "WingetUpdate",
    "Win-Top",
    "DownloadAddToPath",
    "symlink",
    "Add-Varible",
    "addtopath",
    "addtouserpath",
    "AddFirewallException",
    "Grant-FolderAccess",
    "LinkModule",
    "PermissionsHelper",
    "RemoveDeadLink",
    "SetNotReadOnly"
)

# Ensure bin directory exists
if (!(Test-Path $PWSH_BIN_DIR)) {
    Write-Debug -Message "Creating bin directory: $PWSH_BIN_DIR" -Channel "Info"
    try {
        New-Item -ItemType Directory -Path $PWSH_BIN_DIR -ErrorAction Stop | Out-Null
    } catch {
        Write-Debug -Message "Failed to create bin directory: $PWSH_BIN_DIR. Ensure you have necessary permissions." -Channel "Error"
        exit 1
    }
}

<#
.SYNOPSIS
    Creates hard or symbolic links for specified scripts.

.DESCRIPTION
    Searches for predefined scripts in the scripts directory and creates links in the bin directory.

#>
function Setup-ExecutableLinks {
    foreach ($script in $scriptNames) {
        # Ensure script name has .ps1 extension
        if ($script -notmatch "\.ps1$") {
            $script = "$script.ps1"
        }
        
        Write-Debug -Message "Searching for script: $script" -Channel "Verbose"
        $foundScripts = Get-ChildItem -Path $PWSH_SCRIPT_DIR -Recurse -Filter $script -File
        
        foreach ($foundScript in $foundScripts) {
            $targetPath = "$PWSH_BIN_DIR\$($foundScript.Name)"
            
            if (!(Test-Path $targetPath)) {
                Write-Debug -Message "Creating hard-link: $targetPath -> $($foundScript.FullName)" -Channel "Success"
                New-FileLink -SourcePath $foundScript.FullName -TargetPath $targetPath
            } else {
                Write-Debug -Message "Hard-link already exists: $targetPath" -Channel "Warning"
            }
        }
    }
}

<#
.SYNOPSIS
    Ensures the bin directory is in the user's or system's PATH.

.DESCRIPTION
    Adds the bin directory to the user's or system's PATH if it is not already present.

#>
function Setup-PathVariable {
    Write-Debug -Message "Ensuring $PWSH_BIN_DIR is in the user's PATH" -Channel "Information"
    Set-PathVariable -PathToAdd $PWSH_BIN_DIR
}

# Execute setup functions
Setup-ExecutableLinks
Setup-PathVariable

