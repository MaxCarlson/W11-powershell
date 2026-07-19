if (-not $global:ModuleImportedCDModule) {
    $global:ModuleImportedCDModule = $true
} else {
    Write-Debug -Message "Attempting to import module twice!" -Channel "Error" -Condition $DebugProfile -FileAndLine
    return
}

# Directory navigation functions using dynamic paths from profile
# These paths are auto-detected in CustomProfile.ps1

# Module-local navigation roots. Keep dependent destinations derived from these
# values so a folder move normally needs one update here.
$script:HomePath = $HOME
$script:DotfilesPath = Join-Path $script:HomePath 'src\dotfiles'
$script:DownloadsPath = Join-Path $script:HomePath 'Downloads'
$script:ObsidianVaultPath = Join-Path $script:HomePath 'Documents\Obsidian-Vault'
$script:ScriptsRepoFallbackPath = Join-Path $script:HomePath 'Repos\scripts'
$script:PowerShellRepoFallbackPath = Join-Path $script:HomePath 'Repos\W11-powershell'
$script:DotfilesRepoFallbackPath = Join-Path $script:HomePath 'dotfiles'
$script:CTorrentsPath = 'C:\Torrents'
$script:DTorrentsPath = 'D:\Torrents'
$script:PicturesSavedPath = 'D:\Pictures\Saved'
$script:TmpVidsPath = Join-Path $script:PicturesSavedPath 'tmpvids'
$script:YtaedlConfinementPath = Join-Path $script:TmpVidsPath 'ytaedl_confinement'
$script:PicturesPath = Join-Path $script:PicturesSavedPath 'Pics'
$script:HentaiImagesPath = Join-Path $script:PicturesPath 'hentaiImages'

# Standard Windows directories
function cdd { Set-Location $script:DotfilesPath }
function cddl { Set-Location $script:DownloadsPath }
function cdobs { Set-Location $script:ObsidianVaultPath }

# Repository directories (dynamically detected)
function cdsrc {
    if ($global:REPOS_DIR -and (Test-Path $global:REPOS_DIR)) {
        Set-Location $global:REPOS_DIR
    } else {
        Write-Warning "REPOS_DIR not found. Set `$env:SCRIPTS_REPO or `$env:PWSH_REPO"
        Set-Location (Join-Path $script:HomePath 'Repos')
    }
}

function cds {
    if ($global:SCRIPTS_REPO -and (Test-Path $global:SCRIPTS_REPO)) {
        Set-Location $global:SCRIPTS_REPO
    } else {
        Write-Warning "SCRIPTS_REPO not found. Set `$env:SCRIPTS_REPO"
        Set-Location $script:ScriptsRepoFallbackPath
    }
}

function cdsm {
    if ($global:SCRIPTS_REPO -and (Test-Path $global:SCRIPTS_REPO)) {
        Set-Location (Join-Path $global:SCRIPTS_REPO "modules")
    } else {
        Set-Location (Join-Path $script:ScriptsRepoFallbackPath 'modules')
    }
}

function cdspy {
    if ($global:SCRIPTS_REPO -and (Test-Path $global:SCRIPTS_REPO)) {
        Set-Location (Join-Path $global:SCRIPTS_REPO "pyscripts")
    } else {
        Set-Location (Join-Path $script:ScriptsRepoFallbackPath 'pyscripts')
    }
}

function cdsps {
    if ($global:SCRIPTS_REPO -and (Test-Path $global:SCRIPTS_REPO)) {
        Set-Location (Join-Path $global:SCRIPTS_REPO "pscripts")
    } else {
        Set-Location (Join-Path $script:ScriptsRepoFallbackPath 'pscripts')
    }
}

function cdre { cdsrc }

function cdpwsh {
    if ($global:PWSH_REPO -and (Test-Path $global:PWSH_REPO)) {
        Set-Location $global:PWSH_REPO
    } else {
        Write-Warning "PWSH_REPO not found. Set `$env:PWSH_REPO"
        Set-Location $script:PowerShellRepoFallbackPath
    }
}

function cdps { cdpwsh }

function cdmo {
    if ($global:PWSH_REPO -and (Test-Path $global:PWSH_REPO)) {
        Set-Location (Join-Path $global:PWSH_REPO "Config\Modules")
    } else {
        Set-Location (Join-Path $script:PowerShellRepoFallbackPath 'Config\Modules')
    }
}

function cddot {
    if ($global:DOTFILES_REPO -and (Test-Path $global:DOTFILES_REPO)) {
        Set-Location $global:DOTFILES_REPO
    } else {
        Write-Warning "DOTFILES_REPO not found. Set `$env:DOTFILES_REPO"
        Set-Location $script:DotfilesRepoFallbackPath
    }
}
function cdtor { Set-Location $script:CTorrentsPath }
function cdtord { Set-Location $script:DTorrentsPath }
function cdpo { Set-Location $script:PicturesSavedPath }
function cdpon { Set-Location $script:TmpVidsPath }
function cdpony { Set-Location $script:YtaedlConfinementPath }
function cdpoi { Set-Location $script:PicturesPath }
function cdpoh { Set-Location $script:HentaiImagesPath }

# Setting Aliases, lots of UNIX aliases have been converted to powershell here
# Functions for changing directories
$originalSetLocation = Get-Command Set-Location -CommandType Cmdlet

# Define a custom Set-Location function
#function Set-Location {
#    param (
#        [string]$path
#    )
#
#    switch ($path) {
#        '...' { & $originalSetLocation ../.. }
#        '....' { & $originalSetLocation ../../.. }
#        '.....' { & $originalSetLocation ../../../.. }
#        '......' { & $originalSetLocation ../../../../.. }
#        default { & $originalSetLocation $path }
#    }
#}
#
#
## Alias for navigating to the previous directory (if needed, implement a custom solution as PowerShell does not support 'cd -')
#function GoBack {
#    if ($global:PreviousLocation) {
#        Set-Location $global:PreviousLocation
#    }
#    else {
#        Write-Host "No previous location found."
#    }
#}
#Set-Alias -Name '-' -Value GoBack
#
## Quick Directory Navigation (custom implementation required)
#$global:LocationStack = @()
#
#function Push-LocationStack {
#    $global:LocationStack += (Get-Location).Path
#}
#function Pop-LocationStack {
#    $index = $args[0]
#    if ($index -lt $global:LocationStack.Count) {
#        $path = $global:LocationStack[$index]
#        $global:LocationStack = $global:LocationStack[0..($index - 1)]
#        Set-Location $path
#    }
#    else {
#        Write-Host "No such location in stack."
#    }
#}
#
#function 1 { Pop-LocationStack 1 }
#function 2 { Pop-LocationStack 2 }
#function 3 { Pop-LocationStack 3 }
#function 4 { Pop-LocationStack 4 }
#function 5 { Pop-LocationStack 5 }
#function 6 { Pop-LocationStack 6 }
#function 7 { Pop-LocationStack 7 }
#function 8 { Pop-LocationStack 8 }
#function 9 { Pop-LocationStack 9 }
#
## Ensure the location is pushed every time the location changes
#Register-EngineEvent PowerShell.OnIdle -Action { Push-LocationStack }


# zoxide version

# Initialize zoxide if installed
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    # Initialize zoxide to create the z command
    if (-not (Get-Command z -ErrorAction SilentlyContinue)) {
        try {
            Invoke-Expression (& zoxide init powershell | Out-String)
        } catch {
            Write-Warning "Failed to initialize zoxide: $_"
        }
    }
} else {
    Write-Warning "zoxide not found. Install it with: winget install ajeetdsouza.zoxide"
}

# Check if z command is available after initialization
if (-not (Get-Command z -ErrorAction SilentlyContinue)) {
    Write-Warning "zoxide (z command) not available. CDModule will work with limited functionality."
    # Don't return - allow module to load with other functions
}

# Alias cd to z (zoxide) directly
#Set-Alias -Name cd -Value z -Option AllScope
#Set-Alias -Name z -Value z



# Function to navigate to the nth previous directory
#function cd {
#    param (
#        [Parameter(Mandatory=$false)][int]$n
#    )
#
#    if ($n -and $n -gt 0) {
#        # Fetch the list of directories from zoxide's database
#        $dirs = zoxide query --list
#
#        # Ensure the requested index exists in the list
#        if ($n -le $dirs.Count) {
#            # Navigate to the nth previous directory
#            Set-Location $dirs[$n - 1]
#        } else {
#            Write-Host "Index $n is out of range. Only $($dirs.Count) directories are available in history."
#        }
#    } elseif ($n -eq 0 -or !$n) {
#        # Default behavior: delegate to zoxide
#        z
#    } else {
#        Write-Host "Invalid input. Use a positive number for 'cd -n' functionality."
#    }
#}


# Multi-level navigation shortcuts
#function Set-Location {
#    param (
#        [string]$path
#    )
#
#    switch ($path) {
#        '...' { cd .. }
#        '....' { cd ../.. }
#        '.....' { cd ../../.. }
#        '......' { cd ../../../.. }
#        '.......' { cd ../../../../.. }
#        default { cd $path }
#    }
#}
