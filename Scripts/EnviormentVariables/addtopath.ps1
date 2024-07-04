param (
    [Parameter(Mandatory = $false, HelpMessage = "Specify the path to the executable or runnable file to add to PATH")]
    [string]$ExecutablePath,

    [Parameter(Mandatory = $false, HelpMessage = "Add to user PATH instead of system PATH")]
    [switch]$User,

    [Parameter(Mandatory = $false, HelpMessage = "Rollback the last PATH modification")]
    [switch]$Rollback
)

# Define a function to check if the file is runnable
function Is-RunnableFile {
    param (
        [string]$FilePath
    )
    $runnableExtensions = @(".exe", ".bat", ".cmd", ".ps1", ".sh", ".py", ".rb", ".jar")
    $extension = [System.IO.Path]::GetExtension($FilePath)
    return $runnableExtensions -contains $extension
}

# Define a function to log the current PATH
function Log-CurrentPath {
    param (
        [string]$CurrentPath,
        [string]$Target
    )
    $logFilePath = "path_log.txt"
    $logEntry = "$(Get-Date) - $Target PATH: $CurrentPath`n"
    Add-Content -Path $logFilePath -Value $logEntry
}

# Define a function to rollback the last PATH modification
function Rollback-Path {
    param (
        [string]$Target
    )
    $logFilePath = "path_log.txt"
    if (Test-Path -Path $logFilePath) {
        $logEntries = Get-Content -Path $logFilePath
        $lastEntryIndex = ($logEntries | Select-String -Pattern "$Target PATH:").Count - 1
        if ($lastEntryIndex -ge 0) {
            $lastPath = ($logEntries[$lastEntryIndex] -split "$Target PATH:")[1].Trim()
            [System.Environment]::SetEnvironmentVariable("PATH", $lastPath, $Target)
            Write-Output "PATH rolled back successfully. New PATH: $lastPath"
        }
        else {
            Write-Output "No previous $Target PATH found in the log."
        }
    }
    else {
        Write-Output "No log file found. Cannot perform rollback."
    }
}

# Determine the target for the PATH update
$pathTarget = [System.EnvironmentVariableTarget]::Machine
if ($User.IsPresent) {
    $pathTarget = [System.EnvironmentVariableTarget]::User
}

# Rollback if the -r or --rollback switch is specified
if ($Rollback.IsPresent) {
    Rollback-Path -Target $pathTarget
    exit
}

# Check if the executable path is provided
if (-not $ExecutablePath) {
    Write-Output "Please specify the path to the executable or runnable file to add to PATH."
    exit
}

# Check if the executable path exists and is a file
if (Test-Path -Path $ExecutablePath -PathType Leaf) {
    if (-not (Is-RunnableFile -FilePath $ExecutablePath)) {
        Write-Output "The specified file is not a recognized runnable file: $ExecutablePath"
        exit
    }

    # Get the directory name from the file path
    $newPath = (Get-Item $ExecutablePath).DirectoryName
}
else {
    Write-Output "The specified path does not exist or is not a file: $ExecutablePath"
    exit
}

# Ask the user to verify the path
Write-Output "The following path will be added to the PATH environment variable: $newPath"
Write-Output "Is this correct? (y/n)"
$response = Read-Host

if ($response -ne 'y') {
    Write-Output "Operation cancelled by the user."
    exit
}

# Get the current PATH
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", $pathTarget)

# Log the current PATH before modification
Log-CurrentPath -CurrentPath $currentPath -Target $pathTarget

# Check if the new path is already in the PATH
if ($currentPath -like "*$newPath*") {
    Write-Output "The specified path is already in the PATH variable."
    exit
}

# Add the new path to the current PATH
$newPathCombined = $currentPath + ";" + $newPath

# Set the updated PATH
[System.Environment]::SetEnvironmentVariable("PATH", $newPathCombined, $pathTarget)
Write-Output "PATH updated successfully. New PATH: $newPathCombined"

# Check for executables in the new path
$executables = Get-ChildItem -Path $newPath -Filter *.exe
if ($executables.Count -gt 0) {
    Write-Output "The following executables were found in the new path and are now accessible from the command line:"
    foreach ($exe in $executables) {
        Write-Output $exe.Name
    }
}
else {
    Write-Output "No executables were found in the new path."
}
