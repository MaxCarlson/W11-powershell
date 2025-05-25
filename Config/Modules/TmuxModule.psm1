# TmuxModule.psm1

# Import AutoExport helper
. "$PSScriptRoot\AutoExportModule.psm1"

# Capture existing aliases to exclude from auto-export
$preExistingAliases = Get-Alias | Select-Object -ExpandProperty Name

<#
.SYNOPSIS
    Start or attach to a tmux session running native Bash.
.DESCRIPTION
    Creates or attaches to a tmux session named by -Session, defaulting to 'bash'.
.PARAMETER Session
    Name of the tmux session. Defaults to 'bash'.
.EXAMPLE
    Start-TmuxBashSession
    # Creates or attaches to session 'bash'.
.EXAMPLE
    Start-TmuxBashSession -Session dev
    # Creates or attaches to session 'dev'.
#>
function Start-TmuxBashSession {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Session = 'bash'
    )
    tmux new-session -A -s $Session
}

<#
.SYNOPSIS
    Start or attach to a tmux session running PowerShell 7.
.DESCRIPTION
    Creates or attaches to a tmux session named by -Session running pwsh, defaulting to 'pwsh'.
.PARAMETER Session
    Name of the tmux session. Defaults to 'pwsh'.
.EXAMPLE
    Start-TmuxPwshSession
    # Creates or attaches to session 'pwsh'.
#>
function Start-TmuxPwshSession {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Session = 'pwsh'
    )
    $pwshCmd = '/cygdrive/c/Progra~1/PowerShell/7/pwsh.exe -NoLogo -NoExit'
    tmux new-session -A -s $Session $pwshCmd
}

<#
.SYNOPSIS
    List tmux sessions named 'bash*'.
.EXAMPLE
    Get-TmuxBashSessions
#>
function Get-TmuxBashSessions {
    tmux list-sessions -F "#{session_name}: #{?session_attached,attached,detached}" |
        Where-Object { $_ -match '^[bB]ash:' }
}

<#
.SYNOPSIS
    List tmux sessions named 'pwsh*'.
.EXAMPLE
    Get-TmuxPwshSessions
#>
function Get-TmuxPwshSessions {
    tmux list-sessions -F "#{session_name}: #{?session_attached,attached,detached}" |
        Where-Object { $_ -match '^[pP]wsh:' }
}

<#
.SYNOPSIS
    Attach to the most recent detached tmux session of a given type, or start one if none exist.
.PARAMETER Type
    Type of session: 'bash' or 'pwsh'.
.EXAMPLE
    Enter-TmuxLatestSession -Type bash
    # Attaches to the newest detached 'bash*' session or starts one.
#>
function Enter-TmuxLatestSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('bash','pwsh')]
        [string]$Type
    )

    $lines = tmux list-sessions -F "#{session_name} #{session_created} #{?session_attached,attached,detached}"
    $sessions = $lines | ForEach-Object {
        $parts = $_ -split ' '
        [PSCustomObject]@{
            Name    = $parts[0]
            Created = [int]$parts[1]
            Status  = $parts[2]
        }
    }

    $latest = $sessions |
        Where-Object { $_.Name -like "$Type*" -and $_.Status -eq 'detached' } |
        Sort-Object Created -Descending |
        Select-Object -First 1

    if (-not $latest) {
        # No detached session → start one
        Write-Debug "No detached $Type sessions; starting new '$Type' session." -Condition $DebugProfile
        $funcName = "Start-Tmux$($Type.Substring(0,1).ToUpper() + $Type.Substring(1))Session"
        & $funcName -Session $Type
        return
    }

    tmux attach-session -t $latest.Name
}

<#
.SYNOPSIS
    Attach to the latest detached 'bash*' session.
.EXAMPLE
    Enter-TmuxLatestBashSession
#>
function Enter-TmuxLatestBashSession { Enter-TmuxLatestSession -Type 'bash' }

<#
.SYNOPSIS
    Attach to the latest detached 'pwsh*' session.
.EXAMPLE
    Enter-TmuxLatestPwshSession
#>
function Enter-TmuxLatestPwshSession { Enter-TmuxLatestSession -Type 'pwsh' }

# === Short, tmux-prefixed aliases ===
New-Alias -Name tmuxbs -Value Start-TmuxBashSession
New-Alias -Name tmuxps -Value Start-TmuxPwshSession
New-Alias -Name tmuxlb -Value Get-TmuxBashSessions
New-Alias -Name tmuxlp -Value Get-TmuxPwshSessions
New-Alias -Name tmuxeb -Value Enter-TmuxLatestBashSession
New-Alias -Name tmuxep -Value Enter-TmuxLatestPwshSession

# === Auto-export all new functions and aliases ===
Export-AutoExportFunctions -Exclude @()
Export-AutoExportAliases   -Exclude $preExistingAliases

