# Replacement candidate for ListAliases.psm1.
#
# Changes from the original:
# - `ll` omits per-file Git status for faster routine directory listings.
# - `llg` retains the original Git-aware `ll` behavior.
# - `Invoke-Eza` caches eza and bypasses glob-expansion work without arguments.

if (-not $script:ModuleImportedListAliases) {
    $script:ModuleImportedListAliases = $true
} else {
    Write-Debug -Message 'Attempting to import ListAliases twice!' -Channel 'Error' -Condition $DebugProfile -FileAndLine
    return
}

$script:MODULE_NAME       = 'ListAliases'
$script:DEBUG_LISTALIASES = $false
$script:WRITE_TO_DEBUG    = ($DebugProfile -or $DEBUG_LISTALIASES)

if (-not (Get-Module -Name NativeGlob)) {
    Import-Module -Name "$PSScriptRoot\NativeGlob.psm1" -ErrorAction Stop
}

$script:EzaCommand = $null

function Invoke-Eza {
<##
.SYNOPSIS
Calls eza with your presets and PowerShell-style glob expansion, while keeping
output concise (no absolute paths for simple globs).
#>
    [CmdletBinding()]
    param(
        [string[]]$Options,
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Rest
    )

    if (-not $script:EzaCommand) {
        $script:EzaCommand = Get-Command eza -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    }

    if (-not $script:EzaCommand -and $env:LOCALAPPDATA) {
        $wingetCandidates = @(
            (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\eza.exe')
        )
        $pkgRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
        if (Test-Path -LiteralPath $pkgRoot -PathType Container) {
            $wingetCandidates += Get-ChildItem -Path $pkgRoot -Filter 'eza.exe' -Recurse -Depth 2 -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FullName
        }
        foreach ($candidate in $wingetCandidates) {
            if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
                $script:EzaCommand = Get-Command -Name $candidate -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($script:EzaCommand) { break }
            }
        }
    }

    if (-not $script:EzaCommand) {
        Write-Error "eza executable not found on PATH or in WinGet packages. Install eza (e.g. 'winget install eza-community.eza') or ensure its directory is on PATH."
        $global:LASTEXITCODE = 1
        return
    }

    if (-not $Rest -or $Rest.Count -eq 0) {
        & $script:EzaCommand @Options '.'
        return
    }

    Invoke-NativeWithExpansion -Command $script:EzaCommand -Options $Options -Rest $Rest -UseDoubleDash -PreferRelative -LeafForLocal
}

function l   { Invoke-Eza -Options @('--no-permissions','--git','--icons','--no-user') -Rest $args }
function ls  { Invoke-Eza -Options @('-lah','--no-permissions','--git','--icons','--modified','--group-directories-first','--smart-group','--no-user') -Rest $args }
function la  { Invoke-Eza -Options @('-a','--no-permissions','--git','--icons','--classify','--grid','--group-directories-first') -Rest $args }
function ll  { Invoke-Eza -Options @('-lah','--no-permissions','--icons','--modified','--group-directories-first','--smart-group','--no-user') -Rest $args }
function llg { Invoke-Eza -Options @('-lah','--no-permissions','--git','--icons','--created','--group-directories-first','--smart-group','--no-user') -Rest $args }
function lo  { Invoke-Eza -Options @('-lah','--no-permissions','--git','--icons','--no-user','--no-time','--no-filesize') -Rest $args }
function lg  { Invoke-Eza -Options @('-lah','--no-permissions','--git','--icons','--created','--modified','--group-directories-first','--smart-group','--git-repos') -Rest $args }
function lll { Invoke-Eza -Options @('-lah','--git','--icons','--created','--modified','--group-directories-first','--smart-group','--total-size') -Rest $args }
function laha{ Invoke-Eza -Options @('-lahSOnMIHZo@','--git','--git-repos','--icons','--smart-group','--changed','--accessed','--created') -Rest $args }
function lss { Invoke-Eza -Options @('--sort=size') -Rest $args }
function lst { Invoke-Eza -Options @('--sort=time')  -Rest $args }
function lse { Invoke-Eza -Options @('--sort=extension') -Rest $args }
function lx  { Invoke-Eza -Options @('--icons','--grid','--classify','--colour=auto','--sort=type','--group-directories-first','--header','--modified','--created','--git','--binary','--group') -Rest $args }
function l1  { Invoke-Eza -Options @('--icons','--classify','--tree','--level=1','--git') -Rest $args }
function l2  { Invoke-Eza -Options @('--icons','--classify','--tree','--level=2','--git') -Rest $args }
function l3  { Invoke-Eza -Options @('--icons','--classify','--tree','--level=3','--git') -Rest $args }
function l4  { Invoke-Eza -Options @('--icons','--classify','--tree','--level=4','--git') -Rest $args }
function l5  { Invoke-Eza -Options @('--icons','--classify','--tree','--level=5','--git') -Rest $args }
function lt1 { Invoke-Eza -Options @('--icons','--classify','--long','--tree','--level=1','--git') -Rest $args }
function lt2 { Invoke-Eza -Options @('--icons','--classify','--long','--tree','--level=2','--git') -Rest $args }
function lt3 { Invoke-Eza -Options @('--icons','--classify','--long','--tree','--level=3','--git') -Rest $args }
function lt4 { Invoke-Eza -Options @('--icons','--classify','--long','--tree','--level=4','--git') -Rest $args }
function lt5 { Invoke-Eza -Options @('--icons','--classify','--long','--tree','--level=5','--git') -Rest $args }

function fddots { param([int]$depth = 1) fd --hidden --max-depth $depth '^\.' . }
function fcount { param([string]$Path = '.') (Get-ChildItem -Path $Path -File).Count }
function deldirs {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param()

    Get-ChildItem -Directory | ForEach-Object {
        if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove directory recursively')) {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
        }
    }
}

$listAliasFunctions = @(
    'Invoke-Eza',
    'l','ls','la','ll','llg','lo','lg','lll','laha','lss','lst','lse','lx',
    'l1','l2','l3','l4','l5','lt1','lt2','lt3','lt4','lt5',
    'fddots','fcount','deldirs'
)
Export-ModuleMember -Function $listAliasFunctions
