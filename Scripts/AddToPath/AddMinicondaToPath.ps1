param(
    [bool]$addToUserPath = $true, # Add to user PATH by default; set to $false to add to system PATH
    [string[]]$pathsToAdd # Array to store paths to be added
)

function AddToPath {
    param(
        [string[]]$newPaths,
        [string]$pathType
    )
    $oldPath = [System.Environment]::GetEnvironmentVariable('PATH', $pathType)
    Write-Verbose "Current $pathType PATH: $oldPath"
    
    foreach ($newPath in $newPaths) {
        if (-not $oldPath -split ';' -contains $newPath) {
            $oldPath += ";$newPath"
            Write-Verbose "Adding $newPath to the $pathType PATH."
        } else {
            Write-Host "The path $newPath is already in the $pathType PATH."
        }
    }

    [System.Environment]::SetEnvironmentVariable('PATH', $oldPath, $pathType)
    Write-Verbose "New $pathType PATH: $oldPath"
}

# Determine the type of PATH to modify
$pathType = $addToUserPath ? 'User' : 'Machine'

# Validate and add the paths
$validPaths = $pathsToAdd | Where-Object { Test-Path $_ }
if ($validPaths) {
    AddToPath -newPaths $validPaths -pathType $pathType
} else {
    Write-Host "No valid paths provided or paths do not exist."
}
