# Git Functions & Aliases

# Capture existing aliases before we define our own
$preExistingAliases = Get-Alias | Select-Object -ExpandProperty Name


# Define the function to checkout the develop branch
function gchD {
    git checkout develop
}

# Define the function to checkout the main/master branch
function gchm {
    if (git show-ref --verify --quiet refs/heads/main) {
        git checkout main
    }
    elseif (git show-ref --verify --quiet refs/heads/master) {
        git checkout master
    }
    else {
        Write-Host "Neither 'main' nor 'master' branch exists."
    }
}

# Simple aliases that don't need to take parameters
Set-Alias -Name g -Value "git"
Set-Alias -Name ga  -Value "git add"

## Define the function to describe the latest tag
function gdct {
    git describe --tags $(git rev-list --tags --max-count=1)
}


function gaa  { git add --all }
function gp { git push }
function gam  { git am }
function gama  { git am --abort }
function gamc  { git am --continue }
function gams  { git am --skip }
function gamscp  { git am --show-current-patch }
function gap  { git apply }
function gapa  { git add --patch }
function gapt  { git apply --3way }
function gau  { git add --update }
function gav  { git add --verbose }
function gb  { git branch }
function gbD  { git branch --delete --force }
function gba  { git branch --all }
function gbd  { git branch --delete }
function gbg  { git branch -vv | Select-String ': gone\]' }
function gbgD  { git branch -vv | Select-String ': gone\]' | ForEach-Object { git branch -D $_.Matches[0] } }
function gbgd  { git branch -vv | Select-String ': gone\]' | ForEach-Object { git branch -d $_.Matches[0] } }
function gbl  { git blame -w }
function gchB  { git checkout -B }
function gchb  { git checkout -b }
function gchD  { ch }
function gcfg  { git config --list }
function gclR  { git clone --recurse-submodules }
function gcln  { git clean --interactive -d }
function gchm  { ch }
function gtco  { git checkout }
function gchkR  { git checkout --recurse-submodules }
function gtlog  { git shortlog --summary --numbered }
function gchp  { git cherry-pick }
function gchpa  { git cherry-pick --abort }
function gchpc  { git cherry-pick --continue }
function gd  { git diff }
function gdca  { git diff --cached }
function gdct  { dc }
function gdcw  { git diff --cached --word-diff }
function gds  { git diff --staged }
function gdt  { git diff-tree --no-commit-id --name-only -r }
#function gdup  { git diff @{upstream} }
function gdw  { git diff --word-diff }
function gf  { git fetch }
function gfa  { git fetch --all --prune --jobs=10 }
function gfg  { git ls-files | Select-String }
function gfo  { git fetch origin }
function gg  { git gui citool }
function gga  { git gui citool --amend }
function gpl { git pull }
function glg  { git log --stat }
function glgg  { git log --graph }
function glgga  { git log --graph --decorate --all }
function glgm  { git log --graph --max-count=10 }
function glgp  { git log --stat --patch }
function glo  { git log --oneline --decorate }
function glod  { git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset' }

# Functions for commands that need to take parameters
function gcam {
    param (
        [string]$Message
    )
    git commit --all --message "$Message"
}
function gst { git status }

function gcmt { git commit --verbose @args }
function gcmt! { git commit --verbose --amend @args }
function gcmtA { git commit --verbose --all @args }
function gcmtA! { git commit --verbose --all --amend @args }
function gcmtna! { git commit --verbose --all --no-edit --amend @args }
function gcmtcn! { git commit --verbose --all --date=now --no-edit @args }
function gcmtcs! { git commit --verbose --all --signoff --no-edit --amend @args }
function gcmsoA { git commit --all --signoff @args }
function gcmsoM { git commit --all --signoff --message @args }
function gcmtmsg { git commit --message @args }
function gcmsg { git commit --gpg-sign @args }
function gcmsoMsg { git commit --signoff --message @args }
function gcmtcsigS { git commit --gpg-sign --signoff @args }
function gcmtcssM { git commit --gpg-sign --signoff --message @args }

# List of functions to exclude from being exported
#$excludeFunctions = @("PrivateFunction1", "PrivateFunction2")

# Exports for Functions and Aliases handled automatically below
# All functions & aliases defined within this file will be exported
# If something needs to not be exported, we'll have to slightly modify the format
$newFunctions = @(Get-Command -CommandType Function | Where-Object { $_.ScriptBlock.File -eq $PSCommandPath })
Export-ModuleMember -Function $newFunctions.Name


# Get aliases that were defined in this module
$newAliases = Get-Alias | Where-Object { $preExistingAliases -notcontains $_.Name }

# Export all alises defined within this file 
Export-ModuleMember -Alias $newAliases.Name

