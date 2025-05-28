param (
    [string]$taskName = "ManageWSL2SSHForwarding", # You can keep this task name or change it
    [string]$description = "Periodically updates WSL2 IP for SSH port forwarding and ensures firewall rule, using UpdateWSL2SSHServerIP.ps1."
)

# Get the path of the current script
$scriptDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Find the name of the main script to be scheduled (e.g., UpdateWSL2SSHServerIP.ps1)
$scriptToRunFile = Get-ChildItem -Path $scriptDirectory -Filter "*.ps1" |
    Where-Object { $_.Name -ne "SetupSchedule.ps1" } | # Exclude self
    Select-Object -First 1

if (-not $scriptToRunFile) {
    Write-Error "Could not find the main script (e.g., UpdateWSL2SSHServerIP.ps1) to schedule in directory: $scriptDirectory"
    exit 1
}

$scriptToRunPath = $scriptToRunFile.FullName
Write-Host "Script to schedule: $scriptToRunPath"

# Define the arguments for the script (none needed for the enhanced UpdateWSL2SSHServerIP.ps1's default behavior)
$scriptArguments = ''

# Define the action to be taken
$action = New-ScheduledTaskAction -Execute 'pwsh.exe' `
    -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptToRunPath`" $scriptArguments"

# Trigger the task daily at 7 AM. Adjust as needed.
$trigger = New-ScheduledTaskTrigger -Daily -At 7am

# Define the settings for the task
$settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew `
    -DisallowDemandStart:$false `
    -StartWhenAvailable `
    -WakeToRun:$false `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

# Define the principal to run the task with highest privileges
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Check if the task already exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Warning "Task '$taskName' already exists. Unregistering and recreating."
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Register the task
try {
    Register-ScheduledTask -TaskName $taskName `
        -Description $description `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -ErrorAction Stop
    Write-Host "Scheduled task '$taskName' successfully created/updated."
    Write-Host "It will run '$scriptToRunPath' daily at 7 AM with highest privileges."
}
catch {
    Write-Error "Failed to register scheduled task '$taskName'. Error: $_"
    Write-Error "Please ensure you are running this script as an Administrator."
}
