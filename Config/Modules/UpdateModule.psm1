$script:MODULE_NAME = "UpdatePackages"
$script:DEBUG_UPDATE_MODULE = $false
$script:WRITE_TO_DEBUG = $DebugProfile -or $DEBUG_UPDATE_MODULE

function Test-Admin {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Update-AllPackages {
    param (
        [switch]$ForceAdminRestart
    )

    # Ensure running as admin
    if (-not (Test-Admin)) {
        Write-Host "ERROR: This script must be run as administrator." -ForegroundColor Red
        Write-Host "Please restart PowerShell as administrator and try again." -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Starting package update process..." -ForegroundColor Cyan
    Write-Host "Updating system packages..." -ForegroundColor Cyan

    # Define update commands
    $updateCommands = @(
    @{ Name = "winget"; Command = { Start-Process -FilePath "winget.exe" -ArgumentList "upgrade --all --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait } }
    @{ Name = "Chocolatey"; Command = { Start-Process -FilePath "choco" -ArgumentList "upgrade all -y" -NoNewWindow -Wait } }
    @{ Name = "Scoop"; Command = { scoop update } }  # Scoop should already show output
    @{ Name = "Conda"; Command = { Start-Process -FilePath "conda" -ArgumentList "update --all --yes" -NoNewWindow -Wait } }
    @{ Name = "Pip"; Command = { cmd /c "pip list --outdated --format=freeze | ForEach-Object { ($_ -split '=')[0] } | ForEach-Object { pip install --upgrade $_ }" } }
)


    foreach ($update in $updateCommands) {
        Write-Host "Updating $($update.Name) packages..." -ForegroundColor Blue
        try {
            Debug-Action -VerboseAction:$DEBUG_UPDATE_MODULE -SuppressOutput:$false -Action $update.Command
            Write-Host "$($update.Name) update completed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Error updating $($update.Name): $_" -ForegroundColor Red
        }
    }

    Write-Host "All package updates completed." -ForegroundColor Green
}

# Aliases
Set-Alias ua Update-AllPackages
Set-Alias myupdate Update-AllPackages

Export-ModuleMember -Function Update-AllPackages
Export-ModuleMember -Alias ua, myupdate

