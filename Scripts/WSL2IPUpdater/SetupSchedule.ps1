param (
    [bool]$verbose = $false,
    [string]$taskName = "updateWSL2SSHServerIP",
    [string]$description = "Ensure the WSL2 Server IP Remains accurate"
)

# Get the path of the current script
$scriptDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Find the name of the script
$scriptFile = Get-ChildItem -Path . -Filter "*.ps1" |
Where-Object { $_.Name -ne "SetupSchedule.ps1" } |
Select-Object -First 1

# Concatenate the current directory with the name of the script to be scheduled
$scriptToRun = Join-Path -Path $scriptDirectory -ChildPath $scriptFile.Name

##################################################################################
##################################################################################
##################################################################################
######### Unique to Script
##################################################################################
##################################################################################
##################################################################################

# Define the arguments you want to pass to the script
$scriptArguments = ''

# Define the action to be taken
$action = New-ScheduledTaskAction -Execute 'pwsh.exe' `
    -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$scriptToRun`" $scriptArguments"

# Simplified trigger setup: Trigger the task daily
$trigger = New-ScheduledTaskTrigger -Daily -At 7am # Change the time as needed

# Define the settings for the task to prevent multiple instances
$settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew

# Register the task with the action, trigger, and settings
Register-ScheduledTask -Action $action -Trigger $trigger -Settings $settings `
    -TaskName $taskName -Description $description
