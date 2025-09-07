# File: Config/Modules/NativeGlob.psm1

# Auto-export helper (guarded import)
if (-not (Get-Module -Name AutoExportModule)) {
    Import-Module "$PSScriptRoot\AutoExportModule.psm1" -ErrorAction Stop
}

# Import Guard
if (-not $script:ModuleImportedNativeGlob) {
    $script:ModuleImportedNativeGlob = $true
} else {
    Write-Debug -Message 'Attempting to import NativeGlob twice!' -Channel 'Error' -Condition $true -FileAndLine
    return
}

# Module debug wiring
$script:MODULE_NAME      = 'NativeGlob'
$script:DEBUG_NATIVEGLOB = $false
$script:WRITE_TO_DEBUG   = ($DebugProfile -or $DEBUG_NATIVEGLOB)

# Capture existing aliases before we define our own (for auto-export helper)
$preExistingAliases = Get-Alias | Select-Object -ExpandProperty Name

function Expand-GlobTokens {
<#
.SYNOPSIS
Expands PowerShell wildcards for native-command args and classifies flags.

.DESCRIPTION
- Splits incoming tokens into flags (start with '-') and candidate paths.
- Expands wildcards (supports ** in PS7+).
- Emits relative paths (by default) instead of absolute, so tools like eza
  don’t show long full paths.
- For *simple* globs like '*.py' (no directory separators), emits just the
  leaf filename to match normal `ll` behavior.

.PARAMETER Tokens
User tokens (flags and/or paths/globs). Usually pass $args.

.PARAMETER PreferRelative
If set (default), convert expanded paths to relative to the current directory.

.PARAMETER LeafForLocal
If set (default), and the original token had no path separators, output only
the leaf name for each match (e.g., 'file.py').

.OUTPUTS
[pscustomobject] with Flags, Paths, Unmatched arrays.
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true, Position=0)]
        [string[]]$Tokens,

        [switch]$PreferRelative = $true,
        [switch]$LeafForLocal   = $true
    )

    $flags     = New-Object System.Collections.Generic.List[string]
    $paths     = New-Object System.Collections.Generic.List[string]
    $unmatched = New-Object System.Collections.Generic.List[string]

    foreach ($item in ($Tokens ?? @())) {
        if ([string]::IsNullOrWhiteSpace($item)) { continue }

        if ($item.StartsWith('-')) { $flags.Add($item); continue }

        $tokenHasSep = $item -match '[\\/]|^\w:|^/'

        $hasWild = [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($item)
        if ($hasWild) {
            if ($item.Contains('**')) {
                $expanded = Get-ChildItem -Path $item -Force -Recurse -ErrorAction SilentlyContinue |
                            Select-Object -ExpandProperty FullName
            } else {
                $expanded = (Resolve-Path -Path $item -ErrorAction SilentlyContinue).Path
            }
        } else {
            if (Test-Path -LiteralPath $item) {
                $expanded = ,(Resolve-Path -LiteralPath $item -ErrorAction SilentlyContinue).Path
            } else {
                $expanded = @()
            }
        }

        if (-not $expanded -or $expanded.Count -eq 0) {
            $unmatched.Add($item)
            continue
        }

        foreach ($p in $expanded) {
            $out = $p
            if ($PreferRelative) {
                try { $out = Resolve-Path -LiteralPath $p -Relative -ErrorAction Stop } catch { $out = $p }
            }
            if ($LeafForLocal -and -not $tokenHasSep) {
                # For simple patterns like '*.py', prefer just the filename
                $out = Split-Path -Path $out -Leaf
            }
            $paths.Add($out)
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
Invokes a native command with proper glob expansion.

.PARAMETER Command
Executable to run (e.g., 'eza', 'rg').

.PARAMETER Options
Preset flags for the tool.

.PARAMETER Rest
User tokens (flags and/or paths/globs). Usually $args.

.PARAMETER UseDoubleDash
Insert '--' before paths to prevent them being parsed as options.

.PARAMETER PreferRelative
Emit relative paths (default: on).

.PARAMETER LeafForLocal
For tokens without path separators, emit only leaf names (default: on).
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command,
        [string[]]$Options,
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Rest,
        [switch]$UseDoubleDash = $true,
        [switch]$PreferRelative = $true,
        [switch]$LeafForLocal   = $true
    )

    $cmdPath = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $cmdPath) {
        Write-Debug -Message ("Command not found on PATH: {0}" -f $Command) -Channel 'Error' -Condition $true -FileAndLine
        return
    }

    $exp = Expand-GlobTokens -Tokens $Rest -PreferRelative:$PreferRelative -LeafForLocal:$LeafForLocal

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
Export-AutoExportFunctions -Exclude @()
Export-AutoExportAliases   -Exclude $preExistingAliases
