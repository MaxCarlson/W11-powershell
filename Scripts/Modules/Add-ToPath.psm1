function Add-ToPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PathToAdd,        # The folder path to add
        [ValidateSet("User", "System")]
        [string]$Scope = "User",   # Specify "User" or "System" scope (only relevant for permanent changes)
        [switch]$Temporary          # Flag to make the change impermanent (only for the current session)
    )

    # Get the current PATH environment variable
    if ($Temporary) {
        # For temporary (session-only) changes
        $currentPath = $env:PATH
    } elseif ($Scope -eq "User") {
        # For permanent user-level changes
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    } elseif ($Scope -eq "System") {
        # For permanent system-level changes
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    }

    # Check if the path already exists in PATH
    if ($currentPath -split ";" -contains $PathToAdd) {
        Write-Host "The path '$PathToAdd' is already in the $($Temporary ? "session" : $Scope) PATH." -ForegroundColor Yellow
        return
    }

    # Add the new path
    $newPath = "$currentPath;$PathToAdd"

    if ($Temporary) {
        # Set session-only PATH
        $env:PATH = $newPath
        Write-Host "The path '$PathToAdd' has been added to the session PATH." -ForegroundColor Green
    } else {
        # Set permanent PATH
        [Environment]::SetEnvironmentVariable("PATH", $newPath, $Scope)
        Write-Host "The path '$PathToAdd' has been added to the $Scope PATH permanently." -ForegroundColor Green
    }
}
