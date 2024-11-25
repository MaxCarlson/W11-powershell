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
Set-Alias -Name cdobs -Value Set-Location 

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
Set-Alias -Name g -Value git
Set-Alias -Name ga -Value "git add"
Set-Alias -Name gaa -Value "git add --all"
Set-Alias -Name gam -Value "git am"
Set-Alias -Name gama -Value "git am --abort"
Set-Alias -Name gamc -Value "git am --continue"
Set-Alias -Name gams -Value "git am --skip"
Set-Alias -Name gamscp -Value "git am --show-current-patch"
Set-Alias -Name gap -Value "git apply"
Set-Alias -Name gapa -Value "git add --patch"
Set-Alias -Name gapt -Value "git apply --3way"
Set-Alias -Name gau -Value "git add --update"
Set-Alias -Name gav -Value "git add --verbose"
Set-Alias -Name gb -Value "git branch"
Set-Alias -Name gbD -Value "git branch --delete --force"
Set-Alias -Name gba -Value "git branch --all"
Set-Alias -Name gbd -Value "git branch --delete"
Set-Alias -Name gbg -Value "git branch -vv | Select-String ': gone\]'"
Set-Alias -Name gbgD -Value "git branch -vv | Select-String ': gone\]' | ForEach-Object { git branch -D $_.Matches[0] }"
Set-Alias -Name gbgd -Value "git branch -vv | Select-String ': gone\]' | ForEach-Object { git branch -d $_.Matches[0] }"
Set-Alias -Name gbl -Value "git blame -w"
Set-Alias -Name gchB -Value "git checkout -B"
Set-Alias -Name gchb -Value "git checkout -b"
Set-Alias -Name gchD -Value gchD
Set-Alias -Name gcfg -Value "git config --list"
Set-Alias -Name gclR -Value "git clone --recurse-submodules"
Set-Alias -Name gcln -Value "git clean --interactive -d"
Set-Alias -Name gchm -Value gchm
Set-Alias -Name gtco -Value "git checkout"
Set-Alias -Name gchkR -Value "git checkout --recurse-submodules"
Set-Alias -Name gtlog -Value "git shortlog --summary --numbered"
Set-Alias -Name gchp -Value "git cherry-pick"
Set-Alias -Name gchpa -Value "git cherry-pick --abort"
Set-Alias -Name gchpc -Value "git cherry-pick --continue"
Set-Alias -Name gd -Value "git diff"
Set-Alias -Name gdca -Value "git diff --cached"
Set-Alias -Name gdct -Value gdct
Set-Alias -Name gdcw -Value "git diff --cached --word-diff"
Set-Alias -Name gds -Value "git diff --staged"
Set-Alias -Name gdt -Value "git diff-tree --no-commit-id --name-only -r"
Set-Alias -Name gdup -Value "git diff @{upstream}"
Set-Alias -Name gdw -Value "git diff --word-diff"
Set-Alias -Name gf -Value "git fetch"
Set-Alias -Name gfa -Value "git fetch --all --prune --jobs=10"
Set-Alias -Name gfg -Value "git ls-files | Select-String"
Set-Alias -Name gfo -Value "git fetch origin"
Set-Alias -Name gg -Value "git gui citool"
Set-Alias -Name gga -Value "git gui citool --amend"
Set-Alias -Name gpl -Value "git pull"
Set-Alias -Name glg -Value "git log --stat"
Set-Alias -Name glgg -Value "git log --graph"
Set-Alias -Name glgga -Value "git log --graph --decorate --all"
Set-Alias -Name glgm -Value "git log --graph --max-count=10"
Set-Alias -Name glgp -Value "git log --stat --patch"
Set-Alias -Name glo -Value "git log --oneline --decorate"
Set-Alias -Name glod -Value "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'"

# Functions for commands that need to take parameters
function gcmA {
    param (
        [string]$Message
    )
    git commit --all --message "$Message"
}

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
