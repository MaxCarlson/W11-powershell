# ListAliases.psm1

# Import Guard
if (-not $script:ModuleImportedListAliases) {
    $script:ModuleImportedListAliases = $true
} else {
    Write-Debug -Message 'Attempting to import module twice!' `
                -Channel 'Error' -Condition $DebugProfile -FileAndLine
    return
}

# Capture existing aliases before we define our own
$preExistingAliases = Get-Alias | Select-Object -ExpandProperty Name

# === Simplified Eza “ls” functions ===

function l  { eza --no-permissions --git --icons --no-user }
function ls { eza -lah --no-permissions --git --icons --modified --group-directories-first --smart-group --no-user }
function la { eza -a --no-permissions --git --icons --classify --grid --group-directories-first }
function ll { eza -lah --no-permissions --git --icons --created --group-directories-first --smart-group @ARGS }
function lo { eza -lah --no-permissions --git --icons --no-user --no-time --no-filesize }
function lg { eza -lah --no-permissions --git --icons --created --modified --group-directories-first --smart-group --git-repos }
function lll { eza -lah --git --icons --created --modified --group-directories-first --smart-group --total-size }
function laha { eza -lahSOnMIHZo@ --git --git-repos --icons --smart-group --changed --accessed --created }
function lss  { eza --sort=size }
function lst  { eza --sort=time }
function lse  { eza --sort=extension }
function lx   { eza --icons --grid --classify --colour=auto --sort=type --group-directories-first --header --modified --created --git --binary --group }
function l1   { eza --icons --classify --tree --level=1 --git }
function l2   { eza --icons --classify --tree --level=2 --git }
function l3   { eza --icons --classify --tree --level=3 --git }
function l4   { eza --icons --classify --tree --level=4 --git }
function l5   { eza --icons --classify --tree --level=5 --git }
function lt1  { eza --icons --classify --long --tree --level=1 --git }
function lt2  { eza --icons --classify --long --tree --level=2 --git }
function lt3  { eza --icons --classify --long --tree --level=3 --git }
function lt4  { eza --icons --classify --long --tree --level=4 --git }
function lt5  { eza --icons --classify --long --tree --level=5 --git }

function fcount {
    param([string]$Path = '.')
    (Get-ChildItem -Path $Path -File).Count
}

# === Dynamic export of functions and aliases ===

# Export only the functions defined in this very file
$newFunctions = Get-Command -CommandType Function -Scope Script |
    Where-Object { $_.ScriptBlock.File -eq $MyInvocation.MyCommand.Path } |
    Select-Object -ExpandProperty Name
if ($newFunctions) {
    Export-ModuleMember -Function $newFunctions
}

# Export only the aliases *you* define below this point
# (none in this example, but wrapped in an if-statement so no null is ever passed)
$newAliases = Get-Alias |
    Where-Object { $preExistingAliases -notcontains $_.Name } |
    Select-Object -ExpandProperty Name
if ($newAliases) {
    Export-ModuleMember -Alias $newAliases
}
