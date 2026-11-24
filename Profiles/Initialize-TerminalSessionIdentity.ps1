# Create an identity for this PowerShell process. The global marker is local to
# this process and therefore survives dot-sourcing the profile again without
# being inherited by a child PowerShell process.
$identityStateVariable = Get-Variable -Name '__TerminalSessionIdentityState' -Scope Global -ErrorAction SilentlyContinue
$identityState = if ($identityStateVariable) { $identityStateVariable.Value } else { $null }
$parsedEnvironmentId = [guid]::Empty
$hasValidEnvironmentId = [guid]::TryParse([string]$env:TERMINAL_SESSION_ID, [ref]$parsedEnvironmentId)

$stateMatchesCurrentProcess = $identityState -and
    [int]$identityState.ProcessId -eq $PID -and
    $hasValidEnvironmentId -and
    [string]::Equals(
        [string]$identityState.TerminalId,
        $parsedEnvironmentId.ToString('D'),
        [System.StringComparison]::OrdinalIgnoreCase
    )

if ($stateMatchesCurrentProcess) {
    $terminalId = $parsedEnvironmentId.ToString('D')
    $ownerPid = [int]$identityState.ProcessId
}
else {
    $terminalId = [guid]::NewGuid().ToString('D')
    $ownerPid = [int]$PID
    $global:__TerminalSessionIdentityState = [pscustomobject]@{
        ProcessId = $ownerPid
        TerminalId = $terminalId
    }
}

$env:TERMINAL_SESSION_ID = $terminalId
$env:TERMINAL_SESSION_OWNER_PID = [string]$ownerPid
