# manage-path.ps1

param (
    [Parameter(Mandatory = $true, HelpMessage = "Specify the path to the executable or runnable file to add to PATH")]
    [string]$ExecutablePath,

    [Parameter(Mandatory = $false, HelpMessage = "Add to user PATH instead of system PATH")]
    [switch]$User,

    [Parameter(Mandatory = $false, HelpMessage = "Rollback the last PATH modification")]
    [switch]$Rollback,

    [Parameter(Mandatory = $false, HelpMessage = "Force the decision to go through, useful if using this script in automation")]
    [switch]$Force
)

# Import the helper functions
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$scriptDirectory\lib\functions.ps1"

# Determine the target for the PATH update
$pathTarget = [System.EnvironmentVariableTarget]::Machine
if ($User.IsPresent) {
    $pathTarget = [System.EnvironmentVariableTarget]::User
}

# Rollback if the -Rollback switch is specified
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
} elseif (Test-Path -Path $ExecutablePath -PathType Container) {
    $newPath = $ExecutablePath
} else {
    Write-Output "The specified path does not exist or is not a valid file or directory: $ExecutablePath"
    exit
}

# Get the current PATH directories
$currentPathDirs = [System.Environment]::GetEnvironmentVariable("PATH", $pathTarget).Split(';')

# Check for overlapping executables
$result = Check-OverlappingExecutables -NewPath $newPath -CurrentPathDirs $currentPathDirs
$newPathExecutables = $result.NewPathExecutables
$overlappingExecutables = $result.OverlappingExecutables

# Print the executables in the new path
if ($newPathExecutables.Count -gt 0) {
    Write-Output "The following executables were found in the new path:"
    foreach ($exe in $newPathExecutables) {
        Write-Output $exe.Name
    }
} else {
    Write-Output "No executables were found in the new path."
}

# Warn about overlapping executables
if ($overlappingExecutables.Count -gt 0) {
    Write-Output "Warning: The following executables in the new path overlap with existing executables in the PATH:"
    foreach ($exe in $overlappingExecutables) {
        Write-Output $exe
    }
}

# Ask the user to verify the path
Write-Output "The following path will be added to the PATH environment variable: $newPath"
Write-Output "Is this correct? (y/n)"
$response = Read-Host

if ($Force.IsNotPresent && $response -ne 'y') {
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
