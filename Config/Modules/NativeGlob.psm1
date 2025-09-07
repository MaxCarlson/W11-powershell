# File: Config/Modules/NativeGlob.psm1

# Auto-export helper (adjust path if your helper lives elsewhere)
. "$PSScriptRoot\AutoExportModule.psm1"

# Import Guard
if (-not $script:ModuleImportedNativeGlob) {
    $script:ModuleImportedNativeGlob = $true
} else {
    Write-Debug -Message 'Attempting to import NativeGlob twice!' -Channel 'Error' -Condition $true -FileAndLine
    return
}

# Module debug wiring (matches your conventions)
$script:MODULE_NAME       = 'NativeGlob'
$script:DEBUG_NATIVEGLOB  = $false
$script:WRITE_TO_DEBUG    = ($DebugProfile -or $DEBUG_NATIVEGLOB)

# Capture existing aliases before we define our own (for auto-export helper)
$preExistingAliases = Get-Alias | Select-Object -ExpandProperty Name

function Expand-GlobTokens {
<#
.SYNOPSIS
Expands PowerShell wildcards for native-command arguments and classifies flags.

.DESCRIPTION
PowerShell does not expand globs for native executables. This function:
- Splits incoming tokens into "flags" (start with '-') and potential paths.
- Expands wildcards (including ** in PS7+) into full paths.
- Returns Flags, Paths, and Unmatched (patterns with no matches).

.PARAMETER Tokens
The raw tokens (e.g., from $args) that may contain flags and paths/globs.

.OUTPUTS
[pscustomobject] with properties:
- Flags     : string[]
- Paths     : string[] (fully-qualified)
- Unmatched : string[]

.EXAMPLE
Expand-GlobTokens -Tokens @('*.py','-r','src/**\*.ps1')

.EXAMPLE
$exp = Expand-GlobTokens $args
$exp.Paths
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true, Position=0)]
        [string[]]$Tokens
    )

    $flags     = New-Object System.Collections.Generic.List[string]
    $paths     = New-Object System.Collections.Generic.List[string]
    $unmatched = New-Object System.Collections.Generic.List[string]

    foreach ($item in ($Tokens ?? @())) {
        if ([string]::IsNullOrWhiteSpace($item)) { continue }

        if ($item.StartsWith('-')) {
            $flags.Add($item)
            continue
        }

        $hasWild = [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($item)
        if ($hasWild) {
            if ($item.Contains('**')) {
                $expanded = Get-ChildItem -Path $item -Force -Recurse -ErrorAction SilentlyContinue |
                            Select-Object -ExpandProperty FullName
            } else {
                $expanded = (Resolve-Path -Path $item -ErrorAction SilentlyContinue).Path
            }

            if ($expanded) {
                foreach ($p in $expanded) { $paths.Add($p) }
            } else {
                $unmatched.Add($item)
            }
        } else {
            if (Test-Path -LiteralPath $item) {
                $paths.Add((Resolve-Path -LiteralPath $item).Path)
            } else {
                $unmatched.Add($item)
            }
        }
    }

    if ($unmatched.Count -gt 0) {
        Write-Debug -Message ("No matches for: {0}" -f ($unmatched -join ', ')) -Channel 'Warning' -Condition $script:WRITE_TO_DEBUG -FileAndLine
    }

    [pscustomobject]@{
        Flags     = $flags.ToArray()
        Paths     = $paths.ToArray()
        Unmatched = $unmatched.ToArray()
    }
}

function Invoke-NativeWithExpansion {
<#
.SYNOPSIS
Invokes a native command with PowerShell-style glob expansion.

.DESCRIPTION
Generic wrapper for native tools that need glob expansion. It:
- Validates the command exists on PATH.
- Accepts preset Options and the user's Tokens (flags and paths/globs).
- Expands globs, preserves extra flags, and optionally inserts '--'
  before paths to prevent option/filename ambiguity.

.PARAMETER Command
The native executable to invoke (e.g., 'eza', 'rg', 'fd', etc.).

.PARAMETER Options
Preset flags for the specific tool/alias (e.g., '-lah','--icons').

.PARAMETER Rest
User-supplied tokens (flags and/or paths/globs). Usually pass $args here.

.PARAMETER UseDoubleDash
If set (default), inserts '--' before any paths to prevent mis-parsing.

.EXAMPLE
Invoke-NativeWithExpansion -Command 'eza' -Options @('-lah','--icons') -Rest $args -UseDoubleDash

.EXAMPLE
Invoke-NativeWithExpansion -Command 'rg' -Options @('--line-number') -Rest @('TODO','src/**/*.py')
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command,
        [string[]]$Options,
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Rest,
        [switch]$UseDoubleDash = $true
    )

    $cmdPath = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $cmdPath) {
        Write-Debug -Message ("Command not found on PATH: {0}" -f $Command) -Channel 'Error' -Condition $true -FileAndLine
        return
    }

    $exp = Expand-GlobTokens $Rest

    $argsForCmd = @()
    if ($Options)  { $argsForCmd += $Options }
    if ($exp.Flags){ $argsForCmd += $exp.Flags }

    if ($exp.Paths.Count -gt 0) {
        if ($UseDoubleDash) { $argsForCmd += '--' }
        $argsForCmd += $exp.Paths
    }

    try {
        & $cmdPath @argsForCmd
    } catch {
        Write-Debug -Message ("{0} failed: {1}" -f $Command, $_.Exception.Message) -Channel 'Error' -Condition $true -FileAndLine
    }
}

# === Auto-export all new functions and aliases ===
Export-AutoExportFunctions -Exclude @()          # export all functions we just defined
Export-AutoExportAliases   -Exclude $preExistingAliases
