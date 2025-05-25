<#
.SYNOPSIS
    Manage and attach to tmux sessions for Bash or PowerShell 7.

.DESCRIPTION
    Provides cmdlets with approved verbs to start, list, and enter tmux sessions 
    running either your native Bash login shell or a full‐profile PowerShell 7 
    (Oh-My-Posh) session. Also defines six short aliases for quick use.

.NOTES
    Path: C:\Users\mcarls\Repos\W11-powershell\Config\Modules\TmuxModule.psm1
    Requires: tmux (via Cygwin or WSL), PowerShell 7 in Program Files.
#>

<#
.SYNOPSIS
    Start a new tmux session running Bash.
.PARAMETER Session
    Name of the tmux session. Defaults to 'bash'.
.EXAMPLE
    Start-TmuxBashSession
    # Creates (or attaches to) session called "bash".
.EXAMPLE
    Start-TmuxBashSession -Session dev
    # Creates (or attaches to) session called "dev".
#>
function Start-TmuxBashSession {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Session = 'bash'
    )
    tmux new-session -s $Session
}

<#
.SYNOPSIS
    Start a new tmux session running PowerShell 7.
.PARAMETER Session
    Name of the tmux session. Defaults to 'pwsh'.
.EXAMPLE
    Start-TmuxPwshSession
    # Creates (or attaches to) session called "pwsh".
#>
function Start-TmuxPwshSession {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Session = 'pwsh'
    )
    $pwshCmd = '/cygdrive/c/Progra~1/PowerShell/7/pwsh.exe -NoLogo -NoExit'
    tmux new-session -s $Session $pwshCmd
}

<#
.SYNOPSIS
    List tmux sessions whose names begin with 'bash'.
.EXAMPLE
    Get-TmuxBashSessions
#>
function Get-TmuxBashSessions {
    tmux list-sessions -F "#{session_name}: #{?session_attached,attached,detached}" |
      Where-Object { $_ -match '^[bB]ash:' }
}

<#
.SYNOPSIS
    List tmux sessions whose names begin with 'pwsh'.
.EXAMPLE
    Get-TmuxPwshSessions
#>
function Get-TmuxPwshSessions {
    tmux list-sessions -F "#{session_name}: #{?session_attached,attached,detached}" |
      Where-Object { $_ -match '^[pP]wsh:' }
}

<#
.SYNOPSIS
    Attach to the most recently created detached tmux session of a given type.
.PARAMETER Type
    'bash' or 'pwsh'
.EXAMPLE
    Enter-TmuxLatestBashSession
    # Attaches to the newest detached 'bash*' session.
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
        Write-Warning "No detached $Type sessions found."
        return
    }
    tmux attach-session -t $latest.Name
}

<#
.SYNOPSIS
    Attach to the most recent detached 'bash*' tmux session.
#>
function Enter-TmuxLatestBashSession { Enter-TmuxLatestSession -Type 'bash' }

<#
.SYNOPSIS
    Attach to the most recent detached 'pwsh*' tmux session.
#>
function Enter-TmuxLatestPwshSession { Enter-TmuxLatestSession -Type 'pwsh' }

# Export only approved‐verb commands:
Export-ModuleMember -Function `
    Start-TmuxBashSession, Start-TmuxPwshSession, `
    Get-TmuxBashSessions, Get-TmuxPwshSessions, `
    Enter-TmuxLatestBashSession, Enter-TmuxLatestPwshSession

# Short aliases
Set-Alias tmb  Start-TmuxBashSession       -Option AllScope
Set-Alias tmp  Start-TmuxPwshSession       -Option AllScope
Set-Alias gtb  Get-TmuxBashSessions        -Option AllScope
Set-Alias gtp  Get-TmuxPwshSessions        -Option AllScope
Set-Alias jtb  Enter-TmuxLatestBashSession -Option AllScope
Set-Alias jtp  Enter-TmuxLatestPwshSession -Option AllScope

