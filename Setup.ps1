# File: Setup.ps1
# Main Orchestrator Script
# Ensure this script is run as Administrator for full functionality.

# --- Administrator Check ---
function Assert-Administrator-Main {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        Write-Warning "This setup script performs operations that require Administrator privileges (e.g., installing software, managing scheduled tasks, configuring firewall/network)."
        $choice = Read-Host "Do you want to attempt to re-launch as Administrator? (y/N)"
        if ($choice -eq 'y') {
            Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`"" -Verb RunAs
            exit # Exit current non-admin session
        } else {
            Write-Error "Administrator privileges are required. Please re-run this script as an Administrator."
            # Optionally, allow to continue with a warning if some parts can run without admin
            # Read-Host "Press Enter to continue without admin rights (some operations may fail), or Ctrl+C to exit."
            exit 1 # Or just exit
        }
    }
}
Assert-Administrator-Main

# --- Script Base Path ---
# $PSScriptRoot is the directory where the current script (Setup.ps1) is located.
$ScriptBase = $PSScriptRoot
Write-Host "Setup script running from: $ScriptBase" -ForegroundColor Yellow

# --- Shared user-level setup (idempotent, also used by Setup-NoAdmin.ps1) ---
$sharedUserSetup = Join-Path $ScriptBase "Setup\UserSetupCore.ps1"
if (Test-Path $sharedUserSetup) {
    . $sharedUserSetup -ScriptBase $ScriptBase
} else {
    Write-Warning "Shared user setup not found at $sharedUserSetup"
}

# --- Core prerequisites that need admin ---
Write-Host "--- Ensuring PowerShell + PSReadLine ---" -ForegroundColor Cyan
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    try {
        winget install --id Microsoft.PowerShell -e --accept-package-agreements --accept-source-agreements
        Write-Host "PowerShell (pwsh) installation command executed." -ForegroundColor Green
    } catch {
        Write-Warning ("PowerShell installation failed: {0}" -f $_)
    }
} else {
    Write-Host "PowerShell (pwsh) already available." -ForegroundColor DarkGray
}

if (-not (Get-Module -ListAvailable -Name PSReadLine)) {
    try {
        if (-not (Get-Module -ListAvailable -Name PowerShellGet)) {
            Write-Host "Installing PowerShellGet (all users)..." -ForegroundColor DarkGray
            Install-Module -Name PowerShellGet -Force -Scope AllUsers -AllowClobber -ErrorAction Stop
        }
        Install-Module -Name PSReadLine -Force -Scope AllUsers -AllowClobber -ErrorAction Stop
        Write-Host "PSReadLine installed for all users." -ForegroundColor Green
    } catch {
        Write-Warning ("PSReadLine installation failed: {0}" -f $_)
    }
} else {
    Write-Host "PSReadLine already installed." -ForegroundColor DarkGray
}

# --- Initial Setup Scripts ---
Write-Host "--- Running initial setup scripts... ---" -ForegroundColor Cyan
$initialSetupScripts = @(
    "Scripts\SetupScripts\StartSSHAgent.ps1",
    "Scripts\SetupScripts\ProgramBackup.ps1" # Added default parameters as per your original
)
foreach ($scriptRelPath in $initialSetupScripts) {
    $scriptFullPath = Join-Path -Path $ScriptBase -ChildPath $scriptRelPath
    if (Test-Path $scriptFullPath) {
        Write-Host "Executing: $scriptFullPath"
        try {
            if ($scriptRelPath -eq "Scripts\SetupScripts\ProgramBackup.ps1") {
                & $scriptFullPath -Setup -BackupFrequency Daily -UpdateFrequency Daily -ErrorAction Stop
            } else {
                & $scriptFullPath -ErrorAction Stop
            }
        } catch {
            Write-Warning ("Error executing {0}: {1}" -f $scriptFullPath, $_)
        }
    } else {
        Write-Warning "Initial setup script not found: $scriptFullPath"
    }
}

# --- Setup Executables in bin/ ---
Write-Host "--- Setting up executables in bin/... ---" -ForegroundColor Cyan
$setupExecutablesScript = Join-Path -Path $env:PWSH_REPO -ChildPath "Setup\SetupExecutables.ps1"
if (Test-Path $setupExecutablesScript) {
    Write-Host "Executing: $setupExecutablesScript"
    try {
        & $setupExecutablesScript -ErrorAction Stop
    } catch {
        Write-Warning ("Error executing {0}: {1}" -f $setupExecutablesScript, $_)
    }
} else {
    Write-Warning "SetupExecutables.ps1 not found at: $setupExecutablesScript"
}

# --- Ensure Package Managers and Core Tools ---
# Assuming Ensure-PackageManagers.ps1 and Install-Packages.ps1 are in a "Setup" subdirectory
$packageManagerSetupScript = Join-Path -Path $ScriptBase -ChildPath "Setup\Ensure-PackageManagers.ps1"
if (Test-Path $packageManagerSetupScript) {
    Write-Host "--- Ensuring package managers are available... ---" -ForegroundColor Cyan
    Write-Host "Executing: $packageManagerSetupScript"
    . $packageManagerSetupScript # Source it to make functions available if needed, or use &
} else {
    Write-Warning "Ensure-PackageManagers.ps1 not found at $packageManagerSetupScript"
}

# --- Package-list management & installation ---
$installPackagesScript = Join-Path -Path $ScriptBase -ChildPath "Setup\Install-Packages.ps1"
if (Test-Path $installPackagesScript) {
    Write-Host "--- Installing packages from lists... ---" -ForegroundColor Cyan
    Write-Host "Executing: $installPackagesScript"
    . $installPackagesScript # Source it, or use &
} else {
    Write-Warning "Install-Packages.ps1 not found at $installPackagesScript"
}

# --- Update Windows PATH for newly installed tools (e.g., Cygwin) ---
$updateEnvPathsScript = Join-Path -Path $ScriptBase -ChildPath "Setup\Update-EnvironmentPaths.ps1"
if (Test-Path $updateEnvPathsScript) {
    Write-Host "--- Updating environment paths... ---" -ForegroundColor Cyan
    Write-Host "Executing: $updateEnvPathsScript"
    . $updateEnvPathsScript # Source it, or use &
} else {
    Write-Warning "Update-EnvironmentPaths.ps1 not found at $updateEnvPathsScript"
}

# --- WSL Setup (Simplified and Optional by Default) ---
$EnsureWSLBasicsScriptPath = Join-Path -Path $ScriptBase -ChildPath "Setup\Ensure-WSLBasics.ps1" # Ensure this is the correct path to your new script

if (Test-Path $EnsureWSLBasicsScriptPath) {
    Write-Host "--- WSL2 Basic Setup ---" -ForegroundColor Cyan
    $runWslSetup = Read-Host "Do you want to run the basic WSL2 setup (ensures WSL/Ubuntu, OpenSSH server, and SSH port forwarding)? (y/N)"
    if ($runWslSetup -eq 'y') {
        $shouldProcess = if ($PSCmdlet) {
            $PSCmdlet.ShouldProcess("WSL Basic Setup", "Execute Ensure-WSLBasics.ps1 from $EnsureWSLBasicsScriptPath")
        } else { $true }
        if ($shouldProcess) {
            Write-Host "Executing: $EnsureWSLBasicsScriptPath"
            try {
                & $EnsureWSLBasicsScriptPath -ErrorAction Stop
                Write-Host "Basic WSL2 setup script finished." -ForegroundColor Green
            } catch {
                Write-Warning ("Error during basic WSL2 setup ({0}): {1}" -f $EnsureWSLBasicsScriptPath, $_)
            }
        }
    } else {
        Write-Host "Skipping basic WSL2 setup." -ForegroundColor DarkGray
        Write-Host "If you need to set up WSL2 SSH forwarding, you can run '$EnsureWSLBasicsScriptPath' manually as Administrator."
    }
} else {
    Write-Warning "WSL Basic Setup script (Ensure-WSLBasics.ps1) not found at: $EnsureWSLBasicsScriptPath"
}

# --- Run OTHER Scheduled Task Setups ---
Write-Host "--- Processing other scheduled task setup scripts... ---" -ForegroundColor Cyan
# Recursively get a list of SetupSchedule.ps1 files from the root of the repository
$setupFiles = Get-ChildItem -Path $ScriptBase -Filter "SetupSchedule.ps1" -Recurse -ErrorAction SilentlyContinue

foreach ($file in $setupFiles) {
    # Exclude the WSL2IPUpdater's SetupSchedule.ps1 because Ensure-WSLBasics.ps1 handles it if the user opted in.
    if ($file.FullName -notlike "*Scripts\WSL2IPUpdater\SetupSchedule.ps1*") {
        Write-Host "Executing scheduled task setup: $($file.FullName)"
        try {
            & $file.FullName -ErrorAction Stop
        } catch {
            Write-Warning ("Error executing {0}: {1}" -f $file.FullName, $_)
        }
    } else {
        Write-Host "Skipping $($file.FullName) here (handled by Ensure-WSLBasics.ps1 if user chose to run WSL setup)." -ForegroundColor DarkGray
    }
}

Write-Host "--- Main Setup.ps1 script finished. ---" -ForegroundColor Green
# return # Using return is generally safer than exit in scripts that might be sourced.
