# Shared user-level setup tasks used by both admin and non-admin installers.
param(
    [string]$ScriptBase = $PSScriptRoot,
    [switch]$PersistEnv = $true,
    [switch]$EnsureProfileLink = $true,
    [switch]$ConfigureRepoEnv = $true,
    [string[]]$AgentLinkLocations = @('AppData')
)

function Invoke-UserSetupCore {
    param(
        [string]$ScriptBase,
        [switch]$PersistEnv,
        [switch]$EnsureProfileLink,
        [switch]$ConfigureRepoEnv,
        [string[]]$AgentLinkLocations
    )

    Write-Host "--- User setup (shared) ---" -ForegroundColor Cyan

    # Session + user environment variable
    $env:PWSH_REPO = $ScriptBase
    Write-Host "PWSH_REPO (session) => $ScriptBase" -ForegroundColor DarkGray
    if ($PersistEnv) {
        try {
            [System.Environment]::SetEnvironmentVariable('PWSH_REPO', $ScriptBase, [System.EnvironmentVariableTarget]::User)
            Write-Host "PWSH_REPO (user) persisted." -ForegroundColor Green
        } catch {
            Write-Warning ("Could not persist PWSH_REPO: {0}" -f $_)
        }
    }

    # Optional repo env resolution (uses scripts/pwsh/ResolveRepoPaths.ps1 if present)
    if ($ConfigureRepoEnv) {
        $scriptsRepo = Join-Path (Split-Path $ScriptBase -Parent) "scripts"
        $resolver = Join-Path $scriptsRepo "pwsh\ResolveRepoPaths.ps1"
        if (Test-Path $resolver) {
            try {
                . $resolver
                Initialize-RepoEnvironment -AnchorPath $ScriptBase -AnchorRepoName 'W11-powershell' -PersistScopes @('User') | Out-Null
                Write-Host "Repo environment variables synchronized." -ForegroundColor Green
            } catch {
                Write-Warning ("Repo environment sync failed: {0}" -f $_)
            }
        }
    }

    # Ensure profile hardlink
    if ($EnsureProfileLink) {
        $profileTarget = Join-Path $ScriptBase "Profiles\CustomProfile.ps1"
        $linkScript = Join-Path $ScriptBase "Profiles\HardLinkProfile.ps1"
        $profilePath = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        if (-not (Test-Path (Split-Path $profilePath -Parent))) {
            New-Item -ItemType Directory -Path (Split-Path $profilePath -Parent) -Force | Out-Null
        }
        if (-not (Test-Path $profileTarget)) {
            Write-Warning "CustomProfile.ps1 not found at $profileTarget"
        } elseif (-not (Test-Path $linkScript)) {
            Write-Warning "HardLinkProfile.ps1 not found at $linkScript"
        } else {
            try {
                & $linkScript -Replace a
            } catch {
                Write-Warning ("Failed to create profile hardlink: {0}" -f $_)
            }
        }
    }

    # Ensure agent instructions are linked globally
    if ($AgentLinkLocations -and $AgentLinkLocations.Count -gt 0) {
        $agentLinkScript = Join-Path $ScriptBase "Profiles\Ensure-AgentLinks.ps1"
        if (Test-Path $agentLinkScript) {
            try {
                & $agentLinkScript -Locations $AgentLinkLocations
            } catch {
                Write-Warning ("Failed to link AGENTS.md into requested locations: {0}" -f $_)
            }
        } else {
            Write-Warning "Agent linking script not found at $agentLinkScript"
        }
    }

    Write-Host "--- User setup complete ---" -ForegroundColor Cyan
}

Invoke-UserSetupCore -ScriptBase $ScriptBase -PersistEnv:$PersistEnv -EnsureProfileLink:$EnsureProfileLink -ConfigureRepoEnv:$ConfigureRepoEnv -AgentLinkLocations $AgentLinkLocations
