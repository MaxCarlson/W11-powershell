# Utility functions for package installation

function Test-ProgramInstallation {
    param (
        [string]$CommandName
    )
    # Check if a command is available in PATH
    return (Get-Command $CommandName -ErrorAction SilentlyContinue) -ne $null
}

function Install-WingetPackageManager {
    try {
        if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
            Write-Color -Message "Installing Winget..." -Type "Processing"
            Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile "$env:TEMP\Microsoft.DesktopAppInstaller.appxbundle"
            Add-AppxPackage -Path "$env:TEMP\Microsoft.DesktopAppInstaller.appxbundle"
            Write-Color -Message "Winget installed successfully." -Type "Success"
        } else {
            Write-Color -Message "Winget is already installed." -Type "Success"
        }
    } catch {
        Write-Color -Message "Failed to install Winget. Error: $_" -Type "Error"
    }
}

function Install-ChocolateyPackageManager {
    try {
        if (-not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
            Write-Color -Message "Installing Chocolatey..." -Type "Processing"
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-Color -Message "Chocolatey installed successfully." -Type "Success"
        } else {
            Write-Color -Message "Chocolatey is already installed." -Type "Success"
        }
    } catch {
        Write-Color -Message "Failed to install Chocolatey. Error: $_" -Type "Error"
    }
}

function Install-ScoopPackageManager {
    try {
        if (-not (Test-Path "$HOME\scoop")) {
            Write-Color -Message "Installing Scoop..." -Type "Processing"
            Invoke-Expression (New-Object Net.WebClient).DownloadString('https://get.scoop.sh')
            $env:Path += ";$HOME\scoop\shims"
            Write-Color -Message "Scoop installed successfully." -Type "Success"
        } else {
            Write-Color -Message "Scoop is already installed." -Type "Success"
        }
    } catch {
        Write-Color -Message "Failed to install Scoop. Error: $_" -Type "Error"
    }
}

function Install-Program {
    param (
        [string]$ProgramName,
        [string]$WingetID,
        [string]$ChocoID,
        [string]$ScoopID,
        [string]$PowerShellModuleName
    )

    # Skip if already installed
    if (Test-ProgramInstallation -CommandName $ProgramName) {
        Write-Color -Message "$ProgramName is already installed." -Type "Success"
        return
    }

    # Install using winget, choco, scoop, or PowerShell module
    if ($WingetID -and (Test-ProgramInstallation -CommandName "winget")) {
        Write-Color -Message "Installing $ProgramName via Winget..." -Type "Processing"
        winget install --id $WingetID -e --silent
    } elseif ($ChocoID -and (Test-ProgramInstallation -CommandName "choco")) {
        Write-Color -Message "Installing $ProgramName via Chocolatey..." -Type "Processing"
        choco install $ChocoID -y
    } elseif ($ScoopID -and (Test-Path "$HOME\scoop")) {
        Write-Color -Message "Installing $ProgramName via Scoop..." -Type "Processing"
        scoop install $ScoopID
    } elseif ($PowerShellModuleName) {
        Write-Color -Message "Installing $ProgramName as a PowerShell module..." -Type "Processing"
        Install-Module -Name $PowerShellModuleName -Force -Scope CurrentUser
    } else {
        Write-Color -Message "Unable to install $ProgramName. No valid method found." -Type "Error"
    }
}

