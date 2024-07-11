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

# Alias for git
Set-Alias -Name g -Value git

# Functions for git commands
function ga { git add @args }
function gaa { git add --all @args }
function gam { git am @args }
function gama { git am --abort @args }
function gamc { git am --continue @args }
function gams { git am --skip @args }
function gamscp { git am --show-current-patch @args }
function gap { git apply @args }
function gapa { git add --patch @args }
function gapt { git apply --3way @args }
function gau { git add --update @args }
function gav { git add --verbose @args }
function gb { git branch @args }
function gbD { git branch --delete --force @args }
function gba { git branch --all @args }
function gbd { git branch --delete @args }
function gbg { git branch -vv | Select-String ': gone\]' @args }
function gbgD { git branch -vv | Select-String ': gone\]' | ForEach-Object { git branch -D $_.Matches[0] } @args }
function gbgd { git branch -vv | Select-String ': gone\]' | ForEach-Object { git branch -d $_.Matches[0] } @args }
function gbl { git blame -w @args }
function gcmt { git commit --verbose @args }
Set-Alias -Name 'gcmt!' -Value "git commit --verbose --amend"
function gchB { git checkout -B @args }
function gcmtA { git commit --verbose --all @args }
Set-Alias -Name 'gcmtA!' -Value "git commit --verbose --all --amend"
function gcmA { param([string]$Message) git commit --all --message "$Message" }
Set-Alias -Name 'gcmtna!' -Value "git commit --verbose --all --no-edit --amend"
Set-Alias -Name 'gcmtcn!' -Value "git commit --verbose --all --date=now --no-edit --amend"
Set-Alias -Name 'gcmtcs!' -Value "git commit --verbose --all --signoff --no-edit --amend"
function gcmsoA { git commit --all --signoff @args }
function gcmsoM { git commit --all --signoff --message @args }
function gchb { git checkout -b @args }
function gchD { git checkout develop @args }
function gcfg { git config --list @args }
function gclR { git clone --recurse-submodules @args }
function gcln { git clean --interactive -d @args }
function gchm { git checkout main @args }
function gcmtmsg { git commit --message @args }
function gtco { git checkout @args }
function gchkR { git checkout --recurse-submodules @args }
function gtlog { git shortlog --summary --numbered @args }
function gchp { git cherry-pick @args }
function gchpa { git cherry-pick --abort @args }
function gchpc { git cherry-pick --continue @args }
function gcmsg { git commit --gpg-sign @args }
function gcmsoMsg { git commit --signoff --message @args }
function gcmtcsigS { git commit --gpg-sign --signoff @args }
function gcmtcssM { git commit --gpg-sign --signoff --message @args }

# Example usage
# Add-PersistentVariable -VariableName "OBSIDIAN" -Value "C:\Users\mcarls\Documents\Obsidian-Vault\"



# Variables Added to Profile from Add-Variable.ps1 script.
$global:OBSIDIAN = 'C:\Users\mcarls\Documents\Obsidian-Vault\'
