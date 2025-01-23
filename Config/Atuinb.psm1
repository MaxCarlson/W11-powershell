# Atuin PowerShell Initialization Module

# Ensure Atuin session environment variables are set
$env:ATUIN_SESSION = $(atuin uuid)
$env:ATUIN_HISTORY_PATH = "$HOME\.local\share\atuin\history"
$env:ATUIN_PREEXEC_BACKEND = "powershell"

# Initialize Atuin session
Write-Host "Initializing Atuin session: $env:ATUIN_SESSION"
Write-Host "History Path: $env:ATUIN_HISTORY_PATH"

# Helper: Start tracking commands in Atuin
function Start-AtuinHistory {
    param (
        [string]$Command
    )
    try {
        # Start Atuin history tracking for the executed command
        $global:ATUIN_HISTORY_ID = atuin history start -- $Command
        Write-Host "Atuin tracking command: $Command"
    } catch {
        Write-Host "Failed to track command with Atuin: $_" -ForegroundColor Red
    }
}

# Helper: Stop tracking commands in Atuin
function Stop-AtuinHistory {
    param (
        [int]$ExitCode
    )
    try {
        # End Atuin history tracking for the executed command
        if ($global:ATUIN_HISTORY_ID) {
            atuin history end --exit $ExitCode -- $global:ATUIN_HISTORY_ID | Out-Null
            $global:ATUIN_HISTORY_ID = $null
        }
    } catch {
        Write-Host "Failed to end command tracking in Atuin: $_" -ForegroundColor Red
    }
}

# Function to search through Atuin history
function Search-AtuinHistory {
    try {
        atuin search
    } catch {
        Write-Host "Atuin search failed: $_" -ForegroundColor Red
    }
}

# Function to show Atuin reverse history
function Show-AtuinHistory {
    try {
        atuin search --reverse
    } catch {
        Write-Host "Atuin reverse history failed: $_" -ForegroundColor Red
    }
}

# Hook to track commands before execution
function PreCommand-Hook {
    param (
        [string]$Command
    )
    if ($Command) {
        Start-AtuinHistory -Command $Command
    }
}

# Hook to track commands after execution
function PostCommand-Hook {
    param (
        [int]$ExitCode
    )
    Stop-AtuinHistory -ExitCode $ExitCode
}

# Hook into PowerShell's prompt system
function Prompt {
    # Capture the last command
    $LastCommand = (Get-History -Count 1).CommandLine

    # If there's a command, track it
    if ($LastCommand) {
        PreCommand-Hook -Command $LastCommand
    }

    # Return a custom prompt
    return "PS > "
}

# Keybinding for Ctrl+R to search Atuin history
Set-PSReadLineKeyHandler -Chord "Ctrl+r" -ScriptBlock {
    param($key, $line)
    if ($line) {
        Search-AtuinHistory -Query $line
    } else {
        Search-AtuinHistory
    }
} -BriefDescription "Search Atuin History" -LongDescription "Search through your Atuin history"

# Keybinding for Ctrl+G to show Atuin reverse history
Set-PSReadLineKeyHandler -Chord "Ctrl+g" -ScriptBlock {
    Show-AtuinHistory
} -BriefDescription "Show Atuin History" -LongDescription "Display the full Atuin history list"

# Register an event to finalize Atuin history on session exit
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    try {
        PostCommand-Hook -ExitCode 0
    } catch {
        Write-Debug -Message "Error while ending Atuin history: $_" -Channel "Error"
    }
} | Out-Null

# Export module members
Export-ModuleMember -Function Start-AtuinHistory, Stop-AtuinHistory, Search-AtuinHistory, Show-AtuinHistory
