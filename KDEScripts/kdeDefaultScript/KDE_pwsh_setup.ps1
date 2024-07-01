param (
    [string]$command = "echo Running command via KDE Connect..."
)

# Open a new PowerShell terminal and run the command
Start-Process pwsh -ArgumentList "-NoExit", "-Command", $command
