# File: Setup\Ensure-WSLBasics.ps1
# Description: Ensures basic WSL2 setup, Ubuntu installation, OpenSSH server in Ubuntu,
#              and configures the port forwarding and its scheduled task.

[CmdletBinding(SupportsShouldProcess = $true)]
param()

function Assert-Administrator {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        Write-Error "Administrator privileges are required. Please re-run this script or the parent Setup.ps1 as an Administrator."
        exit 1
    }
}

function Invoke-WslCommand {
    param(
        [string]$Distribution = "Ubuntu",
        [string]$Command,
        [switch]$AsRoot = $false,
        [string]$ErrorMessage
    )
    Write-Host "Executing in WSL (${Distribution}): ${Command}" -ForegroundColor Gray
    $fullCommand = if ($AsRoot) { "sudo --preserve-env=PATH env DEBIAN_FRONTEND=noninteractive $Command" } else { "env DEBIAN_FRONTEND=noninteractive $Command" }

    # Ensure the distribution is running before executing a command
    $distroStatus = wsl -l -v | Where-Object { $_ -match $Distribution -and $_ -match "Running" }
    if (-not $distroStatus) {
        Write-Host "Starting WSL distribution '$Distribution'..." -ForegroundColor Yellow
        wsl -d $Distribution -e exit # Simple command to start it if it's not running
        Start-Sleep -Seconds 5 # Give it a moment to start
    }

    $output = wsl -d $Distribution -- $fullCommand 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $errMsgText = if ($ErrorMessage) { $ErrorMessage } else { "WSL command failed: '${Command}'" }
        Write-Warning "${errMsgText} (Exit Code: ${exitCode}). Output: ${output}" # Changed to Warning
        return $false # Indicate failure
    } else {
        Write-Host "WSL Command Output for '${Command}': ${output}" -ForegroundColor DarkGray
    }
    return $true # Indicate success
}

Assert-Administrator

$ErrorActionPreference = 'Continue' # Allow script to continue on non-terminating errors

Write-Host "--- Starting Basic WSL2 and SSH Prerequisite Check ---" -ForegroundColor Cyan

# Step 1: Ensure WSL feature is enabled
Write-Host "Checking WSL Windows Feature..."
$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
if ($wslFeature -and $wslFeature.State -ne 'Enabled') {
    if ($PSCmdlet.ShouldProcess("Windows Feature: Microsoft-Windows-Subsystem-Linux", "Enable")) {
        Write-Host "Enabling Windows Subsystem for Linux feature..."
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -All | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "WSL feature enabled. A reboot might be required if it was newly installed." -ForegroundColor Green
        } else {
            Write-Warning "Failed to enable WSL feature."
        }
    }
} elseif ($wslFeature) {
    Write-Host "WSL feature is already enabled." -ForegroundColor Green
} else {
    Write-Warning "Could not determine WSL feature status."
}

# Step 2: Ensure VirtualMachinePlatform feature is enabled
Write-Host "Checking Virtual Machine Platform Windows Feature..."
$vmPlatformFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
if ($vmPlatformFeature -and $vmPlatformFeature.State -ne 'Enabled') {
    if ($PSCmdlet.ShouldProcess("Windows Feature: VirtualMachinePlatform", "Enable")) {
        Write-Host "Enabling Virtual Machine Platform feature..."
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -All | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Virtual Machine Platform feature enabled. A reboot might be required if it was newly installed." -ForegroundColor Green
        } else {
            Write-Warning "Failed to enable Virtual Machine Platform feature."
        }
    }
} elseif ($vmPlatformFeature) {
    Write-Host "Virtual Machine Platform feature is already enabled." -ForegroundColor Green
} else {
    Write-Warning "Could not determine Virtual Machine Platform feature status."
}

# Step 3: Check for WSL and try to set default to version 2
Write-Host "Checking WSL installation and setting default version to 2..."
wsl -l -q > $null # Test if wsl command works
if ($LASTEXITCODE -eq 0) {
    if ($PSCmdlet.ShouldProcess("WSL Configuration", "Set default version to 2 (if not already)")) {
        wsl --set-default-version 2
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Could not set WSL default version to 2. This might be okay if it's already set or WSL needs an update/restart."
        } else {
            Write-Host "WSL default version set to 2." -ForegroundColor Green
        }
    }
} else {
    Write-Warning "WSL command-line tool does not seem to be working. WSL might not be installed or requires a reboot/update (`wsl --update`)."
}

# Step 4: Ensure Ubuntu is installed
$ubuntuDistroName = "Ubuntu" # Or your preferred default like "Ubuntu-22.04"
Write-Host "Checking if '$ubuntuDistroName' WSL distribution is installed..."
$installedDistros = wsl.exe -l --quiet
if (-not ($installedDistros -match $ubuntuDistroName)) {
    if ($PSCmdlet.ShouldProcess("WSL Distribution: $ubuntuDistroName", "Install")) {
        Write-Host "'$ubuntuDistroName' distro not found; attempting to install..."
        wsl --install -d $ubuntuDistroName
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to install '$ubuntuDistroName'. Please try 'wsl --update' and then install manually if needed."
        } else {
            Write-Host "'$ubuntuDistroName' installed successfully. You may need to complete initial user setup in the Ubuntu terminal." -ForegroundColor Green
        }
    }
} else {
    Write-Host "'$ubuntuDistroName' is already installed." -ForegroundColor Green
}

# Step 5: Ensure openssh-server is installed in Ubuntu (idempotent)
Write-Host "Ensuring openssh-server is installed in '$ubuntuDistroName' (will attempt update first)..."
if ($PSCmdlet.ShouldProcess("'$ubuntuDistroName' packages", "Update and Install openssh-server")) {
    Invoke-WslCommand -Distribution $ubuntuDistroName -Command "apt-get update -y" -AsRoot -ErrorMessage "Failed to update package lists in $ubuntuDistroName."
    Invoke-WslCommand -Distribution $ubuntuDistroName -Command "apt-get install -y openssh-server" -AsRoot -ErrorMessage "Failed to install openssh-server in $ubuntuDistroName."
    # We won't configure sshd_config or wsl.conf here to keep it simple and less intrusive.
    # The user can manually ensure sshd is running via systemd or init.d if needed.
    # For systemd to work reliably, wsl.conf needs `systemd=true` and WSL usually needs a restart.
}

# Determine the root of the W11-powershell repository
$RepoRoot = $PSScriptRoot # Assuming this script (Ensure-WSLBasics.ps1) is in W11-powershell\Setup
if ($PSScriptRoot -like "*\Setup") {
    $RepoRoot = Split-Path -Path $PSScriptRoot -Parent
}
Write-Host "Repository Root identified as: $RepoRoot" -ForegroundColor DarkGray

# Step 6: Run your UpdateWSL2SSHServerIP.ps1 script
# This script should handle getting the WSL IP, setting up port proxy, and firewall.
$UpdateIpScriptPath = Join-Path -Path $RepoRoot -ChildPath "Scripts\WSL2IPUpdater\UpdateWSL2SSHServerIP.ps1"
if (Test-Path $UpdateIpScriptPath) {
    Write-Host "Executing WSL IP and Port Forwarding update script: $UpdateIpScriptPath" -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess($UpdateIpScriptPath, "Execute to update WSL2 SSH forwarding")) {
        try {
            & $UpdateIpScriptPath
            Write-Host "WSL IP and Port Forwarding update script executed." -ForegroundColor Green
        } catch {
            Write-Warning ("Error executing {0}: {1}" -f $UpdateIpScriptPath, $_)
        }
    }
} else {
    Write-Warning "WSL IP Update script not found at: $UpdateIpScriptPath"
}

# Step 7: Run the SetupSchedule.ps1 for the WSL2IPUpdater
# This script will schedule the UpdateWSL2SSHServerIP.ps1 to run regularly.
$ScheduleSetupScriptPath = Join-Path -Path $RepoRoot -ChildPath "Scripts\WSL2IPUpdater\SetupSchedule.ps1"
if (Test-Path $ScheduleSetupScriptPath) {
    Write-Host "Executing WSL IP Updater scheduling script: $ScheduleSetupScriptPath" -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess($ScheduleSetupScriptPath, "Execute to schedule WSL2 SSH forwarding updates")) {
        try {
            & $ScheduleSetupScriptPath
            Write-Host "WSL IP Updater scheduling script executed." -ForegroundColor Green
        } catch {
            Write-Warning ("Error executing {0}: {1}" -f $ScheduleSetupScriptPath, $_)
        }
    }
} else {
    Write-Warning "WSL IP Update scheduling script not found at: $ScheduleSetupScriptPath"
}

Write-Host "--- Basic WSL2 and SSH Prerequisite Check Finished ---" -ForegroundColor Cyan
Write-Host "Please ensure your WSL distribution ($ubuntuDistroName) has the SSH server (sshd) correctly configured and running."
Write-Host "You might need to manually enable systemd in /etc/wsl.conf and restart WSL ('wsl --shutdown') for 'sudo systemctl start ssh' to work reliably."
Write-Host "To connect: ssh your_wsl_username@your_windows_ip -p <configured_port_in_UpdateWSL2SSHServerIP.ps1>"

$ErrorActionPreference = 'Stop' # Reset to default or preferred
