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

# Simplified Eza Functions in PowerShell
# Ensure 'eza' is installed and available in your PATH
#Write-Host "Inside ls-aliases"

function l { eza --no-permissions --git --icons --no-user }
function ls { eza -lah --no-permissions --git --icons --modified --group-directories-first --smart-group --no-user }
function la { eza -a --no-permissions --git --icons --classify --grid --group-directories-first }
function ll { eza -lah --no-permissions --git --icons --created --group-directories-first --smart-group @ARGS }
function lo { eza -lah --no-permissions --git --icons --no-user --no-time --no-filesize }
function lg { eza -lah --no-permissions --git --icons --created --modified --group-directories-first --smart-group --git-repos }
function lll { eza -lah --git --icons --created --modified --group-directories-first --smart-group --total-size }
function laha { eza -lahSOnMIHZo@ --git --git-repos --icons --smart-group --changed --accessed --created }
function lss { eza --sort=size }
function lst { eza --sort=time }
function lse { eza --sort=extension }
function lx { eza --icons --grid --classify --colour=auto --sort=type --group-directories-first --header --modified --created --git --binary --group }
function l1 { eza --icons --classify --tree --level=1 --git }
function l2 { eza --icons --classify --tree --level=2 --git }
function l3 { eza --icons --classify --tree --level=3 --git }
function l4 { eza --icons --classify --tree --level=4 --git }
function l5 { eza --icons --classify --tree --level=5 --git }
function lt1 { eza --icons --classify --long --tree --level=1 --git }
function lt2 { eza --icons --classify --long --tree --level=2 --git }
function lt3 { eza --icons --classify --long --tree --level=3 --git }
function lt4 { eza --icons --classify --long --tree --level=4 --git }
function lt5 { eza --icons --classify --long --tree --level=5 --git }

function fcount {
    param([string]$Path = '.')
    (Get-ChildItem -Path $Path -File).Count
}

# Export functions 
#Export-ModuleMember -Function `
#    l, ls, la, ll, lo, lg, lll, laha, `
#    lss, lst, lse, lx, `
#    l1, l2, l3, l4, l5, `
#    lt1, lt2, lt3, lt4, lt5
#


# List of functions to exclude from being exported
#$excludeFunctions = @("PrivateFunction1", "PrivateFunction2")

# Dynamically export all functions except those in the exclude list
#Get-Command -CommandType Function -Scope Script | Where-Object {
#    $excludeFunctions -notcontains $_.Name
#} | ForEach-Object {
#    Export-ModuleMember -Function $_.Name
#}

# Exports for Functions and Aliases handled automatically below
# All functions & aliases defined within this file will be exported
# If something needs to not be exported, we'll have to slightly modify the format
$newFunctions = @(Get-Command -CommandType Function | Where-Object { $_.ScriptBlock.File -eq $PSCommandPath })
Export-ModuleMember -Function $newFunctions.Name

# Get aliases that were defined in this module
$newAliases = Get-Alias | Where-Object { $preExistingAliases -notcontains $_.Name }

# Export all aliases defined within this file
Export-ModuleMember -Alias $newAliases.Name
# Only export aliases if we actually defined any
$aliasNames = $newAliases | Select-Object -ExpandProperty Name
if ($aliasNames) {
    Export-ModuleMember -Alias $aliasNames
}
