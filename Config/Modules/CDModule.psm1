if (-not $global:ModuleImportedCDModule) {
    $global:ModuleImportedCDModule = $true
} else {
    Write-Debug -Message "Attempting to import module twice!" -Channel "Error" -Condition $DebugProfile -FileAndLine
    return
}

# Alias cd to our custom Set-Location function
function cdd { Set-Location "$HOME\Documents\" }
function cddl { Set-Location "$HOME\Downloads\"}
function cdobs { Set-Location "$HOME\Documents\Obsidian-Vault\" }
function cdsrc { Set-Location "$HOME\Repos\" }
function cds { Set-Location "$HOME\Repos\scripts\" }
function cdsps { Set-Location "$HOME\Repos\scripts\pscripts\" }

function cdre { cdsrc }
function cdpwsh { Set-Location "$HOME\Repos\W11-powershell\" }
function cdps { cdpwsh }
function cdmo { Set-Location "$HOME\Repos\W11-powershell\Config\Modules"}
function cdtor { Set-Location "C:\Torrents"}
function cdtord { Set-Location "D:\Torrents"}
function cdpo { Set-Location "D:\Pictures\Saved\" }
function cdpon { Set-Location "D:\Pictures\Saved\tmpvids" }
function cdpoi { Set-Location "D:\Pictures\Saved\Pics\" }
function cdpoh { Set-Location "D:\Pictures\Saved\Pics\hentaiImages" }

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

# Ensure zoxide is installed and accessible
if (-not (Get-Command z -ErrorAction SilentlyContinue)) {
    # TODO: Place non-zoxide code in here?
    Write-Error "zoxide (z) is not installed or accessible. Please install it first."
    return
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
