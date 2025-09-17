# TmuxModule.psm1
<#
.SYNOPSIS
    Tmux integration module for PowerShell, mirroring Zsh/common tmux helpers.
.DESCRIPTION
    Provides cross-platform tmux session and window management functions
    designed for ease of use and consistency with common tmux workflows.
    Requires tmux to be installed and in PATH.
    Requires fzf to be installed and in PATH for fuzzy finding functions (tsf, tsd).
.NOTES
    Author: Your Name
    Version: 1.1
#>

# Import Auto-Export helper (adjust path if needed)
#
if (-not (Get-Module -Name AutoExportModule)) {
    Import-Module "$PSScriptRoot\AutoExportModule.psm1" -ErrorAction Stop
}

# Import Guard
if (-not $script:ModuleImportedTmuxModule) {
    $script:ModuleImportedTmuxModule = $true
} else {
    Write-Debug -Message 'Attempting to import TmuxModule twice!' `
                -Channel 'Error' -Condition $DebugProfile -FileAndLine
    return
}

# Capture existing aliases before we define our own
$preExistingAliases = Get-Alias | Select-Object -ExpandProperty Name
# --- Helper Function ---

function Test-Tmux {
    [CmdletBinding()]
    param()
    if (-not (Get-Command tmux -ErrorAction SilentlyContinue)) {
        Write-Error "tmux is not installed or not in PATH."
        return $false
    }
    return $true
}

# --- Core Functions ---

<#
.SYNOPSIS
    Attach to an existing tmux session or create a new one.
.DESCRIPTION
    If inside a tmux session, switches to the target session.
    If outside tmux, attaches to the target session.
    If the target session does not exist, creates a new session with that name.
    Defaults to session name '1'.
.PARAMETER Session
    The name of the tmux session to attach to, switch to, or create. Defaults to '1'.
.EXAMPLE
    ts
    # Attaches to session '1', or creates it if it doesn't exist.
.EXAMPLE
    ts -Session "myproject"
    # Attaches to session 'myproject', or creates it.
.EXAMPLE
    ts "dev"
    # Attaches to session 'dev', or creates it.
#>
function ts {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, ValueFromPipeline=$false, HelpMessage="Name of the tmux session.")]
        [string]$Session = '1'
    )

    if (-not (Test-Tmux)) { return }

    $existingSessions = & tmux list-sessions -F '#{session_name}' 2>$null
    $sessionExists = $false
    if ($existingSessions -is [array]) {
        if ($existingSessions -contains $Session) {
            $sessionExists = $true
        }
    } elseif ($existingSessions -is [string]) {
        if ($existingSessions -eq $Session) {
            $sessionExists = $true
        }
    }

    if ($sessionExists) {
        if ($env:TMUX) {
            Write-Verbose "Inside tmux. Switching to session: $Session"
            & tmux switch-client -t $Session
        } else {
            Write-Verbose "Outside tmux. Attaching to session: $Session"
            & tmux attach-session -t $Session
        }
    } else {
        Write-Verbose "Session '$Session' not found. Creating new session."
        $commandToRun = ""
        if ($IsWindows) {
            if (Get-Command pwsh -ErrorAction SilentlyContinue) {
                $commandToRun = "pwsh"
            } elseif (Get-Command powershell -ErrorAction SilentlyContinue) {
                $commandToRun = "powershell"
            }
        }
        # For Linux/macOS, tmux will use default-shell or default-command from .tmux.conf
        # If $commandToRun is empty, tmux uses its default.
        if ($commandToRun) {
             Write-Verbose "Starting new session '$Session' with command: $commandToRun"
            & tmux new-session -s $Session -n "shell" $commandToRun
        } else {
             Write-Verbose "Starting new session '$Session' with default shell."
            & tmux new-session -s $Session -n "shell"
        }
    }
}

<#
.SYNOPSIS
    List all current tmux sessions.
.DESCRIPTION
    Displays a list of all active tmux sessions.
    If no sessions are active, it will indicate that.
.EXAMPLE
    tsl
#>
function tsl {
    [CmdletBinding()]
    param()

    if (-not (Test-Tmux)) { return }

    $sessions = & tmux list-sessions 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $sessions) {
        Write-Host "No tmux sessions."
    } else {
        Write-Output $sessions
    }
}

<#
.SYNOPSIS
    Attach to a new or existing tmux session by specific name (alias for ts).
.DESCRIPTION
    Functionally identical to 'ts'. Creates a session if it doesn't exist,
    otherwise attaches or switches to it.
.PARAMETER Session
    The mandatory name of the tmux session.
.EXAMPLE
    tsn "project-alpha"
#>
function tsn {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true, HelpMessage="Name of the tmux session.")]
        [string]$Session
    )
    if (-not (Test-Tmux)) { return }
    ts -Session $Session
}

<#
.SYNOPSIS
    Fuzzy find and attach to a tmux session.
.DESCRIPTION
    Uses fzf to provide a fuzzy searchable list of existing tmux sessions.
    The selected session is then attached to or switched to using 'ts'.
    Requires 'fzf' to be installed and in PATH.
.EXAMPLE
    tsf
#>
function tsf {
    [CmdletBinding()]
    param()

    if (-not (Test-Tmux)) { return }
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Error "fzf is not installed or not in PATH. tsf cannot function."
        return
    }

    $sessions = & tmux list-sessions -F '#{session_name}' 2>$null
    if (-not $sessions) {
        Write-Host "No tmux sessions to select from."
        return
    }

    $selection = $sessions | fzf
    if ($selection) {
        ts -Session $selection
    } else {
        Write-Verbose "No session selected from fzf."
    }
}

<#
.SYNOPSIS
    Fuzzy find and attach to a DETACHED tmux session.
.DESCRIPTION
    Uses fzf to provide a fuzzy searchable list of currently detached tmux sessions.
    The selected session is then attached to or switched to using 'ts'.
    Requires 'fzf' to be installed and in PATH.
.EXAMPLE
    tsd
#>
function tsd {
    [CmdletBinding()]
    param()

    if (-not (Test-Tmux)) { return }
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Error "fzf is not installed or not in PATH. tsd cannot function."
        return
    }

    $detachedItems = & tmux list-sessions -F '#{session_name} #{session_attached}' 2>$null |
        Where-Object { $_ -match '\s0$' } | # Session is detached (attached count is 0)
        ForEach-Object { ($_ -split ' ')[0] }

    if (-not $detachedItems) {
        Write-Host "No detached tmux sessions."
        return
    }

    $selection = $detachedItems | fzf
    if ($selection) {
        ts -Session $selection
    } else {
        Write-Verbose "No detached session selected from fzf."
    }
}

<#
.SYNOPSIS
    Re-attach to the last detached tmux session.
.DESCRIPTION
    Finds the most recently detached tmux session (last in the list of detached sessions)
    and attaches to it using 'ts'.
.EXAMPLE
    tsr
#>
function tsr {
    [CmdletBinding()]
    param()

    if (-not (Test-Tmux)) { return }

    $lastDetached = & tmux list-sessions -F '#{session_name} #{session_attached}' 2>$null |
        Where-Object { $_ -match '\s0$' } |
        ForEach-Object { ($_ -split ' ')[0] } |
        Select-Object -Last 1

    if ($lastDetached) {
        Write-Verbose "Re-attaching to last detached session: $lastDetached"
        ts -Session $lastDetached
    } else {
        Write-Host "No detached tmux sessions found."
    }
}

<#
.SYNOPSIS
    Create and attach to the next available numerically named session (ts1, ts2, etc.).
.DESCRIPTION
    Finds the lowest positive integer 'N' such that a session named 'tsN'
    does not already exist, then creates and attaches to 'tsN' using 'ts'.
.EXAMPLE
    tsnxt
    # If ts1 exists, but ts2 doesn't, creates and attaches to ts2.
#>
function tsnxt {
    [CmdletBinding()]
    param()

    if (-not (Test-Tmux)) { return }

    $idx = 1
    $existingSessions = & tmux list-sessions -F '#{session_name}' 2>$null
    $nextSessionName = ""

    while ($true) {
        $potentialName = "ts$idx"
        $nameExists = $false
        if ($existingSessions -is [array]) {
            if ($existingSessions -contains $potentialName) {
                $nameExists = $true
            }
        } elseif ($existingSessions -is [string]) {
            if ($existingSessions -eq $potentialName) {
                $nameExists = $true
            }
        }

        if (-not $nameExists) {
            $nextSessionName = $potentialName
            break
        }
        $idx++
        if ($idx -gt 1000) { # Safety break
            Write-Error "Could not find an available 'tsN' session name after 1000 attempts."
            return
        }
    }
    
    Write-Verbose "Next available session name: $nextSessionName"
    ts -Session $nextSessionName
}

<#
.SYNOPSIS
    Rename the current tmux session.
.DESCRIPTION
    If currently inside a tmux session, renames the current session to the NewName.
.PARAMETER NewName
    The new name for the current tmux session.
.EXAMPLE
    tsrename "my-new-project-name"
#>
function tsrename {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true, HelpMessage="The new name for the session.")]
        [string]$NewName
    )

    if (-not (Test-Tmux)) { return }

    if (-not $env:TMUX) {
        Write-Warning "Not inside a tmux session. Cannot rename."
        return
    }

    & tmux rename-session $NewName
    Write-Host "Current tmux session renamed to: $NewName"
}

<#
.SYNOPSIS
    Detach the current tmux client.
.DESCRIPTION
    If currently inside a tmux session, detaches the client from the session,
    leaving the session running in the background.
.EXAMPLE
    tmd
#>
function tmd {
    [CmdletBinding()]
    param()

    if (-not (Test-Tmux)) { return }

    if (-not $env:TMUX) {
        Write-Warning "Not inside a tmux session. Nothing to detach from."
        return
    }
    
    Write-Verbose "Detaching tmux client."
    & tmux detach-client
}
# === Auto-export all new functions and aliases ===
# (throws nothing if nothing new to export)
Export-AutoExportFunctions -Exclude @()          # no functions to exclude
Export-AutoExportAliases   -Exclude $preExistingAliases
