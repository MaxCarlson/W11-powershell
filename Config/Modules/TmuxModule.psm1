# TmuxModule.psm1

# Import AutoExport helper
# Ensure AutoExportModule.psm1 exists in the same directory or provide the correct path.
if (Test-Path -Path "$PSScriptRoot\AutoExportModule.psm1") {
    . "$PSScriptRoot\AutoExportModule.psm1"
} else {
    Write-Warning "AutoExportModule.psm1 not found at $PSScriptRoot. Auto-export features may not work."
}

# Capture existing aliases to exclude from auto-export
$preExistingAliases = Get-Alias | Select-Object -ExpandProperty Name

<#
.SYNOPSIS
    Start or attach to a tmux session running native Bash.
.DESCRIPTION
    Creates or attaches to a tmux session named by -Session, defaulting to 'bash'.
.PARAMETER Session
    Name of the tmux session. Defaults to 'bash'.
    Allows providing a custom name for the session.
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
    Write-Host "DEBUG: Entering Start-TmuxBashSession for session '${Session}'."
    $tmuxCmdInfo = Get-Command tmux -ErrorAction SilentlyContinue
    if (-not $tmuxCmdInfo) {
        Write-Error "DEBUG: tmux command not found in Start-TmuxBashSession. Please ensure tmux is installed and in your PATH."
        return
    }
    Write-Host "DEBUG: tmux command found at: $($tmuxCmdInfo.Source)"
    Write-Host "DEBUG: Starting or attaching to tmux session '${Session}' with bash."
    
    # Using call operator for external command
    & tmux new-session -A -s "${Session}"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "DEBUG: tmux command to start/attach session '${Session}' (bash) may have failed. LASTEXITCODE: ${LASTEXITCODE}"
    } else {
        Write-Host "DEBUG: tmux new-session -A -s '${Session}' (bash) completed. LASTEXITCODE: ${LASTEXITCODE}"
    }
}

<#
.SYNOPSIS
    Start or attach to a tmux session running PowerShell.
.DESCRIPTION
    Creates or attaches to a tmux session named by -Session running pwsh, defaulting to 'pwsh'.
    The 'pwsh' command is expected to be in the PATH of the tmux server environment.
.PARAMETER Session
    Name of the tmux session. Defaults to 'pwsh'.
    Allows providing a custom name for the session.
.EXAMPLE
    Start-TmuxPwshSession
    # Creates or attaches to session 'pwsh'.
.EXAMPLE
    Start-TmuxPwshSession -Session projectX
    # Creates or attaches to session 'projectX' running pwsh.
#>
function Start-TmuxPwshSession {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Session = 'pwsh'
    )
    Write-Host "DEBUG: Entering Start-TmuxPwshSession for session '${Session}'."
    $tmuxCmdInfo = Get-Command tmux -ErrorAction SilentlyContinue
    if (-not $tmuxCmdInfo) {
        Write-Error "DEBUG: tmux command not found in Start-TmuxPwshSession. Please ensure tmux is installed and in your PATH."
        return
    }
    Write-Host "DEBUG: tmux command found at: $($tmuxCmdInfo.Source)"

    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
        Write-Warning "DEBUG: pwsh command not found in the current PowerShell session's PATH. Ensure 'pwsh' is available in the tmux server's environment PATH."
    }
    
    $pwshCmd = 'pwsh -NoLogo -NoExit' 
    Write-Host "DEBUG: Starting or attaching to tmux session '${Session}' with command '${pwshCmd}'."
    
    # Using call operator for external command
    & tmux new-session -A -s "${Session}" "${pwshCmd}"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "DEBUG: tmux command to start/attach session '${Session}' with pwsh may have failed. LASTEXITCODE: ${LASTEXITCODE}"
    } else {
        Write-Host "DEBUG: tmux new-session -A -s '${Session}' with pwsh completed. LASTEXITCODE: ${LASTEXITCODE}"
    }
}

# Helper function for debug testing tmux list-sessions
function Invoke-TmuxListSessionsForDebug {
    [CmdletBinding()]
    param(
        [string]$TestId # e.g., "Get-TmuxBashSessions"
    )
    
    $tmuxCommand = "tmux"
    $tmuxBaseArgs = @("list-sessions", "-F", "#{session_name}: #{?session_attached,attached,detached}")
    
    Write-Host "DEBUG (${TestId}): Preparing to call tmux."
    Write-Host "DEBUG (${TestId}): Command: ${tmuxCommand}"
    Write-Host "DEBUG (${TestId}): Arguments: $($tmuxBaseArgs -join ' ')"

    # Test 1: Using call operator '&' with an arguments array
    Write-Host "DEBUG (${TestId}): === TEST 1: Attempting '& ${tmuxCommand} @(${tmuxBaseArgs -join ','})'. Expect output or freeze. ==="
    $rawOutputTest1 = @() 
    $exceptionTest1 = $null
    $lastExitCodeTest1 = -1
    try {
        $rawOutputTest1 = & $tmuxCommand $tmuxBaseArgs
        $lastExitCodeTest1 = $LASTEXITCODE
        Write-Host "DEBUG (${TestId}): TEST 1: Call operator '&' completed. LASTEXITCODE: ${lastExitCodeTest1}"
    } catch {
        $exceptionTest1 = $_
        Write-Warning "DEBUG (${TestId}): TEST 1: Call operator '&' threw an exception: $($_.Exception.Message)"
    }
    if ($exceptionTest1) { Write-Host "DEBUG (${TestId}): TEST 1: Exception details: $($exceptionTest1 | Out-String)" }
    if ($rawOutputTest1 -ne $null) {
        Write-Host "DEBUG (${TestId}): TEST 1: Output line count: $($rawOutputTest1.Length)"
        $rawOutputTest1 | ForEach-Object { Write-Host "DEBUG_OUT_T1 (${TestId}): $_" }
    } else { Write-Host "DEBUG (${TestId}): TEST 1: No output captured or output was null." }
    Write-Host "DEBUG (${TestId}): === TEST 1 END. ==="

    # Test 2: The @(...) redirection method (kept for comparison)
    Write-Host "DEBUG (${TestId}): === TEST 2: Attempting '@(${tmuxCommand} $($tmuxBaseArgs -join ' ') 2>&1)'. Expect output or freeze. ==="
    $sessionLinesTest2 = @() 
    $exceptionTest2 = $null
    $lastExitCodeTest2 = -1
    try {
        # For @() to work correctly with arguments containing spaces, they might need individual quoting within the string
        # or ensure the command string is constructed carefully.
        # For simplicity and direct comparison to previous attempts, keeping it similar.
        $sessionLinesTest2 = @(tmux list-sessions -F "#{session_name}: #{?session_attached,attached,detached}" 2>&1)
        $lastExitCodeTest2 = $LASTEXITCODE
        Write-Host "DEBUG (${TestId}): TEST 2: '@(tmux ... 2>&1)' call completed. LASTEXITCODE from @(): ${lastExitCodeTest2}" 
    } catch {
        $exceptionTest2 = $_
        Write-Warning "DEBUG (${TestId}): TEST 2: '@(tmux ... 2>&1)' call threw an exception: $($_.Exception.Message)"
    }
    if ($exceptionTest2) { Write-Host "DEBUG (${TestId}): TEST 2: Exception details: $($exceptionTest2 | Out-String)" }
    if ($sessionLinesTest2 -ne $null) {
        Write-Host "DEBUG (${TestId}): TEST 2: Output line count: $($sessionLinesTest2.Length)"
        $sessionLinesTest2 | ForEach-Object { Write-Host "DEBUG_OUT_T2 (${TestId}): $_" }
    } else { Write-Host "DEBUG (${TestId}): TEST 2: No output captured or output was null." }
    Write-Host "DEBUG (${TestId}): === TEST 2 END. ==="

    if ($lastExitCodeTest1 -eq 0 -and $rawOutputTest1 -ne $null -and $rawOutputTest1.Count -gt 0) {
        Write-Host "DEBUG (${TestId}): Using output from TEST 1 (call operator)."
        return $rawOutputTest1, $lastExitCodeTest1
    } elseif ($lastExitCodeTest2 -eq 0 -and $sessionLinesTest2 -ne $null -and $sessionLinesTest2.Count -gt 0) {
        Write-Host "DEBUG (${TestId}): Using output from TEST 2 (@(...)) as TEST 1 failed or was empty."
        return $sessionLinesTest2, $lastExitCodeTest2
    } elseif ($rawOutputTest1 -ne $null) { 
        Write-Host "DEBUG (${TestId}): TEST 1 (call operator) ran but might not have been successful or was empty. Using its output."
        return $rawOutputTest1, $lastExitCodeTest1
    } else { 
         Write-Host "DEBUG (${TestId}): TEST 1 and TEST 2 failed to produce usable output. Using Test 2's (potentially empty) output as a last resort."
        return $sessionLinesTest2, $lastExitCodeTest2 # Fallback to Test 2 output
    }
}


<#
.SYNOPSIS
    List tmux sessions whose names start with 'bash'.
.DESCRIPTION
    Filters tmux sessions to show only those typically started as bash sessions.
.EXAMPLE
    Get-TmuxBashSessions
#>
function Get-TmuxBashSessions {
    [CmdletBinding()]
    param()
    Write-Host "DEBUG: Entering Get-TmuxBashSessions function..."
    $tmuxCmdInfo = Get-Command tmux -ErrorAction SilentlyContinue
    if (-not $tmuxCmdInfo) {
        Write-Error "DEBUG: tmux command not found in Get-TmuxBashSessions."
        return
    }

    $outputFromHelper, $exitCodeFromHelper = Invoke-TmuxListSessionsForDebug -TestId "Get-TmuxBashSessions"
    $finalSessionLinesToProcess = $outputFromHelper
    $finalExitCode = $exitCodeFromHelper # Corrected variable name
    
    Write-Host "DEBUG (Get-TmuxBashSessions): Processing results. Exit code from helper: ${finalExitCode}"

    if ($finalExitCode -ne 0) {
        if (($finalSessionLinesToProcess -join " ") -match "no server running|failed to connect to server") {
            Write-Host "DEBUG (Get-TmuxBashSessions): No tmux server running or no sessions found."
            return # Exit the function
        }
        # If it's not a "no server" message but still an error, warn but proceed if there's any output
        Write-Warning "DEBUG (Get-TmuxBashSessions): tmux list-sessions had non-zero exit code ${finalExitCode}. Output: $($finalSessionLinesToProcess -join "`n")"
        if ($null -eq $finalSessionLinesToProcess -or $finalSessionLinesToProcess.Count -eq 0) {
            return # No output to process after error
        }
    }
    
    if ($null -eq $finalSessionLinesToProcess -or $finalSessionLinesToProcess.Count -eq 0) {
        Write-Host "DEBUG (Get-TmuxBashSessions): No output from tmux list-sessions to process."
        return
    }
    
    $bashSessions = $finalSessionLinesToProcess | ForEach-Object {
        $line = $_
        if ($line -match '^([^:]+):\s*(attached|detached)$') {
            $sessionName = $Matches[1]
            if ($sessionName -match '^[bB]ash') {
                $line 
            }
        } elseif ($line -notmatch "no server running|failed to connect to server") {
            Write-Host "DEBUG (Get-TmuxBashSessions): Skipping non-session line: ${line}"
        }
    } | Where-Object { $_ -ne $null }

    if ($bashSessions.Count -gt 0) {
        Write-Host "DEBUG (Get-TmuxBashSessions): Filtered bash sessions found. Returning them."
        $bashSessions
    } else {
        Write-Host "DEBUG (Get-TmuxBashSessions): No tmux sessions starting with 'bash' found."
    }
}

<#
.SYNOPSIS
    List tmux sessions whose names start with 'pwsh'.
.DESCRIPTION
    Filters tmux sessions to show only those typically started as PowerShell sessions.
.EXAMPLE
    Get-TmuxPwshSessions
#>
function Get-TmuxPwshSessions {
    [CmdletBinding()]
    param()
    Write-Host "DEBUG: Entering Get-TmuxPwshSessions function..."
    $tmuxCmdInfo = Get-Command tmux -ErrorAction SilentlyContinue
    if (-not $tmuxCmdInfo) {
        Write-Error "DEBUG: tmux command not found in Get-TmuxPwshSessions."
        return
    }

    $outputFromHelper, $exitCodeFromHelper = Invoke-TmuxListSessionsForDebug -TestId "Get-TmuxPwshSessions"
    $finalSessionLinesToProcess = $outputFromHelper
    $finalExitCode = $exitCodeFromHelper # Corrected variable name

    Write-Host "DEBUG (Get-TmuxPwshSessions): Processing results. Exit code from helper: ${finalExitCode}"

    if ($finalExitCode -ne 0) {
        if (($finalSessionLinesToProcess -join " ") -match "no server running|failed to connect to server") {
            Write-Host "DEBUG (Get-TmuxPwshSessions): No tmux server running or no sessions found."
            return # Exit the function
        }
        Write-Warning "DEBUG (Get-TmuxPwshSessions): tmux list-sessions had non-zero exit code ${finalExitCode}. Output: $($finalSessionLinesToProcess -join "`n")"
        if ($null -eq $finalSessionLinesToProcess -or $finalSessionLinesToProcess.Count -eq 0) {
            return # No output to process after error
        }
    }
    
    if ($null -eq $finalSessionLinesToProcess -or $finalSessionLinesToProcess.Count -eq 0) {
        Write-Host "DEBUG (Get-TmuxPwshSessions): No output from tmux list-sessions to process."
        return
    }
    
    $pwshSessions = $finalSessionLinesToProcess | ForEach-Object {
        $line = $_
        if ($line -match '^([^:]+):\s*(attached|detached)$') {
            $sessionName = $Matches[1]
            if ($sessionName -match '^[pP]wsh') {
                $line
            }
        } elseif ($line -notmatch "no server running|failed to connect to server") {
            Write-Host "DEBUG (Get-TmuxPwshSessions): Skipping non-session line: ${line}"
        }
    } | Where-Object { $_ -ne $null }

    if ($pwshSessions.Count -gt 0) {
        Write-Host "DEBUG (Get-TmuxPwshSessions): Filtered pwsh sessions found. Returning them."
        $pwshSessions
    } else {
        Write-Host "DEBUG (Get-TmuxPwshSessions): No tmux sessions starting with 'pwsh' found."
    }
}

<#
.SYNOPSIS
    Attach to the most recent detached tmux session of a given type, or start one if none exist.
.PARAMETER Type
    Type of session: 'bash' or 'pwsh'.
.EXAMPLE
    Enter-TmuxLatestSession -Type bash
#>
function Enter-TmuxLatestSession {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('bash','pwsh')]
        [string]$Type
    )
    Write-Host "DEBUG: Entering Enter-TmuxLatestSession for type '${Type}'."
    $tmuxCmdInfo = Get-Command tmux -ErrorAction SilentlyContinue
    if (-not $tmuxCmdInfo) {
        Write-Error "DEBUG: tmux command not found in Enter-TmuxLatestSession."
        return
    }

    Write-Host "DEBUG (Enter-TmuxLatestSession): Looking for latest detached tmux session of type '${Type}'."
    
    $tmuxCommandEnter = "tmux"
    $tmuxArgsEnter = @("list-sessions", "-F", "#{session_name} #{session_created} #{?session_attached,attached,detached}")

    Write-Host "DEBUG (Enter-TmuxLatestSession): Preparing to call tmux."
    Write-Host "DEBUG (Enter-TmuxLatestSession): Command: ${tmuxCommandEnter}"
    Write-Host "DEBUG (Enter-TmuxLatestSession): Arguments: $($tmuxArgsEnter -join ' ')"


    # Test 1 for Enter-TmuxLatestSession (Call operator)
    Write-Host "DEBUG (Enter-TmuxLatestSession): === TEST 1 (Enter): Attempting '& ${tmuxCommandEnter} @($($tmuxArgsEnter -join ','))'. ==="
    $rawOutputTest1Enter = @()
    $exceptionTest1Enter = $null
    $lastExitCodeTest1Enter = -1
    try {
        $rawOutputTest1Enter = & $tmuxCommandEnter $tmuxArgsEnter
        $lastExitCodeTest1Enter = $LASTEXITCODE
        Write-Host "DEBUG (Enter-TmuxLatestSession): TEST 1 (Enter): Call operator '&' completed. LASTEXITCODE: ${lastExitCodeTest1Enter}"
        if ($rawOutputTest1Enter -ne $null) {
             $rawOutputTest1Enter | ForEach-Object { Write-Host "DEBUG_OUT_T1_Enter: $_" }
        }
    } catch { 
        $exceptionTest1Enter = $_
        Write-Warning "DEBUG (Enter-TmuxLatestSession): TEST 1 (Enter): Call operator '&' Exception: $($_.Exception.Message)" 
    }
    

    # Test 2 for Enter-TmuxLatestSession (@(...) method)
    Write-Host "DEBUG (Enter-TmuxLatestSession): === TEST 2 (Enter): Attempting '@(${tmuxCommandEnter} $($tmuxArgsEnter -join ' ') 2>&1)'. ==="
    $sessionLinesTest2Enter = @()
    $exceptionTest2Enter = $null
    $lastExitCodeTest2Enter = -1
    try {
        $sessionLinesTest2Enter = @(tmux list-sessions -F "#{session_name} #{session_created} #{?session_attached,attached,detached}" 2>&1)
        $lastExitCodeTest2Enter = $LASTEXITCODE
        Write-Host "DEBUG (Enter-TmuxLatestSession): TEST 2 (Enter): '@(tmux ...)' completed. LASTEXITCODE: ${lastExitCodeTest2Enter}"
        if ($sessionLinesTest2Enter -ne $null) {
            $sessionLinesTest2Enter | ForEach-Object { Write-Host "DEBUG_OUT_T2_Enter: $_" }
        }
    } catch { 
        $exceptionTest2Enter = $_
        Write-Warning "DEBUG (Enter-TmuxLatestSession): TEST 2 (Enter): '@(tmux ...)' Exception: $($_.Exception.Message)" 
    }
    

    # Choose which output to process for Enter-TmuxLatestSession
    $tmuxOutputLines = $null
    $chosenExitCode = -1

    if ($lastExitCodeTest1Enter -eq 0 -and $rawOutputTest1Enter -ne $null -and $rawOutputTest1Enter.Count -gt 0) {
        $tmuxOutputLines = $rawOutputTest1Enter
        $chosenExitCode = $lastExitCodeTest1Enter
        Write-Host "DEBUG (Enter-TmuxLatestSession): Using output from TEST 1 (Enter - Call Operator)."
    } elseif ($lastExitCodeTest2Enter -eq 0 -and $sessionLinesTest2Enter -ne $null -and $sessionLinesTest2Enter.Count -gt 0) {
        $tmuxOutputLines = $sessionLinesTest2Enter
        $chosenExitCode = $lastExitCodeTest2Enter
        Write-Host "DEBUG (Enter-TmuxLatestSession): Using output from TEST 2 (Enter - @(...)) as TEST 1 failed or was empty."
    } elseif ($rawOutputTest1Enter -ne $null) { # Fallback to Test 1 output even if exit code wasn't 0
         $tmuxOutputLines = $rawOutputTest1Enter
         $chosenExitCode = $lastExitCodeTest1Enter
        Write-Host "DEBUG (Enter-TmuxLatestSession): Using output from TEST 1 (Enter - Call Operator) despite potential issues (Exit Code: ${chosenExitCode})."
    } else { # Fallback to Test 2 output
        $tmuxOutputLines = $sessionLinesTest2Enter
        $chosenExitCode = $lastExitCodeTest2Enter
        Write-Host "DEBUG (Enter-TmuxLatestSession): Using output from TEST 2 (Enter - @(...)) despite potential issues (Exit Code: ${chosenExitCode})."
    }
    
    $sessions = @() 

    if ($chosenExitCode -ne 0) {
        if (($tmuxOutputLines -join " ") -match "no server running|failed to connect to server") {
            Write-Host "DEBUG (Enter-TmuxLatestSession): No tmux server running. Will proceed to start a new session."
            # $sessions will remain empty, leading to new session creation.
        } else {
            # Log error but proceed if there's any output to parse
            Write-Warning "DEBUG (Enter-TmuxLatestSession): tmux list-sessions had non-zero exit code ${chosenExitCode}. Output: $($tmuxOutputLines -join "`n")"
            if ($null -eq $tmuxOutputLines -or $tmuxOutputLines.Count -eq 0) {
                 # No output to process, so new session path will be taken.
            }
        }
    }

    if ($tmuxOutputLines -ne $null) {
        $sessions = $tmuxOutputLines | ForEach-Object {
            $line = $_
            if ($line -match '^(\S+)\s+(\d+)\s+(attached|detached)$') {
                [PSCustomObject]@{
                    Name    = $Matches[1]
                    Created = [int]$Matches[2] 
                    Status  = $Matches[3]
                }
            } else {
                 # Avoid logging "no server" messages as errors here if they slipped through
                 if ($line -notmatch "no server running|failed to connect to server") {
                    Write-Host "DEBUG (Enter-TmuxLatestSession): Skipping malformed line during parsing: ${line}"
                 }
            }
        } | Where-Object { $_ -ne $null }
    }
    Write-Host "DEBUG (Enter-TmuxLatestSession): Parsed $($sessions.Count) sessions."

    $latestDetachedSession = $sessions |
        Where-Object { $_.Name -match "^${Type}" -and $_.Status -eq 'detached' } | 
        Sort-Object Created -Descending |
        Select-Object -First 1

    if ($latestDetachedSession) {
        Write-Host "DEBUG (Enter-TmuxLatestSession): Found detached session: $($latestDetachedSession.Name). Attaching."
        if ($pscmdlet.ShouldProcess($latestDetachedSession.Name, "Attach to tmux session")) {
            & tmux attach-session -t $latestDetachedSession.Name # Using call operator
            if ($LASTEXITCODE -ne 0) { Write-Warning "DEBUG: tmux attach-session for '$($latestDetachedSession.Name)' may have failed. LASTEXITCODE: ${LASTEXITCODE}" }
            else { Write-Host "DEBUG: tmux attach-session for '$($latestDetachedSession.Name)' completed. LASTEXITCODE: ${LASTEXITCODE}"}
        }
    } else {
        Write-Host "DEBUG (Enter-TmuxLatestSession): No suitable detached session for '${Type}'. Starting new."
        $startFunctionName = "Start-Tmux$($Type.Substring(0,1).ToUpper() + $Type.Substring(1))Session"
        if ($pscmdlet.ShouldProcess("new ${Type} session (name: ${Type})", "Start tmux session via ${startFunctionName}")) {
            $functionCmd = Get-Command $startFunctionName -ErrorAction SilentlyContinue
            if ($functionCmd) {
                Write-Host "DEBUG (Enter-TmuxLatestSession): Calling ${startFunctionName} -Session ${Type}"
                & $functionCmd -Session $Type # Using call operator
            } else {
                Write-Error "DEBUG (Enter-TmuxLatestSession): Helper function ${startFunctionName} not found."
            }
        }
    }
}

<#
.SYNOPSIS
    Attach to the latest detached 'bash*' session, or start a new 'bash' session.
.EXAMPLE
    Enter-TmuxLatestBashSession
#>
function Enter-TmuxLatestBashSession {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    Write-Host "DEBUG: Entering Enter-TmuxLatestBashSession."
    if ($pscmdlet.ShouldProcess("latest detached bash session (or new 'bash' session)", "Enter Tmux Bash Environment")) {
        Enter-TmuxLatestSession -Type 'bash'
    }
}

<#
.SYNOPSIS
    Attach to the latest detached 'pwsh*' session, or start a new 'pwsh' session.
.EXAMPLE
    Enter-TmuxLatestPwshSession
#>
function Enter-TmuxLatestPwshSession {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    Write-Host "DEBUG: Entering Enter-TmuxLatestPwshSession."
    if ($pscmdlet.ShouldProcess("latest detached pwsh session (or new 'pwsh' session)", "Enter Tmux PowerShell Environment")) {
        Enter-TmuxLatestSession -Type 'pwsh'
    }
}

# === Short, tmux-prefixed aliases ===
$aliasOptions = @{ Force = $true; Scope = 'Local'; ErrorAction = 'SilentlyContinue' }

Write-Host "DEBUG: Setting up aliases..."
Set-Alias -Name tmuxbs -Value Start-TmuxBashSession @aliasOptions
Set-Alias -Name tmuxps -Value Start-TmuxPwshSession @aliasOptions
Set-Alias -Name tmuxlb -Value Get-TmuxBashSessions @aliasOptions
Set-Alias -Name tmuxlp -Value Get-TmuxPwshSessions @aliasOptions
Set-Alias -Name tmuxeb -Value Enter-TmuxLatestBashSession @aliasOptions
Set-Alias -Name tmuxep -Value Enter-TmuxLatestPwshSession @aliasOptions
Write-Host "DEBUG: Aliases setup complete."

# === Auto-export all new functions and aliases ===
if (Get-Command -Name Export-AutoExportFunctions -ErrorAction SilentlyContinue) {
    Write-Host "DEBUG: Attempting to auto-export functions."
    Export-AutoExportFunctions -Exclude @()
} else {
    Write-Warning "DEBUG: Export-AutoExportFunctions not found. Functions may not be exported."
}

if (Get-Command -Name Export-AutoExportAliases -ErrorAction SilentlyContinue) {
    Write-Host "DEBUG: Attempting to auto-export aliases."
    Export-AutoExportAliases -Exclude $preExistingAliases
} else {
    Write-Warning "DEBUG: Export-AutoExportAliases not found. Aliases may not be exported."
}

Write-Host "DEBUG: TmuxModule.psm1 processing complete."
