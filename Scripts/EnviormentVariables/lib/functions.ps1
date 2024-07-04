# lib/functions.ps1

# Function to check if the file is runnable
function Is-RunnableFile {
    param (
        [string]$FilePath
    )
    $runnableExtensions = @(".exe", ".bat", ".cmd", ".ps1", ".sh", ".py", ".rb", ".jar")
    $extension = [System.IO.Path]::GetExtension($FilePath)
    return $runnableExtensions -contains $extension
}

# Function to log the current PATH
function Log-CurrentPath {
    param (
        [string]$CurrentPath,
        [string]$Target
    )
    $logFilePath = "path_log.txt"
    $logEntry = "$(Get-Date) - $Target PATH: $CurrentPath`n"
    try {
        Add-Content -Path $logFilePath -Value $logEntry
    } catch {
        Write-Error "Failed to log the current PATH: $_"
    }
}

# Function to rollback the last PATH modification
function Rollback-Path {
    param (
        [string]$Target
    )
    $logFilePath = "path_log.txt"
    if (Test-Path -Path $logFilePath) {
        try {
            $logEntries = Get-Content -Path $logFilePath
            $lastEntryIndex = ($logEntries | Select-String -Pattern "$Target PATH:").Count - 1
            if ($lastEntryIndex -ge 0) {
                $lastPath = ($logEntries[$lastEntryIndex] -split "$Target PATH:")[1].Trim()
                [System.Environment]::SetEnvironmentVariable("PATH", $lastPath, $Target)
                Write-Output "PATH rolled back successfully. New PATH: $lastPath"
            } else {
                Write-Output "No previous $Target PATH found in the log."
            }
        } catch {
            Write-Error "Failed to read the log file or parse entries: $_"
        }
    } else {
        Write-Output "No log file found. Cannot perform rollback."
    }
}

# Function to check for overlapping executables
function Check-OverlappingExecutables {
    param (
        [string]$NewPath,
        [array]$CurrentPathDirs
    )
    $newPathExecutables = Get-ChildItem -Path $NewPath -Filter *.exe
    $overlappingExecutables = @()

    foreach ($exe in $newPathExecutables) {
        foreach ($dir in $CurrentPathDirs) {
            if (Test-Path -Path "$dir\$($exe.Name)") {
                $overlappingExecutables += $exe.Name
            }
        }
    }

    return @{
        NewPathExecutables = $newPathExecutables
        OverlappingExecutables = $overlappingExecutables
    }
}
