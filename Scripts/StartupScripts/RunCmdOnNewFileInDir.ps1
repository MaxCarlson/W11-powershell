# Usage examples:
# .\RunCmdOnNewFileInDir.ps1 -sourceDir "C:\WatchDirectory" -command "PowerShell" -arguments "if ((Get-Item '<file>').Extension -eq '.mp4') { Move-Item -Path '<file>' -Destination 'D:\Dest' }"

# Replaces all instance of <file> in the arguments with the actual file path
param(
    [string]$sourceDir,   # Specify the source directory
    [string]$command,     # Command to execute on new files
    [string]$arguments    # Arguments for the command, including the <file> placeholder
)

# Check if the source directory exists
if (-not (Test-Path -Path $sourceDir)) {
    Write-Error "Source directory does not exist."
    return
}

# Create a file system watcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $sourceDir
$watcher.Filter = "*.*"  # Watch for all files
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

# Define the event action using the provided command
$onCreated = Register-ObjectEvent -InputObject $watcher -EventName Created -Action {
    param($source, $e, $cmd, $args)

    # Full path of the newly created file
    $newFilePath = Join-Path -Path $source -ChildPath $e.Name

    # Log detection
    Write-Host "Detected new file: $newFilePath"

    # Print the source and event object for debugging
    Write-Host "Source: $source"
    Write-Host "Event Object Name: $($e.Name)"
    Write-Host "Event Object Full Path: $($e.FullPath)"

    # Replace <file> in the arguments with the actual file path
    $execCommand = $args.Replace("<file>", "`"$newFilePath`"")

    # Print the command to be executed for debugging
    Write-Host "Command to execute: $cmd $execCommand"

    # Execute the command and catch any errors
    try {
        Invoke-Expression "$cmd $execCommand"
        Write-Host "Command successfully executed for '$newFilePath'"
    } catch {
        Write-Error "Error executing command: $_"
    }
} -MessageData ($command, $arguments)

# Write a message to the console
Write-Host "Watching for new files in '$sourceDir'... Press Ctrl+C to exit."

# Keep the script running until manually stopped
Wait-Event
