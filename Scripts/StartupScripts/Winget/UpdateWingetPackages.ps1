# UpdateWingetPackages.ps1

function Start-ElevatedProcess {
    param(
        [string]$Command,
        [switch]$WaitForExit
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-Command `"& { $Command }`""
    $psi.Verb = "runas"
    $psi.WindowStyle = "Normal"

    $process = [System.Diagnostics.Process]::Start($psi)

    if ($WaitForExit) {
        $process.WaitForExit()
    }
}

# TODO: Maybe move this to a sepperate file for helper functions
function Ensure-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Output "Not running as Administrator. Attempting to restart with elevated privileges..."
        Start-ElevatedProcess -Command $MyInvocation.Line -WaitForExit
        exit
    }
}

function Get-UpgradablePackages {
    # Get the list of upgradable packages
    $packages = winget upgrade --source winget | ConvertFrom-String | Select-Object -Skip 1 | ForEach-Object {
        $_.P1
    }
    return $packages
}

function Upgrade-Package {
    param (
        [string]$package
    )

    $command = "winget upgrade $package --accept-source-agreements --accept-package-agreements"
    Write-Output "Attempting to update $package without administrative privileges..."
    $output = & powershell.exe -Command $command 2>&1
    $output | ForEach-Object { Write-Output $_ }

    # Check if the output indicates a need for administrative privileges
    if ($output -match "Access is denied" -or $output -match "requires elevation") {
        Write-Output "$package requires administrative privileges. Adding to elevation list..."
        $requiresElevation += $package
    }
}

function Update-Packages {
    param (
        [array]$packages
    )

    $requiresElevation = @()

    foreach ($package in $packages) {
        $command = "winget upgrade $package --accept-source-agreements --accept-package-agreements"
        Write-Output "Attempting to update $package without administrative privileges..."
        $output = & powershell.exe -Command $command 2>&1
        $output | ForEach-Object { Write-Output $_ }

        # Check if the output indicates a need for administrative privileges
        if ($output -match "Access is denied" -or $output -match "requires elevation") {
            Write-Output "$package requires administrative privileges. Adding to elevation list..."
            $requiresElevation += $package
        }
    }

    # If there are packages that require elevation, elevate once and update all
    if ($requiresElevation.Count -gt 0) {
        $elevatedCommand = $requiresElevation -join ' ' | ForEach-Object { "winget upgrade $_ --accept-source-agreements --accept-package-agreements" }
        Start-ElevatedProcess -Command $elevatedCommand -WaitForExit
    }
}

# Ensure the script is running with administrative privileges at the start
#Ensure-Admin
$packages = Get-UpgradablePackages

Update-Packages -packages $packages
