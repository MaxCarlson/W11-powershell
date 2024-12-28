# Function to check if Python is in PATH and add it if not
function Ensure-PythonInPath {
    # Check if 'python' is accessible
    $pythonPath = which python
    if (-not $pythonPath) {
        Write-Output "Python is not found in the current PATH using 'which'."
        return
    }

    # Get the directory of the Python executable
    $pythonDir = Split-Path -Parent $pythonPath

    # Check if the directory is already in PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
    if ($currentPath -split ";" -contains $pythonDir) {
        Write-Output "Python is already in the PATH."
    } else {
        # Add the directory to PATH
        $newPath = "$currentPath;$pythonDir"
        [Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::User)
        Write-Output "Python directory added to PATH: $pythonDir"
    }
}

# Function to ensure .PY is in PATHEXT
function Ensure-PYInPATHEXT {
    # Get the current PATHEXT variable
    $currentPATHEXT = [Environment]::GetEnvironmentVariable("PATHEXT", [System.EnvironmentVariableTarget]::User)
    if ($currentPATHEXT -split ";" -contains ".PY") {
        Write-Output ".PY is already in PATHEXT."
    } else {
        # Add .PY to PATHEXT
        $newPATHEXT = "$currentPATHEXT;.PY"
        [System.Environment]::SetEnvironmentVariable("PATHEXT", $newPATHEXT, [System.EnvironmentVariableTarget]::User)
        Write-Output ".PY added to PATHEXT."
    }
}

# Execute the functions
Ensure-PythonInPath
Ensure-PYInPATHEXT
