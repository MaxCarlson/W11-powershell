<#
.SYNOPSIS
Ensures the repository AGENTS.md is linked into one or more global locations.

.DESCRIPTION
Creates missing directories, prompts before overwriting existing files,
and then creates symbolic links pointing to Profiles\AGENTS.md. By default,
only the %APPDATA%\agents location is linked, but additional locations can
be opted in through the -Locations parameter.
#>
param(
    [ValidateSet('AppData', 'Codex', 'Configs', 'All')]
    [string[]]$Locations = @('AppData'),
    [string]$SourcePath,
    [Alias('h', 'help')]
    [switch]$ShowHelp
)

if ($args -contains '--help') {
    $ShowHelp = $true
}

function Show-AgentLinkHelp {
@"
Ensures the repo's Profiles\AGENTS.md is symlinked into optional global locations.

Usage:
  .\Ensure-AgentLinks.ps1                # Link only to %APPDATA%\agents (default)
  .\Ensure-AgentLinks.ps1 -Locations All # Link to AppData, ~/.codex, ~/.configs
  .\Ensure-AgentLinks.ps1 -Locations Codex,Configs
  .\Ensure-AgentLinks.ps1 -SourcePath C:\custom\AGENTS.md

Switches:
  -Locations <AppData|Codex|Configs|All>   Locations to target (default AppData only)
  -SourcePath <path>                      Use an alternate AGENTS.md source file
  -h, -help, --help                       Show this usage summary

Notes:
  • Symlink creation generally requires an elevated PowerShell session or Windows Developer Mode.
  • Existing AGENTS.md files prompt before being replaced by the link.
  • When -Locations All is provided, all known destinations are processed.
"@
}

if ($ShowHelp) {
    Show-AgentLinkHelp
    return
}

$source = if ($SourcePath) { $SourcePath } else { Join-Path $PSScriptRoot 'AGENTS.md' }
if (-not (Test-Path $source)) {
    throw "Unable to locate AGENTS.md at $source"
}

$locationMap = [ordered]@{
    AppData = @{
        Directory = if ($env:APPDATA) { Join-Path $env:APPDATA 'agents' } else { Join-Path $HOME 'AppData\Roaming\agents' }
        Label     = '%APPDATA%\agents'
    }
    Codex = @{
        Directory = Join-Path $HOME '.codex'
        Label     = '~/.codex'
    }
    Configs = @{
        Directory = Join-Path $HOME '.configs'
        Label     = '~/.configs'
    }
}

function Resolve-Locations {
    param([string[]]$Requested)
    $resolved = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $Requested) {
        if ($item -eq 'All') {
            foreach ($key in $locationMap.Keys) {
                if (-not $resolved.Contains($key)) { [void]$resolved.Add($key) }
            }
        } elseif (-not $resolved.Contains($item)) {
            [void]$resolved.Add($item)
        }
    }
    return $resolved
}

function Confirm-ReplaceTarget {
    param([string]$TargetPath)
    if (-not (Test-Path $TargetPath)) {
        return $true
    }

    $response = Read-Host "AGENTS.md already exists at $TargetPath. Overwrite with symlink? (y/N)"
    if ($response -ne 'y') {
        Write-Host "Skipped $TargetPath" -ForegroundColor DarkYellow
        return $false
    }

    try {
        Remove-Item -Path $TargetPath -Force
        return $true
    } catch {
        Write-Warning ("Failed to remove {0}: {1}" -f $TargetPath, $_)
        return $false
    }
}

function Ensure-AgentLink {
    param(
        [string]$TargetDirectory,
        [string]$TargetLabel
    )

    if (-not (Test-Path $TargetDirectory)) {
        Write-Host "Creating $TargetLabel directory at $TargetDirectory" -ForegroundColor DarkGray
        New-Item -ItemType Directory -Path $TargetDirectory -Force | Out-Null
    }

    $target = Join-Path $TargetDirectory 'AGENTS.md'
    if (-not (Confirm-ReplaceTarget -TargetPath $target)) {
        return
    }

    try {
        New-Item -ItemType SymbolicLink -Path $target -Target $source -Force | Out-Null
        Write-Host "Linked AGENTS.md to $TargetLabel ($target)" -ForegroundColor Green
    } catch {
        Write-Warning ("Failed to link AGENTS.md into {0}: {1}" -f $TargetLabel, $_)
    }
}

$effectiveLocations = Resolve-Locations -Requested $Locations
foreach ($locationKey in $effectiveLocations) {
    if (-not $locationMap.Contains($locationKey)) {
        Write-Warning "Unknown target location: $locationKey"
        continue
    }
    $info = $locationMap[$locationKey]
    Ensure-AgentLink -TargetDirectory $info.Directory -TargetLabel $info.Label
}
