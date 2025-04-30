
function Set-EnvVar {
    param (
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Value,
        [ValidateSet("User", "Machine")][string]$Scope = "User"
    )

    [System.Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
    Write-Host "[✓] Set $Name=$Value for $Scope" -ForegroundColor Green
}

Set-EnvVar -Name "W11_ROOT" -Value "$HOME\Repos\scripts\pscripts\W11-powershell"
Set-EnvVar -Name "SCRIPTS" -Value  "$HOME\Repos\scripts"
Set-EnvVar -Name "PSCRIPTS" -Value  "$HOME\Repos\scripts\pscripts"
Set-EnvVar -Name "YTDLP_PATH" -Value "$PSCRIPTS\video\yt_dlp\ytdlp.ps1"
Set-EnvVar -Name "DOTFILES_PATH" -Value "$HOME\Repos\scripts\pscripts\W11-powershell"
