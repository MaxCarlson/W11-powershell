<#
.SYNOPSIS
Display and manage environment variables by scope.
.DESCRIPTION
Provides one public getter for listing environment variables by scope,
one public setter for changing a single environment variable, and one public
remover for deleting a single environment variable.

User and Machine scopes are persistent. Process scope applies only to the
current PowerShell process.
.NOTES
Module Name: EnvironmentVariables.psm1
#>

function Get-EnvironmentScopeData {
    [CmdletBinding()]
    param (
        [ValidateSet('Machine','User','Process')]
        [string]$Scope
    )

    if ($Scope -eq 'Process') {
        return Get-ChildItem Env: |
            ForEach-Object { [PSCustomObject]@{ Name = $_.Name; Value = $_.Value; Scope = $Scope } }
    }

    $regPath = if ($Scope -eq 'Machine') {
        'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
    } else {
        'HKCU:\Environment'
    }
    if (-not (Test-Path $regPath)) { return @() }

    $reg = Get-ItemProperty $regPath -ErrorAction SilentlyContinue
    return $reg.PSObject.Properties |
        Where-Object { $_.Name -notlike 'PS*' } |
        ForEach-Object { [PSCustomObject]@{ Name = $_.Name; Value = $_.Value; Scope = $Scope } }
}

<#
.SYNOPSIS
Display environment variables by scope.
.DESCRIPTION
Retrieves environment variables for Machine, User, and/or Process scope.
When no scope switch is provided, all three scopes are displayed.

Use this command to inspect persistent User or Machine variables before
changing them with Set-EnvironmentVariable. User and Machine values are read
from their persistent Windows environment locations; Process values are read
from the current PowerShell process.
.PARAMETER Machine
Include machine-wide persistent environment variables.
.PARAMETER User
Include current-user persistent environment variables.
.PARAMETER Process
Include current-process environment variables.
.PARAMETER Name
Optional variable name filter. Matching is case-insensitive and exact.
.PARAMETER PassThru
Return objects instead of writing formatted lines to the host.
.EXAMPLE
Get-EnvironmentVariables

Displays Machine, User, and Process environment variables.
.EXAMPLE
Get-EnvironmentVariables -User -Name CLAUDE_CODE_USE_POWERSHELL_TOOL -PassThru

Returns the persisted user value for CLAUDE_CODE_USE_POWERSHELL_TOOL as an
object.
.EXAMPLE
Get-EnvironmentVariables -Process -Name PATH

Displays the current process PATH value only.
.OUTPUTS
None by default. With -PassThru, returns PSCustomObject values with Name,
Value, and Scope properties.
#>
function Get-EnvironmentVariables {
    [CmdletBinding()]
    param (
        [switch]$Machine,
        [switch]$User,
        [switch]$Process,
        [string]$Name,
        [switch]$PassThru
    )

    if (-not ($Machine -or $User -or $Process)) { $Machine = $User = $Process = $true }

    $scopes = @()
    if ($Machine) { $scopes += 'Machine' }
    if ($User)    { $scopes += 'User' }
    if ($Process) { $scopes += 'Process' }

    $rows = foreach ($scope in $scopes) {
        $data = Get-EnvironmentScopeData -Scope $scope
        if ($Name) {
            $data | Where-Object { $_.Name -ieq $Name }
        } else {
            $data
        }
    }

    if ($PassThru) {
        return $rows
    }

    $first = $true
    foreach ($scope in $scopes) {
        if (-not $first) { Write-Host }
        Write-Host -ForegroundColor Cyan "=== $scope Environment Variables ==="
        $scopeRows = $rows | Where-Object { $_.Scope -eq $scope }
        if ($scopeRows) {
            $scopeRows | Sort-Object Name | ForEach-Object {
                Write-Host -Object ("{0}={1}" -f $_.Name, $_.Value)
            }
        } else {
            Write-Host '(none)'
        }
        $first = $false
    }
}

<#
.SYNOPSIS
Set one environment variable in a specific scope.
.DESCRIPTION
Sets one named environment variable in Process, User, or Machine scope.

User scope is persistent for the current Windows account and is the recommended
scope for most CLI feature flags. Machine scope is system-wide and typically
requires an elevated PowerShell session. Process scope is temporary.

For User and Machine scope, the current process is also updated by default so
the value is immediately available as $env:NAME in the current shell. Use
-NoProcessUpdate to skip that.

For safety, this command refuses to set Path unless -AllowPathOverwrite is
provided. Use Set-PathEntry from PathManager for normal PATH additions.
.PARAMETER Name
The environment variable name to set. Do not include $env:, Env:, or an equals
sign.
.PARAMETER Value
The value to store. Empty strings are allowed.
.PARAMETER Scope
The target scope. User is the default and is persistent.
.PARAMETER NoClobber
Fail if the variable already exists in the target scope.
.PARAMETER NoProcessUpdate
For User or Machine scope, skip updating the current process.
.PARAMETER AllowPathOverwrite
Allow direct Path assignment. This can overwrite the whole PATH for the target
scope and should only be used intentionally.
.PARAMETER PassThru
Return the updated variable object.
.EXAMPLE
Set-EnvironmentVariable -Name CLAUDE_CODE_USE_POWERSHELL_TOOL -Value 1 -Scope User

Persistently enables the Claude Code PowerShell tool for the current user.
.EXAMPLE
Set-EnvironmentVariable -Name MY_FLAG -Value enabled -Scope User -NoClobber

Creates MY_FLAG for the current user, but fails if it already exists.
.EXAMPLE
Set-EnvironmentVariable -Name SESSION_ONLY -Value yes -Scope Process

Sets SESSION_ONLY only for this PowerShell process.
.EXAMPLE
Set-EnvironmentVariable -Name Path -Value 'C:\Tools' -Scope User

Fails by design. Use Set-PathEntry for PATH additions, or pass
-AllowPathOverwrite if you intentionally want a full PATH overwrite.
.OUTPUTS
None by default. With -PassThru, returns a PSCustomObject with Name, Scope,
and Value properties.
.NOTES
After setting a User or Machine variable, restart shells or applications that
need to inherit the new persisted value.
#>
function Set-EnvironmentVariable {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value,

        [ValidateSet('User','Machine','Process')]
        [string]$Scope = 'User',

        [switch]$NoClobber,
        [switch]$NoProcessUpdate,
        [switch]$AllowPathOverwrite,
        [switch]$PassThru
    )

    if ($Name -match '=') {
        throw "Environment variable names cannot contain '='."
    }
    if ($Name -ieq 'Path' -and -not $AllowPathOverwrite) {
        throw "Refusing to set Path directly. Use Set-PathEntry for PATH additions, or pass -AllowPathOverwrite if you really intend a full PATH overwrite."
    }

    $currentValue = [Environment]::GetEnvironmentVariable($Name, $Scope)
    if ($NoClobber -and $null -ne $currentValue) {
        throw "Environment variable '$Name' already exists in $Scope scope. Remove -NoClobber to overwrite it."
    }

    if ($PSCmdlet.ShouldProcess("$Scope environment variable '$Name'", "Set value")) {
        [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
        if ($Scope -eq 'Process' -or -not $NoProcessUpdate) {
            Set-Item -LiteralPath "Env:$Name" -Value $Value
        }
        if ($PassThru) {
            [pscustomobject]@{
                Name  = $Name
                Scope = $Scope
                Value = [Environment]::GetEnvironmentVariable($Name, $Scope)
            }
        }
    }
}

<#
.SYNOPSIS
Remove one environment variable from a specific scope.
.DESCRIPTION
Removes a single environment variable from Process, User, or Machine scope by
setting the scoped value to $null.

For User and Machine scope, the current process variable is also removed by
default. Use -NoProcessUpdate to leave the current process untouched.

For safety, this command refuses to remove Path unless -AllowPathOverwrite is
provided.
.PARAMETER Name
The environment variable name to remove. Do not include $env:, Env:, or an
equals sign.
.PARAMETER Scope
The target scope. User is the default.
.PARAMETER NoProcessUpdate
For User or Machine scope, skip removing the variable from the current process.
.PARAMETER AllowPathOverwrite
Allow direct Path removal. This is intentionally opt-in.
.PARAMETER PassThru
Return an object with the removed variable name and previous value.
.EXAMPLE
Remove-EnvironmentVariable -Name CLAUDE_CODE_USE_POWERSHELL_TOOL -Scope User

Removes the persisted Claude Code PowerShell tool setting for the current user.
.EXAMPLE
Remove-EnvironmentVariable -Name SESSION_ONLY -Scope Process -PassThru

Removes a process-only variable and returns the previous value.
.OUTPUTS
None by default. With -PassThru, returns a PSCustomObject with Name, Scope,
OldValue, and Removed properties.
#>
function Remove-EnvironmentVariable {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [ValidateSet('User','Machine','Process')]
        [string]$Scope = 'User',

        [switch]$NoProcessUpdate,
        [switch]$AllowPathOverwrite,
        [switch]$PassThru
    )

    if ($Name -match '=') {
        throw "Environment variable names cannot contain '='."
    }
    if ($Name -ieq 'Path' -and -not $AllowPathOverwrite) {
        throw "Refusing to remove Path directly. Use PathManager functions for PATH changes, or pass -AllowPathOverwrite if you really intend to remove PATH."
    }

    $oldValue = [Environment]::GetEnvironmentVariable($Name, $Scope)
    if ($PSCmdlet.ShouldProcess("$Scope environment variable '$Name'", "Remove value")) {
        [Environment]::SetEnvironmentVariable($Name, $null, $Scope)
        if ($Scope -eq 'Process' -or -not $NoProcessUpdate) {
            Remove-Item -LiteralPath "Env:$Name" -ErrorAction SilentlyContinue
        }
        if ($PassThru) {
            [pscustomobject]@{
                Name     = $Name
                Scope    = $Scope
                OldValue = $oldValue
                Removed  = $true
            }
        }
    }
}

Export-ModuleMember -Function Get-EnvironmentVariables,Set-EnvironmentVariable,Remove-EnvironmentVariable
