# Module for full system backup and restore
# Usage
#
# Backup Everything:
#
# Backup-All -BackupDirectory "C:\MySystemBackups"
# Restore Everything:
#
# Restore-All -BackupDirectory "C:\MySystemBackups"
# Custom Backup Options:
#
# Run only specific parts (e.g., scheduled tasks):
#
# Backup-ScheduledTasks -BackupDirectory "C:\MyBackups\Tasks"
# Restore-ScheduledTasks -BackupDirectory "C:\MyBackups\Tasks"
# BackupAndRestore module
#
#
# FullSystemBackup Module

# FullSystemBackup Module

#region Helper Functions

# Check if the script is running with admin privileges and prompt to elevate if not
function Ensure-AdminPrivileges {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "This script requires administrative privileges. Restarting as administrator..."
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File '$($MyInvocation.MyCommand.Path)'" -Verb RunAs
        exit
    }
}

# Log messages to a log file
function Log-Message {
    param (
        [string]$Message,
        [string]$LogFile
    )
    if (-not [string]::IsNullOrEmpty($LogFile)) {
         $logDir = Split-Path -Path $LogFile -Parent
         if (-not (Test-Path -Path $logDir)) {
             New-Item -Path $logDir -ItemType Directory -Force | Out-Null
         }
        Add-Content -Path $LogFile -Value "$((Get-Date).ToString()): $Message"
    }
      else {
           $defaultErrorLog = "$HOME\SystemBackups\Error.log"
           $logDir = Split-Path -Path $defaultErrorLog -Parent
           if (-not (Test-Path -Path $logDir)) {
               New-Item -Path $logDir -ItemType Directory -Force | Out-Null
            }
           Add-Content -Path $defaultErrorLog -Value "$((Get-Date).ToString()): $Message"

    }
}

# Create a timestamped backup directory for atomic operations
function Create-TimestampedBackupDirectory {
    param (
        [string]$BaseDirectory = "$HOME\SystemBackups"
    )
    $timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $tempDir = Join-Path -Path $BaseDirectory -ChildPath "TempBackup-$timestamp"
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    return $tempDir
}

# Finalize backup directory by renaming temp directory after a successful backup
function Finalize-BackupDirectory {
    param (
        [string]$TempDirectory,
        [string]$BaseDirectory = "$HOME\SystemBackups"
    )
    $finalDir = $TempDirectory -replace "TempBackup", "Backup"
    Rename-Item -Path $TempDirectory -NewName $finalDir
    return $finalDir
}

# Check if a file exists and prompt user for action
function Handle-FileExists {
    param (
        [string]$FilePath
    )
    if (Test-Path $FilePath) {
        Write-Warning "The file '$FilePath' already exists. What would you like to do?"
        Write-Host "1. Overwrite"
        Write-Host "2. Skip"
        Write-Host "3. Create a new backup file"

        do {
            $choice = Read-Host "Enter your choice (1/2/3)"
        } while ($choice -notin @("1", "2", "3"))

        switch ($choice) {
            1 { return "Overwrite" }
            2 { return "Skip" }
            3 { return "NewFile" }
            default { Write-Warning "Invalid choice. Skipping."; return "Skip" }
        }
    }
    return "Overwrite"
}

# Validate backup/restore directory
function Validate-Directory {
    param (
        [string]$DirectoryPath
    )
    if (-not (Test-Path $DirectoryPath)) {
        Write-Error "The directory '$DirectoryPath' does not exist. Operation aborted."
        exit
    }
}

# Display progress
function Show-Progress {
    param (
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete
    )
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
}

#endregion Helper Functions

# BACKUP FUNCTIONS ------------------------------------------------------

function Backup-EnvironmentVariables {
    param (
        [string]$BackupDirectory,
        [string]$LogFile = "$HOME\SystemBackups\Backup.log"
    )

    try {
        $envDir = Join-Path $BackupDirectory "Environment"
        New-Item -Path $envDir -ItemType Directory -Force | Out-Null

        # Backup all User environment variables
        $userEnvVars = [Environment]::GetEnvironmentVariables("User")
        $userEnvVarsFile = Join-Path $envDir "UserEnvironmentVariables.json"
        $userEnvVarsHash = @{}
        $count = $userEnvVars.Count
        $current = 0

        foreach ($key in $userEnvVars.Keys) {
            $current++
             Show-Progress -Activity "Backing up User Environment Variables" -Status "Processing ${key}" -PercentComplete (($current / $count) * 100)
            if ($userEnvVars[$key]) {
                $userEnvVarsHash[$key] = $userEnvVars[$key]
            }
        }
        $userEnvVarsHash | ConvertTo-Json -Depth 10 | Set-Content -Path $userEnvVarsFile
        Log-Message "User environment variables backed up to $userEnvVarsFile." $LogFile

        # Backup all System environment variables
        $systemEnvVars = [Environment]::GetEnvironmentVariables("Machine")
        $systemEnvVarsFile = Join-Path $envDir "SystemEnvironmentVariables.json"
        $systemEnvVarsHash = @{}
        $count = $systemEnvVars.Count
        $current = 0

        foreach ($key in $systemEnvVars.Keys) {
            $current++
            Show-Progress -Activity "Backing up System Environment Variables" -Status "Processing ${key}" -PercentComplete (($current / $count) * 100)
            if ($systemEnvVars[$key]) {
                $systemEnvVarsHash[$key] = $systemEnvVars[$key]
            }
        }
        $systemEnvVarsHash | ConvertTo-Json -Depth 10 | Set-Content -Path $systemEnvVarsFile
        Log-Message "System environment variables backed up to $systemEnvVarsFile." $LogFile
         Write-Output "Environment variables backed up successfully to $envDir."
    } catch {
        Log-Message "Error backing up environment variables: $_"
         Write-Error "Error backing up environment variables: $_"
    }
}

function Backup-FirewallRules {
     param (
        [string]$BackupDirectory,
        [string]$LogFile = "$HOME\SystemBackups\Backup.log"
    )

    try {
        $firewallDir = Join-Path $BackupDirectory "Firewall"
        New-Item -Path $firewallDir -ItemType Directory -Force | Out-Null

        Show-Progress -Activity "Backing up Firewall Rules" -Status "Exporting rules" -PercentComplete 50
        $firewallBackupFile = Join-Path $firewallDir "FirewallRules.wfw"
        netsh advfirewall export $firewallBackupFile | Out-Null

        Show-Progress -Activity "Backing up Firewall Rules" -Status "Completed" -PercentComplete 100
        Log-Message "Firewall rules backed up to $firewallBackupFile." $LogFile
        Write-Output "Firewall rules backed up successfully to $firewallDir."
    } catch {
        Log-Message "Error backing up firewall rules: $_"
        Write-Error "Error backing up firewall rules: $_"
    }
}

function Backup-RegistryKeys {
    param (
        [string]$BackupDirectory,
        [string]$LogFile = "$HOME\SystemBackups\Backup.log",
        [string]$RegistryKey = "HKCU"
    )

    try {
        $registryDir = Join-Path $BackupDirectory "Registry"
        New-Item -Path $registryDir -ItemType Directory -Force | Out-Null

        $targetKeys = if ($RegistryKey -eq "All") { @("HKCU", "HKLM") } else { @($RegistryKey) }

        foreach ($key in $targetKeys) {
             Show-Progress -Activity "Backing up Registry Keys" -Status "Exporting $key" -PercentComplete 50
            $backupFile = Join-Path $registryDir "${key}-Backup.reg"
            $action = Handle-FileExists -FilePath $backupFile

            if ($action -eq "Skip") {
                Log-Message "Skipped backing up $key." $LogFile
                continue
            } elseif ($action -eq "NewFile") {
                $backupFile = Join-Path $registryDir "${key}-Backup-$(Get-Date -Format 'yyyyMMddHHmmss').reg"
            }

            reg export $key $backupFile /y | Out-Null
            Log-Message "Registry key $key backed up to $backupFile." $LogFile
        }

        Show-Progress -Activity "Backing up Registry Keys" -Status "Completed" -PercentComplete 100
         Write-Output "Registry keys backed up successfully to $registryDir."
    } catch {
        Log-Message "Error backing up registry keys: $_"
        Write-Error "Error backing up registry keys: $_"
    }
}

function Backup-ScheduledTasks {
    param (
        [string]$BackupDirectory,
        [string]$LogFile = "$HOME\SystemBackups\Backup.log"
    )

    try {
        $taskDir = Join-Path $BackupDirectory "Tasks"
        New-Item -Path $taskDir -ItemType Directory -Force | Out-Null

        $tasks = Get-ScheduledTask
        $taskCount = $tasks.Count
        $currentTask = 0

        foreach ($task in $tasks) {
            $currentTask++
            Show-Progress -Activity "Backing up Scheduled Tasks" -Status "Exporting $($task.TaskName)" -PercentComplete (($currentTask / $taskCount) * 100)
            $taskName = $task.TaskName
            $sanitizedTaskName = $taskName -replace "[\\/?:<>|*]", "_"
            $taskFile = Join-Path $taskDir "$sanitizedTaskName.xml"
            Export-ScheduledTask -TaskName $taskName -Path $taskFile
        }

        Log-Message "Scheduled tasks backed up to $taskDir." $LogFile
         Write-Output "Scheduled tasks backed up successfully to $taskDir."
    } catch {
         Log-Message "Error backing up scheduled tasks: $_"
        Write-Error "Error backing up scheduled tasks: $_"
    }
}

# RESTORE FUNCTIONS ------------------------------------------------------

function Restore-EnvironmentVariables {
    param (
        [string]$BackupDirectory,
        [string]$LogFile = "$BackupDirectory\Restore.log"
    )

    try {
        $envDir = Join-Path $BackupDirectory "Environment"

        # Restore User environment variables
        $userEnvVarsFile = Join-Path $envDir "UserEnvironmentVariables.json"
        if (Test-Path $userEnvVarsFile) {
            $userEnvVars = Get-Content -Path $userEnvVarsFile | ConvertFrom-Json
            $existingUserVars = [Environment]::GetEnvironmentVariables("User")
            $existingKeys = $existingUserVars.Keys
            $count = $userEnvVars.Count
            $current = 0

            # Remove variables not in the backup
            foreach ($existingKey in $existingKeys) {
                if (-not $userEnvVars.ContainsKey($existingKey)) {
                    [Environment]::SetEnvironmentVariable($existingKey, $null, "User")
                    Log-Message "Removed redundant user variable: ${existingKey}" $LogFile
                }
            }

            # Restore or overwrite variables
            foreach ($key in $userEnvVars.Keys) {
                 $current++
                 Show-Progress -Activity "Restoring User Environment Variables" -Status "Processing ${key}" -PercentComplete (($current / $count) * 100)
                # Case-insensitive check for existing variables
                $matchingKey = $existingKeys | Where-Object { $_ -ieq $key }
                if ($matchingKey) {
                    Write-Warning "The user variable '${key}' already exists with value '${existingUserVars[$matchingKey]}'."
                    do {
                        $choice = Read-Host "Do you want to overwrite it? (yes/no)"
                    } while ($choice -notin @("yes", "no"))

                    if ($choice -eq "no") {
                        Log-Message "Skipped restoring user variable: ${key}" $LogFile
                        continue
                    }
                }
                try {
                    [Environment]::SetEnvironmentVariable($key, $userEnvVars[$key], "User")
                    Log-Message "Restored user variable: ${key}" $LogFile
                } catch {
                   Log-Message "Error restoring user variable ${key}: $_"
                     Write-Error "Error restoring user variable ${key}: $_"
                }
            }
        } else {
            Log-Message "User environment variable backup file not found. Skipping restore for User environment variables." $LogFile
             Write-Output "User environment variable backup file not found. Skipping restore for User environment variables."
        }

        # Restore System environment variables
        $systemEnvVarsFile = Join-Path $envDir "SystemEnvironmentVariables.json"
        if (Test-Path $systemEnvVarsFile) {
            $systemEnvVars = Get-Content -Path $systemEnvVarsFile | ConvertFrom-Json
            $existingSystemVars = [Environment]::GetEnvironmentVariables("Machine")
            $existingKeys = $existingSystemVars.Keys
            $count = $systemEnvVars.Count
            $current = 0

            # Remove variables not in the backup
            foreach ($existingKey in $existingKeys) {
                if (-not $systemEnvVars.ContainsKey($existingKey)) {
                    [Environment]::SetEnvironmentVariable($existingKey, $null, "Machine")
                    Log-Message "Removed redundant system variable: ${existingKey}" $LogFile
                }
            }

            # Restore or overwrite variables
            foreach ($key in $systemEnvVars.Keys) {
                $current++
                Show-Progress -Activity "Restoring System Environment Variables" -Status "Processing ${key}" -PercentComplete (($current / $count) * 100)
                # Case-insensitive check for existing variables
                $matchingKey = $existingKeys | Where-Object { $_ -ieq $key }
                if ($matchingKey) {
                     Write-Warning "The system variable '${key}' already exists with value '${existingSystemVars[$matchingKey]}'."
                    do {
                        $choice = Read-Host "Do you want to overwrite it? (yes/no)"
                    } while ($choice -notin @("yes", "no"))

                    if ($choice -eq "no") {
                        Log-Message "Skipped restoring system variable: ${key}" $LogFile
                        continue
                    }
                }
                try {
                     [Environment]::SetEnvironmentVariable($key, $systemEnvVars[$key], "Machine")
                    Log-Message "Restored system variable: ${key}" $LogFile
                } catch {
                     Log-Message "Error restoring system variable ${key}: $_"
                    Write-Error "Error restoring system variable ${key}: $_"
                }
            }
        } else {
            Log-Message "System environment variable backup file not found. Skipping restore for System environment variables." $LogFile
             Write-Output "System environment variable backup file not found. Skipping restore for System environment variables."
        }
         Write-Output "Environment variables restored successfully from $envDir."
    } catch {
        Log-Message "Error restoring environment variables: $_"
        Write-Error "Error restoring environment variables: $_"
    }
}

function Restore-FirewallRules {
    param (
        [string]$BackupDirectory,
        [string]$LogFile = "$BackupDirectory\Restore.log"
    )

    try {
        $firewallDir = Join-Path $BackupDirectory "Firewall"
        $firewallBackupFile = Join-Path $firewallDir "FirewallRules.wfw"
        if (Test-Path $firewallBackupFile) {
            Show-Progress -Activity "Restoring Firewall Rules" -Status "Importing rules" -PercentComplete 50
            netsh advfirewall import $firewallBackupFile | Out-Null
             Show-Progress -Activity "Restoring Firewall Rules" -Status "Completed" -PercentComplete 100
            Log-Message "Firewall rules restored from $firewallBackupFile." $LogFile
            Write-Output "Firewall rules restored successfully from $firewallDir."
        } else {
             Write-Output "No backup file found for firewall rules."
            Log-Message "No backup file found for firewall rules." $LogFile
        }
    } catch {
        Log-Message "Error restoring firewall rules: $_"
         Write-Error "Error restoring firewall rules: $_"
    }
}

function Restore-RegistryKeys {
    param (
         [string]$BackupDirectory,
         [string]$LogFile = "$BackupDirectory\Restore.log"
    )

    try {
        $registryDir = Join-Path $BackupDirectory "Registry"
        $registryBackupFile = Join-Path $registryDir "RegistryBackup.reg"
        if (Test-Path $registryBackupFile) {
           Show-Progress -Activity "Restoring Registry Keys" -Status "Importing keys" -PercentComplete 50
            reg import $registryBackupFile | Out-Null
             Show-Progress -Activity "Restoring Registry Keys" -Status "Completed" -PercentComplete 100
            Log-Message "Registry keys restored from $registryBackupFile." $LogFile
             Write-Output "Registry keys restored successfully from $registryDir."
        } else {
             Write-Output "No backup file found for registry keys."
            Log-Message "No backup file found for registry keys." $LogFile
        }
    } catch {
        Log-Message "Error restoring registry keys: $_"
        Write-Error "Error restoring registry keys: $_"
    }
}

function Restore-ScheduledTasks {
    param (
        [string]$BackupDirectory,
        [string]$LogFile = "$BackupDirectory\Restore.log"
    )

    try {
        $taskDir = Join-Path $BackupDirectory "Tasks"
         $taskFiles = Get-ChildItem -Path $taskDir -Filter *.xml
         $taskCount = $taskFiles.Count
         $currentTask = 0

         foreach ($taskFile in $taskFiles) {
             $currentTask++
            Show-Progress -Activity "Restoring Scheduled Tasks" -Status "Restoring $($taskFile.BaseName)" -PercentComplete (($currentTask / $taskCount) * 100)
            schtasks /create /tn $taskFile.BaseName /xml $taskFile.FullName /f | Out-Null
        }

        Log-Message "Scheduled tasks restored from $taskDir." $LogFile
        Write-Output "Scheduled tasks restored successfully from $taskDir."
    } catch {
         Log-Message "Error restoring scheduled tasks: $_"
        Write-Error "Error restoring scheduled tasks: $_"
    }
}


# CENTRALIZED FUNCTIONS --------------------------------------------------

function Backup-All {
    param (
        [string]$BaseDirectory = "$HOME\SystemBackups",
        [string]$LogFile = "$HOME\SystemBackups\Backup.log",
         [string]$RegistryKey = "All"
    )

    Ensure-AdminPrivileges

    $tempDir = Create-TimestampedBackupDirectory -BaseDirectory $BaseDirectory

     Log-Message "Starting full system backup..." $LogFile

    try {
         Backup-EnvironmentVariables -BackupDirectory $tempDir -LogFile $LogFile
        Backup-FirewallRules -BackupDirectory $tempDir -LogFile $LogFile
        Backup-RegistryKeys -BackupDirectory $tempDir -LogFile $LogFile -RegistryKey $RegistryKey
        Backup-ScheduledTasks -BackupDirectory $tempDir -LogFile $LogFile
         $finalDir = Finalize-BackupDirectory -TempDirectory $tempDir -BaseDirectory $BaseDirectory
        Log-Message "Full system backup completed successfully at $finalDir." $LogFile
         Write-Output "Full system backup completed successfully. Logs available at $finalDir\Backup.log."
    } catch {
        Log-Message "Error during system backup: $_"
         Write-Error "Error during system backup: $_"
    }
}

function Restore-All {
    param (
        [string]$BackupDirectory,
        [string]$LogFile = "$BackupDirectory\Restore.log"
    )

    Validate-Directory -DirectoryPath $BackupDirectory
    Ensure-AdminPrivileges

    Log-Message "Starting full system restore..." $LogFile

    try {
        Restore-EnvironmentVariables -BackupDirectory $BackupDirectory -LogFile $LogFile
        Restore-FirewallRules -BackupDirectory $BackupDirectory -LogFile $LogFile
        Restore-RegistryKeys -BackupDirectory $BackupDirectory -LogFile $LogFile
        Restore-ScheduledTasks -BackupDirectory $BackupDirectory -LogFile $LogFile
        Log-Message "Full system restore completed successfully." $LogFile
         Write-Output "Full system restore completed successfully. Logs available at $BackupDirectory\Restore.log."
    } catch {
        Log-Message "Error during system restore: $_"
         Write-Error "Error during system restore: $_"
    }
}

# Exported functions
Export-ModuleMember -Function Backup-All, Restore-All, Backup-EnvironmentVariables, Restore-EnvironmentVariables, Backup-FirewallRules, Restore-FirewallRules, Backup-RegistryKeys, Restore-RegistryKeys, Backup-ScheduledTasks, Restore-ScheduledTasks

# Dot source the helper functions to make them available within the module scope
. $PSScriptRoot\BackupAndRestore.psm1
