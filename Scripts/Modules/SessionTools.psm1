function Refresh-Path {
    # Combine User and Machine PATH variables
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)

    # Update the current session's PATH
    $env:PATH = $userPath + ";" + $machinePath

    # Output the reloaded PATH for verification
    Write-Host "PATH has been reloaded for the current session." -ForegroundColor Green
    Write-Host $env:PATH -ForegroundColor Yellow
}

function Refresh-Profile {
    # Reload PowerShell profile if it exists
    if (Test-Path $PROFILE) {
        . $PROFILE
        Write-Host "PowerShell profile has been reloaded." -ForegroundColor Cyan
    } else {
        Write-Host "No profile found to reload." -ForegroundColor Red
    }
}

function Refresh-Enviornment {
    # Reload both PATH and PowerShell profile
    Reload-Path
    Reload-Profile
    Write-Host "Both PATH and PowerShell profile have been reloaded." -ForegroundColor Green
}
