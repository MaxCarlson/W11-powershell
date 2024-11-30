# Define the task name and description
$TaskName = "StartSSHAgent"
$TaskDescription = "Ensures the OpenSSH Authentication Agent is started at boot."

# Check if the task already exists
$TaskExists = Get-ScheduledTask | Where-Object { $_.TaskName -like $TaskName }

if ($TaskExists) {
    Write-Host "Task '$TaskName' already exists."
} else {
    # Task doesn't exist, create it
    Write-Host "Creating task '$TaskName'..."

    # Command to start SSH agent
    $Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-Command "Start-Service ssh-agent"'

    # Trigger at system startup
    $Trigger = New-ScheduledTaskTrigger -AtStartup

    # Register the task
    Register-ScheduledTask -TaskName $TaskName -Description $TaskDescription -Action $Action -Trigger $Trigger -RunLevel Highest -User "SYSTEM"

    Write-Host "Task '$TaskName' created successfully."
}
