# Profile for Current User Current Host located at $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
# To use this profile rename it to Microsoft.PowerShell_profile.ps1 and move it to the above directory
# cp ProfileCUCH.ps1 $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1

# Initialize Oh-My-Posh with the desired theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression

# PowerToys CommandNotFound module (Optional: comment out if causing issues)
# Import-Module -Name Microsoft.WinGet.CommandNotFound

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58

# Initialize fnm (Fast Node Manager) environment variables
fnm env | ForEach-Object { Invoke-Expression $_ }

function GitMan {
    param ($Subcommand)
    git help -m $Subcommand | groff -T ascii -man | more
}

Set-Alias gitman GitMan


# Setting Aliases, lots of UNIX aliases have been converted to powershell here
# Functions for changing directories
$originalSetLocation = Get-Command Set-Location -CommandType Cmdlet

# Define a custom Set-Location function
function Set-Location {
    param (
        [string]$path
    )

    switch ($path) {
        '...' { & $originalSetLocation ../.. }
        '....' { & $originalSetLocation ../../.. }
        '.....' { & $originalSetLocation ../../../.. }
        '......' { & $originalSetLocation ../../../../.. }
        default { & $originalSetLocation $path }
    }
}

# Alias cd to our custom Set-Location function
Function cdd { Set-Location "C:\Users\mcarls\Documents\" }
Function cdobs { Set-Location "C:\Users\mcarls\Documents\Obsidian-Vault\" }
Function cdp { Set-Location "C:\Projects\" }
Function cdps { Set-Location "C:\Projects\W11-powershell\Scripts\" }

# Alias for navigating to the previous directory (if needed, implement a custom solution as PowerShell does not support 'cd -')
Function GoBack {
    if ($global:PreviousLocation) {
        Set-Location $global:PreviousLocation
    }
    else {
        Write-Host "No previous location found."
    }
}
Set-Alias -Name '-' -Value GoBack

# Quick Directory Navigation (custom implementation required)
$global:LocationStack = @()

Function Push-LocationStack {
    $global:LocationStack += (Get-Location).Path
}
Function Pop-LocationStack {
    $index = $args[0]
    if ($index -lt $global:LocationStack.Count) {
        $path = $global:LocationStack[$index]
        $global:LocationStack = $global:LocationStack[0..($index - 1)]
        Set-Location $path
    }
    else {
        Write-Host "No such location in stack."
    }
}

Function 1 { Pop-LocationStack 1 }
Function 2 { Pop-LocationStack 2 }
Function 3 { Pop-LocationStack 3 }
Function 4 { Pop-LocationStack 4 }
Function 5 { Pop-LocationStack 5 }
Function 6 { Pop-LocationStack 6 }
Function 7 { Pop-LocationStack 7 }
Function 8 { Pop-LocationStack 8 }
Function 9 { Pop-LocationStack 9 }

# Ensure the location is pushed every time the location changes
Register-EngineEvent PowerShell.OnIdle -Action { Push-LocationStack }

# Sudo Simulation
Function _ { Start-Process powershell -Verb runAs -ArgumentList ($args -join ' ') }

# ag searches for aliases whose commands match the pattern
Remove-Item Alias:ag -ErrorAction SilentlyContinue
Remove-Item Function:ag -ErrorAction SilentlyContinue

function aliasGrepFunction {
    param(
        [string]$Pattern
    )
    Get-Alias | Where-Object { $_.Definition -match $Pattern -or $_.Name -match $Pattern } | Format-Table -Property Name, Definition
}

Set-Alias -Name ag -Value aliasGrepFunction 

# grep implementation for powershell
function grepFunction {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$InputObject
    )
    process {
        $InputObject | Select-String -Pattern $Pattern
    }
}

Set-Alias -Name grep -Value grepFunction



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

# Git Aliases with new prefixes

## Define the function to describe the latest tag
function gdct {
    git describe --tags $(git rev-list --tags --max-count=1)
}


# Simple aliases that don't need to take parameters
Set-Alias -Name g -Value "git"
Set-Alias -Name ga  -Value "git add"
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

# Example usage
# Add-PersistentVariable -VariableName "OBSIDIAN" -Value "C:\Users\mcarls\Documents\Obsidian-Vault\"



# Variables Added to Profile from Add-Variable.ps1 script.
$global:OBSIDIAN = 'C:\Users\mcarls\Documents\Obsidian-Vault\'
$global:SCRIPTS = 'C:\Projects\W11-powershell\'
