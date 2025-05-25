# Setup.ps1 - Main Orchestrator

# --- Initial Setup Scripts ---
Write-Host "Running initial setup scripts..."
# Assuming these are idempotent and located correctly relative to this script
# (e.g., in ./Scripts/SetupScripts/ or a known path)
$ScriptBase = Split-Path -Parent $MyInvocation.MyCommand.Definition
.\Scripts\SetupScripts\StartSSHAgent.ps1
.\Scripts\SetupScripts\ProgramBackup.ps1 -Setup -BackupFrequency Daily -UpdateFrequency Daily

# --- Setup Executables in bin/ ---
Write-Host "Setting up executables..."
# Ensure $PWSH_REPO is defined if SetupExecutables.ps1 relies on it,
# or pass $ScriptBase if it expects the repository root.
# For now, assuming it can find its way or is self-contained.
# If $PWSH_REPO is meant to be the root of this git repo:
$env:PWSH_REPO = $ScriptBase # Or however you define it globally
& (Join-Path $env:PWSH_REPO "Setup\SetupExecutables.ps1")

# --- Ensure Package Managers and Core Tools ---
Write-Host "Ensuring package managers are available..."
. (Join-Path $ScriptBase "Setup\Ensure-PackageManagers.ps1")

# --- Package-list management & installation ---
Write-Host "Installing packages from lists..."
. (Join-Path $ScriptBase "Setup\Install-Packages.ps1")

# --- Update Windows PATH for newly installed tools (e.g., Cygwin) ---
Write-Host "Updating environment paths..."
. (Join-Path $ScriptBase "Setup\Update-EnvironmentPaths.ps1")

# --- Run Scheduled Task Setups ---
Write-Host "Running scheduled task setup scripts..."
# Recursively get a list of SetupSchedule.ps1 files
# $PSScriptRoot should be the directory of THIS Setup.ps1 script
$setupFiles = Get-ChildItem -Path $PSScriptRoot -Filter "SetupSchedule.ps1" -Recurse -ErrorAction SilentlyContinue

foreach ($file in $setupFiles) {
    # Exclude WSL setup from default run
    if ($file.FullName -notlike "*WSL*SetupSchedule*") { # Be more specific if needed
        Write-Host "Executing: $($file.FullName)"
        try {
            & $file.FullName
        } catch {
            Write-Warning "Error executing $($file.FullName): $_"
        }
    } else {
        Write-Host "Skipping WSL-related schedule setup: $($file.FullName)"
    }
}

# --- WSL Setup (Manual / Optional) ---
# Write-Host "WSL Setup is not run by default. To set up WSL, run the specific WSL setup script manually."
# Example: . (Join-Path $ScriptBase "Setup\WSL2-Setup.ps1") # Or WSL2-Setup2.ps1

Write-Host "Main Setup.ps1 script finished."
return
