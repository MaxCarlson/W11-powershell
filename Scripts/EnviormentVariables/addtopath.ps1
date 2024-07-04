param (
    [Alias("h")]
    [Parameter(Mandatory = $false, HelpMessage = "Display help message")]
    [switch]$Help,

    [Alias("e", "path")]
    [Parameter(Mandatory = $true, HelpMessage = "Specify the path to the executable or runnable file to add to PATH")]
    [string]$ExecutablePath,

    [Alias("u")]
    [Parameter(Mandatory = $false, HelpMessage = "Add to user PATH instead of system PATH")]
    [switch]$User,

    [Alias("r")]
    [Parameter(Mandatory = $false, HelpMessage = "Rollback the last PATH modification")]
    [switch]$Rollback,

    [Alias("f")]
    [Parameter(Mandatory = $false, HelpMessage = "Force the operation without user confirmation")]
    [switch]$Force
)

# Display help message if -h or --help is specified
if ($Help) {
    Write-Output @"
Usage: addtopath.ps1 [-e <path>] [-u] [-r] [-f] [-h]

Parameters:
  -e, --path <path>        Specify the path to the executable or runnable file to add to PATH
  -u                       Add to user PATH instead of system PATH
  -r                       Rollback the last PATH modification
  -f                       Force the operation without user confirmation
  -h, --help               Display this help message

Examples:
  .\addtopath.ps1 -e "C:\tools"
  .\addtopath.ps1 -e "C:\tools" -u
  .\addtopath.ps1 -r
  .\addtopath.ps1 -e "C:\tools" -f
"@
    exit
}

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
    try {
        Rollback-Path -Target $pathTarget
    } catch {
        Write-Error "Failed to rollback PATH: $_"
    }
    exit
}

# Check if the executable path is provided
if (-not $ExecutablePath) {
    Write-Error "Please specify the path to the executable or runnable file to add to PATH."
    exit
}

# Check if the executable path exists and is a file or directory
if (Test-Path -Path $ExecutablePath -PathType Leaf) {
    if (-not (Is-RunnableFile -FilePath $ExecutablePath)) {
        Write-Error "The specified file is not a recognized runnable file: $ExecutablePath"
        exit
    }

    # Get the directory name from the file path
    $newPath = (Get-Item $ExecutablePath).DirectoryName
} elseif (Test-Path -Path $ExecutablePath -PathType Container) {
    $newPath = $ExecutablePath
} else {
    Write-Error "The specified path does not exist or is not a valid file or directory: $ExecutablePath"
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

# Ask the user to verify the path, unless forced
if (-not $Force.IsPresent) {
    Write-Output "The following path will be added to the PATH environment variable: $newPath"
    Write-Output "Is this correct? (y/n)"
    $response = Read-Host

    if ($response -ne 'y') {
        Write-Output "Operation cancelled by the user."
        exit
    }
}

# Get the current PATH
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", $pathTarget)

# Log the current PATH before modification
try {
    Log-CurrentPath -CurrentPath $currentPath -Target $pathTarget
} catch {
    Write-Error "Failed to log the current PATH: $_"
    exit
}

# Check if the new path is already in the PATH
if ($currentPath -like "*$newPath*") {
    Write-Output "The specified path is already in the PATH variable."
    exit
}

# Add the new path to the current PATH
$newPathCombined = $currentPath + ";" + $newPath

# Set the updated PATH
try {
    [System.Environment]::SetEnvironmentVariable("PATH", $newPathCombined, $pathTarget)
    Write-Output "PATH updated successfully. New PATH: $newPathCombined"
} catch {
    Write-Error "Failed to update the PATH variable: $_"
}
