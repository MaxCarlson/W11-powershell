<#
.SYNOPSIS
Adds a specified directory to the system's PATH variable.

.DESCRIPTION
This function updates the system's PATH variable by appending the specified directory if it does not already exist. The DryRun flag allows for a simulated execution.

.PARAMETER Path
The directory to add to the PATH variable.

.PARAMETER Scope
The scope of the PATH modification. Can be "User" or "System". Default is "User".

.PARAMETER Temporary
Flag to make the change impermanent (only for the current session).

.PARAMETER DryRun
Simulates the function's execution, showing what would happen without making actual changes.

.EXAMPLE
Add-ToPath -Path "C:\MyTools" -Scope "User"
#>
function Add-ToPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,        # The folder path to add
        [ValidateSet("User", "System")]
        [string]$Scope = "User",   # Specify "User" or "System" scope (only relevant for permanent changes)
        [switch]$Temporary,        # Flag to make the change impermanent (only for the current session)
        [switch]$DryRun            # Simulate the function without making changes
    )

    $Path = $Path.TrimEnd('\')

    # Validate the path exists
    if (!(Test-Path -Path $Path)) {
        Write-Host "The specified path '$Path' does not exist." -ForegroundColor Red
        return $false
    }

    # Get the current PATH environment variable
    if ($Temporary) {
        $currentPath = $env:PATH
    } elseif ($Scope -eq "User") {
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    } elseif ($Scope -eq "System") {
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    }

    # Validate the current PATH
    if (-not $currentPath) {
        Write-Host "The current PATH variable is empty or invalid." -ForegroundColor Red
        return $false
    }

    # Ensure the path is not already included (case-insensitive)
    $currentPathArray = $currentPath -split ";"
    if ($currentPathArray -contains $Path -or $currentPathArray -ieq $Path) {
        Write-Host "The path '$Path' is already in the $($Temporary ? "session" : $Scope) PATH." -ForegroundColor Yellow
        if ($DryRun) {
            Write-Host "DryRun: No changes would be made since the path is already present." -ForegroundColor Yellow
        }
        return $true
    }

    # Simulate or apply changes
    $newPath = ($currentPathArray + $Path) -join ";"

    if ($DryRun) {
        Write-Host "DryRun: Simulating changes to the PATH variable." -ForegroundColor Cyan
        Write-Host "Current PATH:" -ForegroundColor Cyan
        Write-Host $currentPath
        Write-Host "Proposed new PATH:" -ForegroundColor Cyan
        Write-Host $newPath

        # Validate the simulated new PATH
        $valid = $true
        foreach ($path in $newPath -split ";") {
            if ($path -ne "" -and !(Test-Path -Path $path)) {
                Write-Host "DryRun: Invalid path detected in the proposed PATH: '$path'" -ForegroundColor Red
                $valid = $false
            }
        }

        if ($valid) {
            Write-Host "DryRun: The proposed new PATH is valid." -ForegroundColor Green
        } else {
            Write-Host "DryRun: The proposed new PATH contains invalid entries." -ForegroundColor Red
        }

        return $valid
    }

    # Apply changes if not a dry run
    if ($Temporary) {
        # Set session-only PATH
        $env:PATH = $newPath
        Write-Host "The path '$Path' has been added to the session PATH." -ForegroundColor Green
    } else {
        try {
            # Set permanent PATH
            [Environment]::SetEnvironmentVariable("PATH", $newPath, $Scope)
            Write-Host "The path '$Path' has been added to the $Scope PATH permanently." -ForegroundColor Green
        } catch {
            Write-Host "Failed to add the path to the $Scope PATH. Error: $_" -ForegroundColor Red
            return $false
        }
    }

    return $true
}

