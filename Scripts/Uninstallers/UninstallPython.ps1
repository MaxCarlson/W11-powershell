# Ensure running as Administrator
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Debug -Channel "Error" -Message "Please run PowerShell as Administrator!"
    Exit
}

Write-Debug -Channel "Information" -Message "`n==== Removing Python, Anaconda, Miniconda, and Python Launcher ===="

# Function to uninstall packages via winget
function Uninstall-WingetPackage($PackageId) {
    $installed = winget list --id $PackageId 2>$null
    if ($installed -match $PackageId) {
        Write-Debug -Channel "Information" -Message "Uninstalling $PackageId via winget..."
        winget uninstall --id $PackageId --force
    } else {
        Write-Debug -Channel "Success" -Message "$PackageId is not installed via winget."
    }
}

# Uninstall known winget packages
Uninstall-WingetPackage "Anaconda.Anaconda3"
Uninstall-WingetPackage "Anaconda.Miniconda3"
Uninstall-WingetPackage "Python.Launcher"

# Uninstall ALL versions of Python detected by winget
$pythonPackages = winget list --name Python | ForEach-Object { ($_ -split "\s{2,}")[0] }
foreach ($package in $pythonPackages) {
    if ($package -match "Python.Python") {
        Write-Debug -Channel "Information" -Message "Uninstalling $package via winget..."
        winget uninstall --id $package --force
    }
}

# Remove known Python-related directories
$pythonDirs = @(
    "$env:LOCALAPPDATA\Programs\Python",
    "$env:PROGRAMFILES\Python*",
    "$env:PROGRAMFILES\Python Launcher",
    "$env:LOCALAPPDATA\Anaconda3",
    "$env:LOCALAPPDATA\Continuum",
    "$env:LOCALAPPDATA\Miniconda3",
    "$env:LOCALAPPDATA\conda",
    "$env:USERPROFILE\.condarc",
    "$env:USERPROFILE\.conda",
    "$env:USERPROFILE\.anaconda"
)

foreach ($dir in $pythonDirs) {
    if (Test-Path $dir) {
        Write-Debug -Channel "Information" -Message "Removing directory: $dir"
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Remove Python-related registry keys
$pythonRegistryKeys = @(
    "HKCU:\Software\Python",
    "HKLM:\Software\Python",
    "HKCU:\Software\PythonLauncher",
    "HKLM:\Software\PythonLauncher",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Python*",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Python*"
)

foreach ($key in $pythonRegistryKeys) {
    if (Test-Path $key) {
        Write-Debug -Channel "Information" -Message "Removing registry key: $key"
        Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Remove Python-related environment variables
$pythonEnvVars = @(
    "PYTHONHOME",
    "PYTHONPATH"
)

foreach ($var in $pythonEnvVars) {
    if (Test-Path "HKCU:\Environment\$var") {
        Write-Debug -Channel "Information" -Message "Removing environment variable: $var"
        Remove-ItemProperty -Path "HKCU:\Environment" -Name $var -ErrorAction SilentlyContinue
    }
    if (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\$var") {
        Write-Debug -Channel "Information" -Message "Removing system-wide environment variable: $var"
        Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -Name $var -ErrorAction SilentlyContinue
    }
}

# Remove Python from PATH (User & Machine)
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User") -split ";" | Where-Object { $_ -notmatch "anaconda|conda|python" }
$systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" | Where-Object { $_ -notmatch "anaconda|conda|python" }

Write-Debug -Channel "Information" -Message "Updating User PATH..."
[System.Environment]::SetEnvironmentVariable("Path", ($userPath -join ";"), "User")

Write-Debug -Channel "Information" -Message "Updating System PATH..."
[System.Environment]::SetEnvironmentVariable("Path", ($systemPath -join ";"), "Machine")

Write-Debug -Channel "Success" -Message "Python and related components have been successfully removed."
Write-Debug -Channel "Success" -Message "Restart your system for all changes to take full effect."

