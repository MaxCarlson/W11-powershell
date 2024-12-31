# Simplified Eza Functions in PowerShell
# Ensure 'eza' is installed and available in your PATH
#Write-Host "Inside ls-aliases"

function l { eza --no-permissions --git --icons --no-user }
function ls { eza -lah --no-permissions --git --icons --modified --group-directories-first --smart-group --no-user }
function la { eza -a --no-permissions --git --icons --classify --grid --group-directories-first }
function ll { eza -lah --no-permissions --git --icons --created --group-directories-first --smart-group }
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


# Export functions 
Export-ModuleMember -Function `
    l, ls, la, ll, lo, lg, lll, laha, `
    lss, lst, lse, lx, `
    l1, l2, l3, l4, l5, `
    lt1, lt2, lt3, lt4, lt5
