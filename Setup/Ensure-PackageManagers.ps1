<#
.SYNOPSIS
    Installs Chocolatey and Cygwin if they are not already present.
.DESCRIPTION
    - Checks for `choco` and installs via the official PowerShell script if missing.
    - Checks for Cygwin (`bash.exe`) and installs via WinGet; then downloads setup-x86_64.exe.
#>

# --- Chocolatey ---
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    iex ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-Host "Chocolatey is already installed."
}

# --- Cygwin ---
if (-not (Test-Path 'C:\cygwin64\bin\bash.exe')) {
    Write-Host "Installing Cygwin via WinGet..."
    winget install --id=Cygwin.Cygwin --exact -e

    Write-Host "Downloading the official Cygwin setup program..."
    Invoke-WebRequest `
      -Uri 'https://cygwin.com/setup-x86_64.exe' `
      -OutFile 'C:\cygwin64\setup-x86_64.exe'
} else {
    Write-Host "Cygwin is already installed."
}

