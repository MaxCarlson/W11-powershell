# File: Config/Modules/ListAliases.psm1

# Import Auto-Export helper
. "$PSScriptRoot\AutoExportModule.psm1"

# Import Guard
if (-not $script:ModuleImportedListAliases) {
    $script:ModuleImportedListAliases = $true
} else {
    Write-Debug -Message 'Attempting to import ListAliases twice!' -Channel 'Error' -Condition $DebugProfile -FileAndLine
    return
}

# Module debug wiring (matches your conventions)
$script:MODULE_NAME        = 'ListAliases'
$script:DEBUG_LISTALIASES  = $false
$script:WRITE_TO_DEBUG     = ($DebugProfile -or $DEBUG_LISTALIASES)

# Bring in the generic glob expansion/invocation helper
Import-Module -Name "$PSScriptRoot\NativeGlob.psm1" -ErrorAction Stop

# Capture existing aliases before we define our own
$preExistingAliases = Get-Alias | Select-Object -ExpandProperty Name

# --- Thin eza wrapper using the generic invoker --------------------------------
function Invoke-Eza {
<#
.SYNOPSIS
Calls eza with your preset options and PowerShell-style glob expansion.

.DESCRIPTION
Delegates to Invoke-NativeWithExpansion from NativeGlob.psm1, ensuring:
- Globs like *.py expand on Windows/PowerShell.
- Extra eza flags passed by the user are preserved.
- '--' is inserted before paths to avoid option/filename ambiguity.
#>
    [CmdletBinding()]
    param(
        [string[]]$Options,
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Rest
    )
    Invoke-NativeWithExpansion -Command 'eza' -Options $Options -Rest $Rest -UseDoubleDash
}
# ------------------------------------------------------------------------------

# === Simplified Eza “ls” functions (now glob-aware, full set preserved) ===
function l   { Invoke-Eza -Options @('--no-permissions','--git','--icons','--no-user') -Rest $args }
function ls  { Invoke-Eza -Options @('-lah','--no-permissions','--git','--icons','--modified','--group-directories-first','--smart-group','--no-user') -Rest $args }
function la  { Invoke-Eza -Options @('-a','--no-permissions','--git','--icons','--classify','--grid','--group-directories-first') -Rest $args }
function ll  { Invoke-Eza -Options @('-lah','--no-permissions','--git','--icons','--created','--group-directories-first','--smart-group','--no-user') -Rest $args }
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

# === Utilities (kept from your original) ===
function fddots {
    param([int]$depth = 1)
    fd --hidden --max-depth $depth '^\.' .
}

function fcount {
    param([string]$Path = '.')
    (Get-ChildItem -Path $Path -File).Count
}

function deldirs {
    Get-ChildItem -Directory | Remove-Item -Recurse -Force
}

# === Auto-export all new functions and aliases ===
Export-AutoExportFunctions -Exclude @()          # export all functions we just defined
Export-AutoExportAliases   -Exclude $preExistingAliases
