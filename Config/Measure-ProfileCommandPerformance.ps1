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

.PARAMETER Eza
    Explicitly requests the Eza listing benchmark. Eza runs by default, so
    this switch is retained for readable invocations and compatibility.

.PARAMETER EzaOnly
    Runs only the Eza listing benchmark and skips profile command benchmarks.

.PARAMETER SkipEza
    Skips the Eza listing benchmark when running profile command benchmarks.

.PARAMETER EzaPath
    Directory used by the Eza listing benchmark. Defaults to the current
    directory.

.PARAMETER Iterations
    Number of samples for each Eza case. Results report the median.

.PARAMETER SkipProfileCommands
    Excludes Invoke-Eza, ll, and ls wrapper measurements from the Eza mode.

.PARAMETER EzaCsvPath
    Optional CSV path for Eza listing results.

.PARAMETER Help
    Displays full comment-based help. -?, -Help, -h, and --help are accepted.

.EXAMPLE
    .\Config\Measure-ProfileCommandPerformance.ps1

.EXAMPLE
    .\Config\Measure-ProfileCommandPerformance.ps1 -CommandName cdpon

.EXAMPLE
    .\Config\Measure-ProfileCommandPerformance.ps1 -List

.EXAMPLE
    .\Config\Measure-ProfileCommandPerformance.ps1 -EzaOnly -EzaPath D:\Pictures\Saved\tmpvids
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
    [switch]$PassThru,

    [Alias('e')]
    [switch]$Eza,

    [Alias('eo')]
    [switch]$EzaOnly,

    [Alias('se')]
    [switch]$SkipEza,

    [Alias('ep')]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$EzaPath = (Get-Location).Path,

    [Alias('i')]
    [ValidateRange(1, 20)]
    [int]$Iterations = 1,

    [Alias('spc')]
    [switch]$SkipProfileCommands,

    [Alias('ec')]
    [string]$EzaCsvPath,

    [Alias('h', '?', '--help')]
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Help) {
    Get-Help -Name $PSCommandPath -Full
    return
}

function Get-Median {
    param([Parameter(Mandatory)][double[]]$Values)

    $sorted = @($Values | Sort-Object)
    $middle = [int][math]::Floor($sorted.Count / 2)
    if ($sorted.Count % 2) {
        return $sorted[$middle]
    }

    return ($sorted[$middle - 1] + $sorted[$middle]) / 2
}

function Format-Duration {
    param([Parameter(Mandatory)][double]$Milliseconds)

    if ($Milliseconds -ge 1000) {
        return ('{0:N3} s' -f ($Milliseconds / 1000))
    }

    return ('{0:N1} ms' -f $Milliseconds)
}

function Show-EzaCommandDetails {
    param([Parameter(Mandatory)][string]$Name)

    $command = Get-Command -Name $Name -ErrorAction SilentlyContinue
    if (-not $command) {
        Write-Host "${Name}: unavailable"
        return
    }

    Write-Host "${Name}: $($command.CommandType) from $($command.Source)"
}

function Invoke-EzaListingBenchmark {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][int]$SampleCount,
        [Parameter(Mandatory)][bool]$SkipWrappers,
        [string]$CsvPath
    )

    $eza = Get-Command eza -CommandType Application -ErrorAction Stop
    $base = @('-l', '-a', '-h')
    $llFlags = @('--no-permissions', '--icons', '--modified', '--group-directories-first', '--smart-group', '--no-user')
    $lsFlags = @('--no-permissions', '--git', '--icons', '--modified', '--group-directories-first', '--smart-group', '--no-user')
    $testCases = [System.Collections.Generic.List[object]]::new()

    function Add-EzaTest {
        param([string]$Name, [string[]]$Arguments)
        $testCases.Add([pscustomobject]@{ Name = $Name; Arguments = $Arguments })
    }

    Add-EzaTest 'eza -lh baseline' @('-l', '-h')
    Add-EzaTest 'eza -lah baseline' $base
    foreach ($flag in $llFlags + '--git' + '--created') {
        Add-EzaTest "eza -lah + $flag" ($base + $flag)
    }

    $progressive = $base
    foreach ($flag in $llFlags) {
        $progressive = $progressive + $flag
        Add-EzaTest "ll progressive through $flag" $progressive
    }

    Add-EzaTest 'direct ll flags' ($base + $llFlags)
    Add-EzaTest 'direct ls flags' ($base + $lsFlags)
    Add-EzaTest 'direct old ll flags (Git + created)' ($base + '--no-permissions', '--git', '--icons', '--created', '--group-directories-first', '--smart-group', '--no-user')

    Push-Location -LiteralPath $Path
    try {
        Write-Host "`n=== Eza listing benchmark ($($testCases.Count) cases) ==="
        Write-Host "Directory: $((Get-Location).Path)"
        Write-Host 'Available listing commands:'
        Show-EzaCommandDetails -Name Invoke-Eza
        Show-EzaCommandDetails -Name ll
        Show-EzaCommandDetails -Name ls

        $results = [System.Collections.Generic.List[object]]::new()
        $index = 0
        foreach ($case in $testCases) {
            $index++
            Write-Progress -Id 2 -Activity 'Eza listing benchmark' -Status "[$index/$($testCases.Count)] $($case.Name)" -PercentComplete (100 * $index / $testCases.Count)
            $times = [System.Collections.Generic.List[double]]::new()
            for ($run = 1; $run -le $SampleCount; $run++) {
                $global:LASTEXITCODE = 0
                $elapsed = (Measure-Command { & $eza @($case.Arguments) *> $null }).TotalMilliseconds
                if ($LASTEXITCODE -ne 0) {
                    throw "eza failed for '$($case.Name)' with exit code $LASTEXITCODE."
                }
                $times.Add($elapsed)
            }
            $results.Add([pscustomobject]@{
                Test      = $case.Name
                MedianMs  = [math]::Round((Get-Median $times.ToArray()), 1)
                SamplesMs = ($times | ForEach-Object { [math]::Round($_, 1) }) -join ', '
                Arguments = $case.Arguments -join ' '
            })
        }

        if (-not $SkipWrappers) {
            $wrapperCases = @(
                @{ Name = 'Invoke-Eza wrapper'; CommandName = 'Invoke-Eza'; Invocation = { Invoke-Eza -Options @('-lah', '--no-permissions', '--icons', '--modified', '--group-directories-first', '--smart-group', '--no-user') -Rest @() } }
                @{ Name = 'PowerShell ll'; CommandName = 'll'; Invocation = { ll } }
                @{ Name = 'PowerShell ls'; CommandName = 'ls'; Invocation = { ls } }
            )
            foreach ($case in $wrapperCases) {
                if (-not (Get-Command $case.CommandName -ErrorAction SilentlyContinue)) {
                    continue
                }
                $times = [System.Collections.Generic.List[double]]::new()
                for ($run = 1; $run -le $SampleCount; $run++) {
                    $times.Add((Measure-Command { & $case.Invocation *> $null }).TotalMilliseconds)
                }
                $results.Add([pscustomobject]@{
                    Test      = $case.Name
                    MedianMs  = [math]::Round((Get-Median $times.ToArray()), 1)
                    SamplesMs = ($times | ForEach-Object { [math]::Round($_, 1) }) -join ', '
                    Arguments = '<loaded command>'
                })
            }
        }

        $sorted = @($results | Sort-Object MedianMs -Descending)
        Write-Host "`nEza results (slowest first):"
        $sorted |
            Select-Object Test, MedianMs, SamplesMs, Arguments |
            Format-Table -AutoSize |
            Out-Host
        if ($CsvPath) {
            $sorted | Export-Csv -LiteralPath $CsvPath -NoTypeInformation
            Write-Host "Saved Eza results to $CsvPath"
        }

        return $sorted
    }
    finally {
        Pop-Location
        Write-Progress -Id 2 -Activity 'Eza listing benchmark' -Completed
    }
}

if ($EzaOnly) {
    Invoke-EzaListingBenchmark -Path $EzaPath -SampleCount $Iterations -SkipWrappers $SkipProfileCommands -CsvPath $EzaCsvPath | Out-Null
    return
}

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

function Invoke-BenchmarkInvocation {
    param(
        [Parameter(Mandatory)][string]$Invocation,
        [string]$FailurePattern
    )

    $previousErrorActionPreference = $global:ErrorActionPreference
    $previousNativeCommandPreference = $global:PSNativeCommandUseErrorActionPreference
    try {
        $global:ErrorActionPreference = 'Stop'
        $global:PSNativeCommandUseErrorActionPreference = $true
        $global:LASTEXITCODE = 0
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        $invocationScript = [scriptblock]::Create($Invocation)
        $capturedOutput = @(& $invocationScript *>&1)
        $timer.Stop()

        $capturedText = ($capturedOutput | Out-String).Trim()
        if ($FailurePattern -and $capturedText -match $FailurePattern) {
            throw "Command emitted failure output: $capturedText"
        }

        $errorRecords = @($capturedOutput | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })
        if ($errorRecords.Count -gt 0) {
            $messages = $errorRecords | ForEach-Object { $_.Exception.Message } | Select-Object -Unique
            throw ($messages -join ' ')
        }

        if ($LASTEXITCODE -ne 0) {
            $message = "Command exited with code $LASTEXITCODE."
            if ($capturedText) {
                $message += " $capturedText"
            }
            throw $message
        }

        return $timer.Elapsed.TotalMilliseconds
    }
    finally {
        $global:ErrorActionPreference = $previousErrorActionPreference
        $global:PSNativeCommandUseErrorActionPreference = $previousNativeCommandPreference
    }
}

try {
    $profileLoad = Measure-Command { . $ProfilePath *> $null }
    Set-StrictMode -Version Latest
    $commandName = ($definition.Invocation -split '\s+', 2)[0]
    $command = Get-Command -Name $commandName -ErrorAction Stop

    $failurePattern = ''
    if ($definition.PSObject.Properties['FailurePattern']) {
        $failurePattern = [string]$definition.FailurePattern
    }

    $cold = Invoke-BenchmarkInvocation -Invocation $definition.Invocation -FailurePattern $failurePattern
    $coldPrompt = 0.0
    if ($MeasurePrompt -and (Get-Command -Name prompt -CommandType Function -ErrorAction SilentlyContinue)) {
        $coldPrompt = (Measure-Command { & $function:prompt | Out-Null }).TotalMilliseconds
    }

    $warm = Invoke-BenchmarkInvocation -Invocation $definition.Invocation -FailurePattern $failurePattern
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
        ColdCommandMs = [math]::Round($cold, 2)
        ColdPromptMs  = [math]::Round($coldPrompt, 2)
        ColdTotalMs   = [math]::Round($cold + $coldPrompt, 2)
        WarmCommandMs = [math]::Round($warm, 2)
        WarmPromptMs  = [math]::Round($warmPrompt, 2)
        WarmTotalMs   = [math]::Round($warm + $warmPrompt, 2)
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

Write-Host "`n=== Profile command benchmark ($($definitions.Count) commands) ==="
Write-Host 'Each command runs in a fresh profile-loaded child shell to capture cold and warm timings.'
$commandIndex = 0
$results = try {
    foreach ($definition in $definitions) {
        $commandIndex++
        Write-Progress -Id 1 -Activity 'Profile command benchmark' -Status "[$commandIndex/$($definitions.Count)] $($definition.Name)" -PercentComplete (100 * $commandIndex / $definitions.Count)
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
}
finally {
    Write-Progress -Id 1 -Activity 'Profile command benchmark' -Completed
}

$results = @($results | Sort-Object ColdTotalMs -Descending)
$results |
    Select-Object @{ Name = 'Command'; Expression = { $_.Name } }, Safety, Status,
        @{ Name = 'ColdMs'; Expression = { $_.ColdTotalMs } },
        @{ Name = 'WarmMs'; Expression = { $_.WarmTotalMs } } |
    Format-Table -AutoSize |
    Out-Host

$failures = @($results | Where-Object Status -eq 'Failed')
if ($failures.Count -gt 0) {
    Write-Warning "`nBenchmark failures ($($failures.Count)):"
    foreach ($failure in $failures) {
        Write-Warning "  $($failure.Name): $($failure.Error)"
    }
}

if ($CsvPath) {
    $results | Export-Csv -LiteralPath $CsvPath -NoTypeInformation
}
if ($JsonPath) {
    $results | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $JsonPath -Encoding utf8
}

if ($PassThru) {
    $results
}

if (-not $SkipEza) {
    Invoke-EzaListingBenchmark -Path $EzaPath -SampleCount $Iterations -SkipWrappers $SkipProfileCommands -CsvPath $EzaCsvPath | Out-Null
}
