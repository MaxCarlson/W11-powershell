## Atuin PowerShell Initialization Module
#
## Set a unique history path for PowerShell to separate from Linux/zsh history
#$env:ATUIN_DATA_PATH = "$HOME\.local\share\atuin-powershell"
#
## Ensure Atuin session environment variables are set
#$env:ATUIN_SESSION = $(atuin uuid)
#$env:ATUIN_HISTORY_PATH = "$env:ATUIN_DATA_PATH\history"
#$env:ATUIN_PREEXEC_BACKEND = "powershell"
#
## Initialize Atuin session
#Write-Debug -Message "Initializing Atuin session: $env:ATUIN_SESSION" -Condition $WRITE_TO_DEBUG
#Write-Debug -Message "History Path: $env:ATUIN_HISTORY_PATH" -Condition $WRITE_TO_DEBUG
#
## Helper: Start tracking a command in Atuin
#function Start-AtuinHistory {
#    param (
#        [string]$Command
#    )
#    try {
#        # Track the command in Atuin
#        $global:ATUIN_HISTORY_ID = atuin history start -- $Command
#        Write-Debug -Message "Atuin tracking command: $Command" -Condition $WRITE_TO_DEBUG
#    } catch {
#        Write-Debug -Message "Failed to track command with Atuin: $_" -Channel "Error" -Condition $WRITE_TO_DEBUG
#    }
#}
#
## Helper: Stop tracking a command in Atuin
#function Stop-AtuinHistory {
#    param (
#        [int]$ExitCode
#    )
#    try {
#        # Close Atuin history tracking
#        if ($global:ATUIN_HISTORY_ID) {
#            atuin history end --exit $ExitCode -- $global:ATUIN_HISTORY_ID | Out-Null
#            $global:ATUIN_HISTORY_ID = $null
#        }
#    } catch {
#        Write-Debug -Message "Failed to end command tracking in Atuin: $_" -Channel "Error" -Condition $WRITE_TO_DEBUG
#    }
#}
#
## Hook into the prompt system to capture the last command
#function Prompt {
#    # Capture the last executed command
#    $LastCommand = (Get-History -Count 1 | Select-Object -ExpandProperty CommandLine)
#    if ($LastCommand -and $LastCommand -ne $global:LAST_CAPTURED_COMMAND) {
#        $global:LAST_CAPTURED_COMMAND = $LastCommand
#        Start-AtuinHistory -Command $LastCommand
#    }
#
#    # Return the custom prompt
#    return "PS > "
#}
#
## Function to search Atuin history
#function Search-AtuinHistory {
#    try {
#        atuin search
#    } catch {
#        Write-Debug -Message "Atuin search failed: $_" -Channel "Error" -Condition $WRITE_TO_DEBUG
#    }
#}
#
## Function to show Atuin history in reverse
#function Show-AtuinHistory {
#    try {
#        atuin search --reverse
#    } catch {
#        Write-Debug -Message "Atuin reverse history failed: $_" -Channel "Error" -Condition $WRITE_TO_DEBUG
#    }
#}
#
## Set key bindings for Atuin
#Set-PSReadLineKeyHandler -Chord "Ctrl+r" -ScriptBlock {
#    Search-AtuinHistory
#} -BriefDescription "Search Atuin History" -LongDescription "Search through your Atuin history"
#
#Set-PSReadLineKeyHandler -Chord "Ctrl+g" -ScriptBlock {
#    Show-AtuinHistory
#} -BriefDescription "Show Atuin History" -LongDescription "Display the reverse Atuin history"
#
## Register an event to finalize Atuin history on session exit
#Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
#    try {
#        Stop-AtuinHistory -ExitCode $global:LASTEXITCODE
#    } catch {
#        Write-Debug -Message -Message "Error while ending Atuin history: $_" -Channel "Error" -Condition $WRITE_TO_DEBUG
#    }
#} | Out-Null
#
## Exported functions
#Export-ModuleMember -Function Start-AtuinHistory, Stop-AtuinHistory, Search-AtuinHistory, Show-AtuinHistory

# Atuin PowerShell Initialization Module

# Ensure Atuin session environment variables are set


# Atuin PowerShell Initialization Module
# Atuin PowerShell Initialization Module

# Set Atuin session and history path
$atuinCommand = Get-Command atuin -ErrorAction SilentlyContinue
if (-not $atuinCommand) {
    Write-Warning "Atuin not found in PATH; skipping Atuin module."
    return
}

$script:ATUIN_DEBUG=$false
$script:WRITE_TO_DEBUG= $ATUIN_DEBUG -or $DebugProfile
$env:ATUIN_SESSION = $(atuin uuid)
$env:ATUIN_HISTORY_PATH = "$HOME\.local\share\atuin\history.db"
Write-Debug -Message "Initializing Atuin session: $env:ATUIN_SESSION" -Condition $ATUIN_DEBUG
Write-Debug -Message "History Path: $env:ATUIN_HISTORY_PATH" -Condition $ATUIN_DEBUG

# Function to log commands into Atuin
function Log-AtuinHistory {
    param (
        [string]$Command
    )
    try {
        if ($Command -and $Command -ne $global:LastTrackedCommand) {
            $global:LastTrackedCommand = $Command
            $global:ATUIN_HISTORY_ID = atuin history start -- $Command
            Write-Debug -Message "Atuin tracking command: $Command" -Condition $ATUIN_DEBUG
        }
    } catch {
        Write-Debug -Message "Failed to track command with Atuin: $_" -Channel "Error" -Condition $WRITE_TO_DEBUG
    }
}

# Finalize Atuin history tracking
function Stop-AtuinHistory {
    param (
        [int]$ExitCode
    )
    try {
        if ($global:ATUIN_HISTORY_ID) {
            atuin history end --exit $ExitCode -- $global:ATUIN_HISTORY_ID | Out-Null
            $global:ATUIN_HISTORY_ID = $null
        }
    } catch {
        Write-Debug -Message "Failed to finalize Atuin history: $_" -Channel "Error" -Condition $WRITE_TO_DEBUG
    }
}

# Hook into PSReadLine to process each command added to the history
Set-PSReadLineOption -AddToHistoryHandler {
    param($line)
    # Log the command to Atuin
    Log-AtuinHistory -Command $line
    # Return $true to allow the command to be added to the native history
    return $true
}

# Debugging tools
function Debug-AtuinHistory {
    Write-Debug -Message "Current Command: $((Get-History -Count 1).CommandLine)" -Channel "Information" -Condition $WRITE_TO_DEBUG
    Write-Debug -Message "Last Atuin History ID: $global:ATUIN_HISTORY_ID" -Channel "Warning" -Condition $WRITE_TO_DEBUG
}

# Keybindings for Atuin commands
Set-PSReadLineKeyHandler -Chord "Ctrl+r" -ScriptBlock {
    atuin search
} -BriefDescription "Search Atuin History"

Set-PSReadLineKeyHandler -Chord "Ctrl+g" -ScriptBlock {
    atuin history list
} -BriefDescription "Show Atuin History"

# Cleanup Atuin history on session exit
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Stop-AtuinHistory -ExitCode $global:LASTEXITCODE
} | Out-Null

# Exported functions
Export-ModuleMember -Function Log-AtuinHistory, Stop-AtuinHistory, Debug-AtuinHistory
