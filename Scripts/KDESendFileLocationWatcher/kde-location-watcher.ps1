# Define the temporary directory where the files will be downloaded
$watchDirectory = "$HOME\kde-downloads\"

# Function to get the directory from a config file
function Get-ConfigDirectory {
    $configPath = "config.txt"
    if (Test-Path $configPath) {
        $configContent = Get-Content $configPath
        $homeDirectory = [Environment]::GetFolderPath('UserProfile')
        $expandedConfigContent = $configContent.Replace('$HOME', $homeDirectory)
        return $expandedConfigContent
    }
    else {
        Write-Host "Config file not found. Exiting."
        exit 0
    }
}

# Setup the FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchDirectory
$watcher.IncludeSubdirectories = $true

$action = {
    $filePath = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    Write-Host "File $filePath was $changeType at $(Get-Date)"
    
    # If a file was created, move it to the directory specified in the config file
    if ($changeType -eq "Created" -and (Test-Path $filePath)) {
        # Wait until the file is no longer being written to or used by another process
        while ((Get-FileLockStatus -Path $filePath) -eq $true) {
            Start-Sleep -Seconds 1
        }

        $destinationDirectory = Get-ConfigDirectory
        Write-Host "Destination directory: $destinationDirectory"
        $destinationPath = Join-Path -Path $destinationDirectory -ChildPath (Split-Path -Path $filePath -Leaf)
        Write-Host "Moving $filePath to $destinationPath"
        
        try {
            Move-Item -Path $filePath -Destination $destinationPath -ErrorAction Stop
        }
        catch {
            Write-Host "Failed to move file: $_"
        }
    }
}

function Get-FileLockStatus {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    try {
        [IO.File]::OpenWrite($Path).close()
        return $false
    }
    catch {
        return $true
    }
}

# Keep the script running until it is manually stopped
while ($true) {
    $watcher.EnableRaisingEvents = $true
    $eventSubscription = Register-ObjectEvent $watcher "Created" -Action $action
    Start-Sleep -Seconds 5
    Unregister-Event -SourceIdentifier $eventSubscription.Name
}