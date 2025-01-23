<#
.SYNOPSIS
A script to periodically back up and update the list of installed programs from winget, choco, scoop, and cargo.

.DESCRIPTION
This script performs the following tasks:
1. Backups the list of programs installed via winget, choco, scoop, and cargo.
2. Updates all installed packages for these package managers without user input.
3. Provides a `-Setup` flag to schedule the script to run periodically for backups and updates.
4. Allows customization of backup and update frequencies and times.

.PARAMETER Setup
Configures a scheduled task to run the script periodically with specified frequencies and times.

.PARAMETER BackupFrequency
Specifies the frequency for backups. Options: Daily, Weekly, Monthly. Default: Daily.

.PARAMETER UpdateFrequency
Specifies the frequency for updates. Options: Daily, Weekly, Monthly. Default: Weekly.

.PARAMETER BackupTime
Specifies the time of day for backups (e.g., 02:00AM). Default: 02:00AM.

.PARAMETER UpdateTime
Specifies the time of day for updates (e.g., 03:00AM). Default: 03:00AM.
#>

param (
    [switch]$Setup,
    [ValidateSet("Daily", "Weekly", "Monthly")]
    [string]$BackupFrequency = "Daily",
    [ValidateSet("Daily", "Weekly", "Monthly")]
    [string]$UpdateFrequency = "Weekly",
    [string]$BackupTime = "02:00AM",
    [string]$UpdateTime = "03:00AM"
)

# Define paths for backups and logs
$BackupDir = "${env:USERPROFILE}\Backups\ProgramBackups"
$LogFile = "${BackupDir}\script-errors.log"
$WingetBackup = "${BackupDir}\winget-installed.txt"
$ChocoBackup = "${BackupDir}\choco-installed.txt"
$ScoopBackup = "${BackupDir}\scoop-installed.txt"
$CargoBackup = "${BackupDir}\cargo-installed.txt"

# Ensure backup directory exists
try {
    if (-not (Test-Path -Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }
} catch {
    Write-Error "Failed to create or access the backup directory: $_"
    Add-Content $LogFile "[$(Get-Date)] Failed to create or access the backup directory: $_"
    exit 1
}

# Function to check for existing tasks
function Check-ExistingTasks {
    param (
        [string]$TaskName
    )
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Write-Error "The task '$TaskName' already exists. Setup aborted. Please delete the existing task from Task Scheduler if reconfiguration is needed."
        exit 1
    }
}

# Function to update winget, choco, scoop, and cargo
function Update-PackageManagers {
    try {
        Write-Output "Updating winget packages..."
        winget upgrade --all --accept-source-agreements --accept-package-agreements
    } catch {
        Write-Error "Error updating winget packages: $_"
        Add-Content $LogFile "[$(Get-Date)] Error updating winget packages: $_"
    }

    try {
        Write-Output "Updating Chocolatey packages..."
        choco upgrade all -y
    } catch {
        Write-Error "Error updating Chocolatey packages: $_"
        Add-Content $LogFile "[$(Get-Date)] Error updating Chocolatey packages: $_"
    }

    try {
        Write-Output "Updating Scoop packages..."
        scoop update *
    } catch {
        Write-Error "Error updating Scoop packages: $_"
        Add-Content $LogFile "[$(Get-Date)] Error updating Scoop packages: $_"
    }

    try {
        Write-Output "Updating Cargo packages..."
        cargo install-update -a
    } catch {
        Write-Error "Error updating Cargo packages: $_"
        Add-Content $LogFile "[$(Get-Date)] Error updating Cargo packages: $_"
    }
}

# Function to backup installed programs
function Backup-InstalledPrograms {
    try {
        Write-Output "Backing up winget packages to $WingetBackup..."
        winget list > "${WingetBackup}"
    } catch {
        Write-Error "Error backing up winget packages: $_"
        Add-Content $LogFile "[$(Get-Date)] Error backing up winget packages: $_"
    }

    try {
        Write-Output "Backing up Chocolatey packages to $ChocoBackup..."
        choco list > "${ChocoBackup}" 2>&1
    } catch {
        Write-Error "Error backing up Chocolatey packages: $_"
        Add-Content $LogFile "[$(Get-Date)] Error backing up Chocolatey packages: $_"
    }

    try {
        Write-Output "Backing up Scoop packages to $ScoopBackup..."
        scoop list | Out-String | Set-Content "${ScoopBackup}"
    } catch {
        Write-Error "Error backing up Scoop packages: $_"
        Add-Content $LogFile "[$(Get-Date)] Error backing up Scoop packages: $_"
    }

    try {
        Write-Output "Backing up Cargo packages to $CargoBackup..."
        cargo install --list | Out-String | Set-Content "${CargoBackup}"
    } catch {
        Write-Error "Error backing up Cargo packages: $_"
        Add-Content $LogFile "[$(Get-Date)] Error backing up Cargo packages: $_"
    }
}

# Function to set up scheduled tasks
function Setup-ScheduledTask {
    try {
        # Check if tasks already exist
        Check-ExistingTasks -TaskName "BackupInstalledPrograms"
        Check-ExistingTasks -TaskName "UpdateInstalledPrograms"

        Write-Output "Setting up scheduled tasks for periodic updates and backups..."

        # Define actions
        $BackupAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$PSCommandPath`" -Backup"
        $UpdateAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$PSCommandPath`" -Update"

        # Define triggers for backups
        switch ($BackupFrequency) {
            "Daily" { $BackupTrigger = New-ScheduledTaskTrigger -Daily -At (Get-Date $BackupTime) }
            "Weekly" { $BackupTrigger = New-ScheduledTaskTrigger -Weekly -At (Get-Date $BackupTime) }
            "Monthly" { $BackupTrigger = New-ScheduledTaskTrigger -Monthly -At (Get-Date $BackupTime) }
        }

        # Define triggers for updates
        switch ($UpdateFrequency) {
            "Daily" { $UpdateTrigger = New-ScheduledTaskTrigger -Daily -At (Get-Date $UpdateTime) }
            "Weekly" { $UpdateTrigger = New-ScheduledTaskTrigger -Weekly -At (Get-Date $UpdateTime) }
            "Monthly" { $UpdateTrigger = New-ScheduledTaskTrigger -Monthly -At (Get-Date $UpdateTime) }
        }

        # Define principal (run with highest privileges)
        $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount

        # Register backup task
        Register-ScheduledTask -TaskName "BackupInstalledPrograms" -Action $BackupAction -Trigger $BackupTrigger -Principal $Principal -Force

        # Register update task
        Register-ScheduledTask -TaskName "UpdateInstalledPrograms" -Action $UpdateAction -Trigger $UpdateTrigger -Principal $Principal -Force

        Write-Output "Scheduled tasks created successfully."
    } catch {
        Write-Error "Error setting up scheduled tasks: $_"
        Add-Content $LogFile "[$(Get-Date)] Error setting up scheduled tasks: $_"
        exit 1
    }
}

# Main logic
try {
    if ($Setup) {
        Setup-ScheduledTask
        Write-Output "Setup complete. Scheduled tasks have been configured."
    } elseif ($Backup) {
        Backup-InstalledPrograms
        Write-Output "Backup complete."
    } elseif ($Update) {
        Update-PackageManagers
        Write-Output "Update complete."
    } else {
        Update-PackageManagers
        Backup-InstalledPrograms
        Write-Output "Backup and update complete."
    }
} catch {
    Write-Error "Unexpected error: $_"
    Add-Content $LogFile "[$(Get-Date)] Unexpected error: $_"
    exit 1
}
