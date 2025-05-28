<#
.SYNOPSIS
PowerShell module to display environment variables and PATH entries by scope.
.DESCRIPTION
Provides functions to retrieve and display environment variables and PATH entries for Machine, User, and Process scopes. Includes options to format PATH entries line-by-line with trailing semicolons or as a single string.
.NOTES
Module Name: EnvironmentModule.psm1
#>

# ---------------------
# Internal helper: retrieve name/value pairs for a given scope
# ---------------------
function Get-EnvironmentScopeData {
    [CmdletBinding()]
    param (
        [ValidateSet('Machine','User','Process')]
        [string]$Scope
    )
    if ($Scope -eq 'Process') {
        return Get-ChildItem Env: |
            ForEach-Object { [PSCustomObject]@{ Name = $_.Name; Value = $_.Value } }
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
        ForEach-Object { [PSCustomObject]@{ Name = $_.Name; Value = $_.Value } }
}

# ---------------------
<#
.SYNOPSIS
Display environment variables by scope.
.DESCRIPTION
Retrieves and prints environment variables for the specified scopes (Machine, User, Process).
When no scope is provided, all scopes are printed.
.PARAMETER Machine
Include machine (system-wide) environment variables.
.PARAMETER User
Include user-specific environment variables.
.PARAMETER Process
Include process (current session) environment variables.
.EXAMPLE
Get-EnvironmentVariables
Prints all scopes.
.EXAMPLE
Get-EnvironmentVariables -User -Process
Prints user then process variables, separated by a blank line.
#>
function Get-EnvironmentVariables {
    [CmdletBinding()]
    param (
        [switch]$Machine,
        [switch]$User,
        [switch]$Process
    )
    if (-not ($Machine -or $User -or $Process)) { $Machine = $User = $Process = $true }
    $sections = @()
    if ($Machine) { $sections += @{ Name = 'Machine';  Color = 'Cyan' } }
    if ($User)    { $sections += @{ Name = 'User';     Color = 'Green' } }
    if ($Process) { $sections += @{ Name = 'Process';  Color = 'Yellow'} }
    $first = $true
    foreach ($sec in $sections) {
        if (-not $first) { Write-Host }
        Write-Host -ForegroundColor $sec.Color "=== $($sec.Name) Environment Variables ==="
        Get-EnvironmentScopeData -Scope $sec.Name |
            ForEach-Object { Write-Host -Object ("{0}={1}" -f $_.Name, $_.Value) }
        $first = $false
    }
}

# ---------------------
<#
.SYNOPSIS
Display PATH entries by scope.
.DESCRIPTION
Prints the PATH environment variable entries for the specified scopes.
By default, each entry prints on its own line with a trailing semicolon.
Use -NoPathFormat to output the PATH as a single string.
.PARAMETER Machine
Include machine (system-wide) PATH entries.
.PARAMETER User
Include user-specific PATH entries.
.PARAMETER Process
Include process (current session) PATH entries.
.PARAMETER NoPathFormat
If specified, prints each scope's PATH as a single string instead of line-by-line.
.EXAMPLE
Get-EnvironmentPaths -User
Prints each user PATH entry on its own line with trailing semicolons.
.EXAMPLE
Get-EnvironmentPaths -User -NoPathFormat
Prints the user PATH as a single string.
#>
function Get-EnvironmentPaths {
    [CmdletBinding()]
    param (
        [switch]$Machine,
        [switch]$User,
        [switch]$Process,
        [switch]$NoPathFormat
    )
    if (-not ($Machine -or $User -or $Process)) { $Machine = $User = $Process = $true }
    $scopes = @()
    if ($Machine) { $scopes += 'Machine' }
    if ($User)    { $scopes += 'User' }
    if ($Process) { $scopes += 'Process' }
    $first = $true
    foreach ($scope in $scopes) {
        if (-not $first) { Write-Host }
        Write-Host "=== $scope PATH ==="
        $entry = Get-EnvironmentScopeData -Scope $scope | Where-Object Name -ieq 'Path'
        if ($entry) {
            if ($NoPathFormat) {
                Write-Host -Object $entry.Value
            } else {
                $entry.Value.Split(';') |
                    ForEach-Object { Write-Host ($_ + ';') }
            }
        } else {
            Write-Host '(none)'
        }
        $first = $false
    }
}

# ---------------------
<#
.SYNOPSIS
Display all environment variables and PATH entries.
.DESCRIPTION
Runs Get-EnvironmentVariables then Get-EnvironmentPaths for the same scopes,
separated by a blank line. Supports -NoPathFormat for PATH formatting.
.PARAMETER Machine
Include machine scope.
.PARAMETER User
Include user scope.
.PARAMETER Process
Include process scope.
.PARAMETER NoPathFormat
Passes through to Get-EnvironmentPaths to change PATH formatting.
.EXAMPLE
Get-EnvironmentAll -Machine
Prints machine vars then machine PATH entries.
#>
function Get-EnvironmentAll {
    [CmdletBinding()]
    param (
        [switch]$Machine,
        [switch]$User,
        [switch]$Process,
        [switch]$NoPathFormat
    )
    if (-not ($Machine -or $User -or $Process)) { $Machine = $User = $Process = $true }
    # Variables
    Get-EnvironmentVariables @PSBoundParameters
    Write-Host
    # PATHs
    Get-EnvironmentPaths @PSBoundParameters
}

# ---------------------
# Alias definitions (interactive convenience)
# ---------------------
# gev  – alias for Get-EnvironmentVariables:  
#        Prints environment variables (Machine, User, Process) by scope
Set-Alias gev  Get-EnvironmentVariables

# gep  – alias for Get-EnvironmentPaths:  
#        Prints the PATH entries (Machine, User, Process) by scope
Set-Alias gep  Get-EnvironmentPaths

# genv – alias for Get-EnvironmentAll:  
#        Prints both environment variables and PATH entries in one call
Set-Alias genv Get-EnvironmentAll

# ---------------------
# Export public functions and aliases
# ---------------------
Export-ModuleMember -Function Get-EnvironmentVariables,Get-EnvironmentPaths,Get-EnvironmentAll -Alias gev,gep,genv

