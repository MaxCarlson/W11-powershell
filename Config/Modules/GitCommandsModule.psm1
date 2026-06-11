# Git Functions & Aliases

# Remove default aliases that block git helpers from being imported
$commandOverrides = @()
foreach ($aliasName in @('ga', 'gl', 'gp')) {
    $existingCommands = @(Get-Command -Name $aliasName -All -ErrorAction SilentlyContinue)
    foreach ($cmd in $existingCommands) {
        $definition = switch ($cmd.CommandType) {
            'Alias' { $cmd.Definition }
            'Function' { $cmd.Definition }
            default { $cmd.Source }
        }
        $commandOverrides += [PSCustomObject]@{
            ModuleName  = 'GitCommandsModule'
            Name        = $cmd.Name
            CommandType = $cmd.CommandType
            Definition  = $definition
        }
    }
    if (Get-Alias -Name $aliasName -ErrorAction SilentlyContinue) {
        Remove-Item -Path "Alias:$aliasName" -Force -ErrorAction SilentlyContinue
    }
}
if ($commandOverrides.Count -gt 0) {
    if (-not $global:AliasOverrides) {
        $global:AliasOverrides = [System.Collections.Generic.List[PSObject]]::new()
    }
    foreach ($commandOverride in $commandOverrides) {
        $global:AliasOverrides.Add($commandOverride)
    }
}

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

## Define the function to describe the latest tag
function gdct {
    git describe --tags $(git rev-list --tags --max-count=1)
}

function gl { git pull @args }
function ga { git add @args }
function gp { git push @args }
function gaa  { git add --all }
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
function gcfg  { git config --list }
function gclR  { git clone --recurse-submodules }
function gcln  { git clean --interactive -d }
function gtco  { git checkout }
function gchkR  { git checkout --recurse-submodules }
function gtlog  { git shortlog --summary --numbered }
function gchp  { git cherry-pick }
function gchpa  { git cherry-pick --abort }
function gchpc  { git cherry-pick --continue }
function gd  { git diff }
function gdca  { git diff --cached }
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
function gcmsg { git commit -m @args }
function gcmsoMsg { git commit --signoff --message @args }
function gcmtcsigS { git commit --gpg-sign --signoff @args }
function gcmtcssM { git commit --gpg-sign --signoff --message @args }

$gitFunctions = @(
    'gchD','gchm','gdct','gl','ga','gp','gaa','gam','gama','gamc','gams','gamscp',
    'gap','gapa','gapt','gau','gav','gb','gbD','gba','gbd','gbg','gbgD','gbgd',
    'gbl','gchB','gchb','gcfg','gclR','gcln','gtco','gchkR','gtlog','gchp',
    'gchpa','gchpc','gd','gdca','gdcw','gds','gdt','gdw','gf','gfa','gfg','gfo',
    'gg','gga','gpl','glg','glgg','glgga','glgm','glgp','glo','glod','gcam','gst',
    'gcmt','gcmt!','gcmtA','gcmtA!','gcmtna!','gcmtcn!','gcmtcs!','gcmsoA',
    'gcmsoM','gcmtmsg','gcmsg','gcmsoMsg','gcmtcsigS','gcmtcssM'
)
Export-ModuleMember -Function $gitFunctions

