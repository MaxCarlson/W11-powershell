<#
.SYNOPSIS
    Benchmarks explicitly classified PowerShell profile commands.

.DESCRIPTION
    Reads Config/ProfileCommandBenchmarks.psd1 and executes only the selected
    safe, read-only, or navigation entries in disposable child PowerShell
    processes. Each result contains profile load, cold command, warm command,
    and (where requested) prompt-render timings. Navigation cannot change the
    caller's location because it occurs only in a child process.

    Commands labelled Interactive, Mutating, or Unknown are excluded unless
    explicitly selected with -Safety. The manifest is trusted local data: only
    add invocations that you have reviewed.

.PARAMETER ManifestPath
    Path to the declarative PowerShell data manifest.

.PARAMETER CommandName
    Limits execution to one or more manifest command names.

.PARAMETER Safety
    Limits execution to one or more safety labels. By default, Safe,
    ReadOnly, and Navigation commands are included.

.PARAMETER List
    Displays manifest definitions without running any command.

.PARAMETER IncludePrompt
    Measures prompt rendering for every selected command. Navigation entries
    request prompt timing by default because it affects perceived cd latency.

.PARAMETER CsvPath
    Optional path for CSV results.

.PARAMETER JsonPath
    Optional path for JSON results.

.PARAMETER PassThru
    Returns result objects in addition to displaying the summary table.

.EXAMPLE
    .\Config\Measure-ProfileCommandPerformance.ps1

.EXAMPLE
    .\Config\Measure-ProfileCommandPerformance.ps1 -CommandName cdpon

.EXAMPLE
    .\Config\Measure-ProfileCommandPerformance.ps1 -List
#>
[CmdletBinding()]
param(
    [Alias('m')]
    [string]$ManifestPath = (Join-Path $PSScriptRoot 'ProfileCommandBenchmarks.psd1'),

    [Alias('c')]
    [string[]]$CommandName,

    [Alias('s')]
    [ValidateSet('Safe', 'ReadOnly', 'Navigation', 'Interactive', 'Mutating', 'Unknown')]
    [string[]]$Safety = @('Safe', 'ReadOnly', 'Navigation'),

    [Alias('l')]
    [switch]$List,

    [Alias('p')]
    [switch]$IncludePrompt,

    [Alias('o')]
    [string]$CsvPath,

    [Alias('j')]
    [string]$JsonPath,

    [Alias('pt')]
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "Benchmark manifest was not found: $ManifestPath"
}

$manifest = Import-PowerShellDataFile -LiteralPath $ManifestPath
if ($manifest.SchemaVersion -ne 1 -or -not $manifest.Commands) {
    throw "Unsupported benchmark manifest: $ManifestPath"
}

$definitions = @($manifest.Commands | ForEach-Object { [pscustomobject]$_ })
if ($CommandName) {
    $definitions = @($definitions | Where-Object Name -in $CommandName)
}
else {
    $definitions = @($definitions | Where-Object Safety -in $Safety)
}

if ($List) {
    $definitions |
        Select-Object Name, Module, Safety, Invocation, MeasurePrompt, Notes |
        Format-Table -AutoSize
    return
}

if (-not $definitions) {
    throw 'No benchmark definitions matched the requested command names or safety labels.'
}

$profilePath = Join-Path $PSScriptRoot '..\Profiles\CustomProfile.ps1'
$profilePath = [System.IO.Path]::GetFullPath($profilePath)
if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
    throw "Tracked custom profile was not found: $profilePath"
}

$powerShellExecutable = Join-Path $PSHOME 'pwsh.exe'
if (-not (Test-Path -LiteralPath $powerShellExecutable -PathType Leaf)) {
    $powerShellExecutable = Join-Path $PSHOME 'pwsh'
}

$childScript = @'
param(
    [Parameter(Mandatory)][string]$ProfilePath,
    [Parameter(Mandatory)][string]$DefinitionBase64,
    [Parameter(Mandatory)][bool]$MeasurePrompt
)

Set-StrictMode -Off
$ErrorActionPreference = 'Stop'
$env:MAX_FORCE_INTERACTIVE_PWSH = '1'
$global:ProfileLoaded = $false

$definitionJson = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($DefinitionBase64))
$definition = $definitionJson | ConvertFrom-Json

try {
    $profileLoad = Measure-Command { . $ProfilePath *> $null }
    Set-StrictMode -Version Latest
    $commandName = ($definition.Invocation -split '\s+', 2)[0]
    $command = Get-Command -Name $commandName -ErrorAction Stop

    $cold = Measure-Command { Invoke-Expression $definition.Invocation | Out-Null }
    $coldPrompt = 0.0
    if ($MeasurePrompt -and (Get-Command -Name prompt -CommandType Function -ErrorAction SilentlyContinue)) {
        $coldPrompt = (Measure-Command { & $function:prompt | Out-Null }).TotalMilliseconds
    }

    $warm = Measure-Command { Invoke-Expression $definition.Invocation | Out-Null }
    $warmPrompt = 0.0
    if ($MeasurePrompt -and (Get-Command -Name prompt -CommandType Function -ErrorAction SilentlyContinue)) {
        $warmPrompt = (Measure-Command { & $function:prompt | Out-Null }).TotalMilliseconds
    }

    [pscustomobject]@{
        Name          = $definition.Name
        Module        = $definition.Module
        Safety        = $definition.Safety
        CommandType   = [string]$command.CommandType
        CommandSource = [string]$command.Source
        Status        = 'Passed'
        ProfileLoadMs = [math]::Round($profileLoad.TotalMilliseconds, 2)
        ColdCommandMs = [math]::Round($cold.TotalMilliseconds, 2)
        ColdPromptMs  = [math]::Round($coldPrompt, 2)
        ColdTotalMs   = [math]::Round($cold.TotalMilliseconds + $coldPrompt, 2)
        WarmCommandMs = [math]::Round($warm.TotalMilliseconds, 2)
        WarmPromptMs  = [math]::Round($warmPrompt, 2)
        WarmTotalMs   = [math]::Round($warm.TotalMilliseconds + $warmPrompt, 2)
        Error         = $null
    } | ConvertTo-Json -Compress
}
catch {
    [pscustomobject]@{
        Name          = $definition.Name
        Module        = $definition.Module
        Safety        = $definition.Safety
        CommandType   = $null
        CommandSource = $null
        Status        = 'Failed'
        ProfileLoadMs = $null
        ColdCommandMs = $null
        ColdPromptMs  = $null
        ColdTotalMs   = $null
        WarmCommandMs = $null
        WarmPromptMs  = $null
        WarmTotalMs   = $null
        Error         = $_.Exception.Message
    } | ConvertTo-Json -Compress
}
'@

$results = foreach ($definition in $definitions) {
    $measurePrompt = $IncludePrompt -or [bool]$definition.MeasurePrompt
    $definitionJson = $definition | ConvertTo-Json -Compress
    $definitionBase64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($definitionJson))
    $escapedProfilePath = $profilePath.Replace("'", "''")
    $promptLiteral = if ($measurePrompt) { '$true' } else { '$false' }
    $childCommand = @"
& {
$childScript
} -ProfilePath '$escapedProfilePath' -DefinitionBase64 '$definitionBase64' -MeasurePrompt:$promptLiteral
"@
    $encodedChildCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($childCommand))
    $rawResult = & $powerShellExecutable -NoLogo -NoProfile -EncodedCommand $encodedChildCommand
    $rawResult | Select-Object -Last 1 | ConvertFrom-Json
}

$results = @($results | Sort-Object ColdTotalMs -Descending)
$results |
    Select-Object Name, Safety, Status, ColdCommandMs, ColdPromptMs, ColdTotalMs, WarmCommandMs, WarmPromptMs, WarmTotalMs, Error |
    Format-Table -AutoSize |
    Out-Host

if ($CsvPath) {
    $results | Export-Csv -LiteralPath $CsvPath -NoTypeInformation
}
if ($JsonPath) {
    $results | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $JsonPath -Encoding utf8
}

if ($PassThru) {
    $results
}
