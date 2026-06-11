# Utility functions for package installation
function Write-ModuleColor {
    param(
        [Parameter(Mandatory)][string]$Message,
        [string]$Type = 'White'
    )

    $map = @{
        Error      = 'Red'
        Warning    = 'Yellow'
        Success    = 'Green'
        Info       = 'Cyan'
        Processing = 'DarkCyan'
    }
    $resolved = if ($map.ContainsKey($Type)) { $map[$Type] } else { $Type }
    Write-Host $Message -ForegroundColor $resolved
}

<#
.SYNOPSIS
Checks if a program is installed.

.DESCRIPTION
Validates whether a specified program is installed on the system by searching the PATH or registry.

.PARAMETER ProgramName
The name of the program command to check. This is an alias for CommandName.

.PARAMETER CommandName
The name of the command to check in PATH.

.EXAMPLE
Test-ProgramInstallation -ProgramName "git"

.EXAMPLE
Test-ProgramInstallation -CommandName "pwsh"
#>
function Test-ProgramInstallation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Alias('ProgramName')]
        [ValidateNotNullOrEmpty()]
        [string]$CommandName
    )
    # Check if a command is available in PATH
    return (Get-Command $CommandName -ErrorAction SilentlyContinue) -ne $null
}

<#
.SYNOPSIS
Installs Winget package manager on the system.

.DESCRIPTION
Downloads and installs the latest version of Microsoft's Winget package manager.

.EXAMPLE
Install-WingetPackageManager
#>
function Install-WingetPackageManager {
    try {
        if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
            Write-ModuleColor -Message "Installing Winget..." -Type "Processing"
            Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile "$env:TEMP\Microsoft.DesktopAppInstaller.appxbundle"
            Add-AppxPackage -Path "$env:TEMP\Microsoft.DesktopAppInstaller.appxbundle"
            Write-ModuleColor -Message "Winget installed successfully." -Type "Success"
        } else {
            Write-ModuleColor -Message "Winget is already installed." -Type "Success"
        }
    } catch {
        Write-ModuleColor -Message "Failed to install Winget. Error: $_" -Type "Error"
    }
}

<#
.SYNOPSIS
Installs Chocolatey package manager on the system.

.DESCRIPTION
Sets up Chocolatey, a Windows package manager, for managing software installations.

.EXAMPLE
Install-ChocolateyPackageManager
#>
function Install-ChocolateyPackageManager {
    try {
        if (-not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
            Write-ModuleColor -Message "Installing Chocolatey..." -Type "Processing"
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-ModuleColor -Message "Chocolatey installed successfully." -Type "Success"
        } else {
            Write-ModuleColor -Message "Chocolatey is already installed." -Type "Success"
        }
    } catch {
        Write-ModuleColor -Message "Failed to install Chocolatey. Error: $_" -Type "Error"
    }
}

<#
.SYNOPSIS
Installs Scoop package manager on the system.

.DESCRIPTION
Sets up Scoop, a Windows package manager, for managing software installations.

.EXAMPLE
Install-ScoopPackageManager
#>
function Install-ScoopPackageManager {
    try {
        if (-not (Test-Path "$HOME\scoop")) {
            Write-ModuleColor -Message "Installing Scoop..." -Type "Processing"
            Invoke-Expression (New-Object Net.WebClient).DownloadString('https://get.scoop.sh')
            $env:Path += ";$HOME\scoop\shims"
            Write-ModuleColor -Message "Scoop installed successfully." -Type "Success"
        } else {
            Write-ModuleColor -Message "Scoop is already installed." -Type "Success"
        }
    } catch {
        Write-ModuleColor -Message "Failed to install Scoop. Error: $_" -Type "Error"
    }
}

<#
.SYNOPSIS
Installs a specified program using the configured package manager.

.DESCRIPTION
Uses a selected package manager (e.g., Winget, Chocolatey, Scoop) to install a program.

.PARAMETER ProgramName
The name of the program to install.

.EXAMPLE
Install-Program -ProgramName "nodejs"
#>
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
        Write-ModuleColor -Message "$ProgramName is already installed." -Type "Success"
        return
    }

    # Install using winget, choco, scoop, or PowerShell module
    if ($WingetID -and (Test-ProgramInstallation -CommandName "winget")) {
        Write-ModuleColor -Message "Installing $ProgramName via Winget..." -Type "Processing"
        winget install --id $WingetID -e --silent
    } elseif ($ChocoID -and (Test-ProgramInstallation -CommandName "choco")) {
        Write-ModuleColor -Message "Installing $ProgramName via Chocolatey..." -Type "Processing"
        choco install $ChocoID -y
    } elseif ($ScoopID -and (Test-Path "$HOME\scoop")) {
        Write-ModuleColor -Message "Installing $ProgramName via Scoop..." -Type "Processing"
        scoop install $ScoopID
    } elseif ($PowerShellModuleName) {
        Write-ModuleColor -Message "Installing $ProgramName as a PowerShell module..." -Type "Processing"
        Install-Module -Name $PowerShellModuleName -Force -Scope CurrentUser
    } else {
        Write-ModuleColor -Message "Unable to install $ProgramName. No valid method found." -Type "Error"
    }
}

Export-ModuleMember -Function Test-ProgramInstallation,Install-WingetPackageManager,Install-ChocolateyPackageManager,Install-ScoopPackageManager,Install-Program

