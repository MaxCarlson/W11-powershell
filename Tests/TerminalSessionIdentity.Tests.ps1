$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
$helperPath = Join-Path $repoRoot 'Profiles\Initialize-TerminalSessionIdentity.ps1'
$profilePath = Join-Path $repoRoot 'Profiles\CustomProfile.ps1'
$pwshPath = (Get-Process -Id $PID).Path

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Invoke-PwshJson {
    param([Parameter(Mandatory)][string]$Code, [hashtable]$Environment = @{})

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $pwshPath
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.ArgumentList.Add('-NoLogo')
    $startInfo.ArgumentList.Add('-NoProfile')
    $startInfo.ArgumentList.Add('-Command')
    $startInfo.ArgumentList.Add($Code)
    foreach ($key in $Environment.Keys) { $startInfo.Environment[$key] = [string]$Environment[$key] }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { throw 'Could not start disposable pwsh process.' }
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) {
        throw "Disposable pwsh exited $($process.ExitCode): $stderr`n$stdout"
    }
    return ($stdout | ConvertFrom-Json)
}

Describe 'Terminal session identity' {
    It 'initializes fresh shell identities and preserves same-shell reloads' {
Assert-True (Test-Path -LiteralPath $helperPath -PathType Leaf) 'Identity helper is missing.'

$profileText = Get-Content -LiteralPath $profilePath -Raw
$automationReturn = $profileText.IndexOf('if ($script:IsAutomationShell)')
$helperCall = $profileText.IndexOf('Initialize-TerminalSessionIdentity.ps1')
$profileGuard = $profileText.IndexOf('if ($global:ProfileLoaded)')
Assert-True ($automationReturn -ge 0 -and $helperCall -gt $automationReturn -and $helperCall -lt $profileGuard) 'Identity initialization must follow the automation early return and precede the existing profile guard.'
Assert-True ($profileText.Contains('$global:ProfileLoaded = $true')) 'The existing profile-loaded guard assignment is missing.'

$inheritedId = [guid]::NewGuid().ToString('D')
$inheritedOwner = '12345'
$environment = @{
    TERMINAL_SESSION_ID = $inheritedId
    TERMINAL_SESSION_OWNER_PID = $inheritedOwner
    PATH = ''
}
$helperLiteral = $helperPath.Replace("'", "''")
$comspecLiteral = $env:ComSpec.Replace("'", "''")
$identityCode = @"
. '$helperLiteral'
[pscustomobject]@{ Id = `$env:TERMINAL_SESSION_ID; Owner = `$env:TERMINAL_SESSION_OWNER_PID; Pid = `$PID } | ConvertTo-Json -Compress
"@

$first = Invoke-PwshJson -Code $identityCode -Environment $environment
$second = Invoke-PwshJson -Code $identityCode -Environment $environment
Assert-True ([guid]::Parse($first.Id) -is [guid]) 'TERMINAL_SESSION_ID is not a UUID.'
Assert-True ($first.Id -ne $inheritedId) 'The shell reused an inherited parent identity.'
Assert-True ($first.Id -ne $second.Id) 'Independent PowerShell processes received the same identity.'
Assert-True ([int]$first.Owner -eq [int]$first.Pid) 'Owner PID does not identify the initializing PowerShell process.'

$reloadCode = @"
. '$helperLiteral'
`$firstId = `$env:TERMINAL_SESSION_ID
`$firstOwner = `$env:TERMINAL_SESSION_OWNER_PID
. '$helperLiteral'
[pscustomobject]@{ FirstId = `$firstId; Id = `$env:TERMINAL_SESSION_ID; FirstOwner = `$firstOwner; Owner = `$env:TERMINAL_SESSION_OWNER_PID; Pid = `$PID } | ConvertTo-Json -Compress
"@
$reloaded = Invoke-PwshJson -Code $reloadCode -Environment $environment
Assert-True ($reloaded.Id -eq $reloaded.FirstId) 'Reloading the helper changed the shell identity.'
Assert-True ($reloaded.Owner -eq $reloaded.FirstOwner) 'Reloading the helper changed the owner PID.'

$nestedCode = @"
. '$helperLiteral'
`$parentId = `$env:TERMINAL_SESSION_ID
`$parentPid = `$PID
`$childCode = ". '$helperLiteral'; [pscustomobject]@{ Id=`$env:TERMINAL_SESSION_ID; Owner=`$env:TERMINAL_SESSION_OWNER_PID; Pid=`$PID } | ConvertTo-Json -Compress"
`$child = & '$pwshPath' -NoLogo -NoProfile -Command `$childCode | ConvertFrom-Json
[pscustomobject]@{ ParentId=`$parentId; ParentPid=`$parentPid; ChildId=`$child.Id; ChildOwner=`$child.Owner; ChildPid=`$child.Pid } | ConvertTo-Json -Compress
"@
$nested = Invoke-PwshJson -Code $nestedCode -Environment $environment
Assert-True ($nested.ChildId -ne $nested.ParentId) 'A nested PowerShell shell inherited the parent identity.'
Assert-True ([int]$nested.ChildOwner -eq [int]$nested.ChildPid) 'Nested owner PID does not identify the child process.'

$nativeCode = @"
. '$helperLiteral'
`$expectedId = `$env:TERMINAL_SESSION_ID
`$expectedOwner = `$env:TERMINAL_SESSION_OWNER_PID
`$native = & '$comspecLiteral' /d /c 'echo %TERMINAL_SESSION_ID% %TERMINAL_SESSION_OWNER_PID%'
[pscustomobject]@{ ExpectedId=`$expectedId; ExpectedOwner=`$expectedOwner; Native=`$native.Trim() } | ConvertTo-Json -Compress
"@
$native = Invoke-PwshJson -Code $nativeCode -Environment $environment
Assert-True ($native.Native -eq "$($native.ExpectedId) $($native.ExpectedOwner)") 'Native child did not inherit the initialized identity and owner PID.'

$tokens = $null
$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($helperPath, [ref]$tokens, [ref]$parseErrors)
Assert-True ($parseErrors.Count -eq 0) "Identity helper has PowerShell parse errors: $($parseErrors -join '; ')"
[void][System.Management.Automation.Language.Parser]::ParseFile($profilePath, [ref]$tokens, [ref]$parseErrors)
Assert-True ($parseErrors.Count -eq 0) "Profile has PowerShell parse errors: $($parseErrors -join '; ')"
$helperText = Get-Content -LiteralPath $helperPath -Raw
Assert-True ($helperText -notmatch 'LLMD|Invoke-WebRequest|Invoke-RestMethod|SetEnvironmentVariable|Out-File|Set-Content|Add-Content') 'The helper must not depend on LLMD, network access, or persistent environment/file writes.'

    }
}
