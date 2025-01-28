<#
.SYNOPSIS
    Module for package management and Winget search utilities.

.DESCRIPTION
    Provides functions to update installed packages across various package managers (Winget, Chocolatey, Scoop, Conda, Pip) and perform searches using Winget.
    Includes aliases for ease of use.

.EXPORTS
    - Functions: Update-AllPackages, Start-WingetSearch
    - Aliases: ua, myupdate, wingsea

#>

$script:MODULE_NAME = "UpdatePackages"
$script:DEBUG_UPDATE_MODULE = $false
$script:WRITE_TO_DEBUG = $DebugProfile -or $DEBUG_UPDATE_MODULE

<#
.SYNOPSIS
    Checks if the current PowerShell session is running as administrator.

.DESCRIPTION
    Returns a boolean indicating whether the script is running with administrator privileges.

.EXAMPLE
    if (Test-Admin) { Write-Host "Running as Administrator" }

#>
function Test-Admin {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

<#
.SYNOPSIS
    Updates all installed packages using various package managers.

.DESCRIPTION
    Runs update commands for Winget, Chocolatey, Scoop, Conda, and Pip.
    Requires administrative privileges.

.PARAMETER ForceAdminRestart
    If specified, forces the script to restart as administrator if not already elevated.

.EXAMPLE
    Update-AllPackages
    Updates all installed packages.

#>
function Update-AllPackages {
    param (
        [switch]$ForceAdminRestart
    )

    if (-not (Test-Admin)) {
        Write-Host "ERROR: This script must be run as administrator." -ForegroundColor Red
        Write-Host "Please restart PowerShell as administrator and try again." -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Starting package update process..." -ForegroundColor Cyan
    Write-Host "Updating system packages..." -ForegroundColor Cyan

    $updateCommands = @(
        @{ Name = "winget"; Command = { Start-Process -FilePath "winget.exe" -ArgumentList "upgrade --all --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait } }
        @{ Name = "Chocolatey"; Command = { Start-Process -FilePath "choco" -ArgumentList "upgrade all -y" -NoNewWindow -Wait } }
        @{ Name = "Scoop"; Command = { scoop update } }
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

<#
.SYNOPSIS
    Searches for packages using Winget.

.DESCRIPTION
    Allows users to search for software packages using Winget. Supports iterative searching for refining queries.

.PARAMETER Iter
    Enables iterative search mode.

.EXAMPLE
    Start-WingetSearch -Iter
    Starts Winget search in iterative mode.

.EXAMPLE
    Start-WingetSearch
    Prompts for search terms and performs a search.

#>
function Start-WingetSearch {
    param(
        [string[]]$Terms,  # Accept multiple search terms as an array
        [switch]$Iter
    )

    function Search-Winget {
        param(
            [string[]]$Terms
        )

        Write-Debug -Message "Searching Winget with terms: $($Terms -join ', ')" -Channel "Information"

        # Construct query string
        $query = $Terms -join " "

        # Run winget search with query
        $results = winget search --query "$query" | ForEach-Object { $_.Trim() }

        # Debugging: Check raw results before filtering
        Write-Debug -Message "Raw winget output:" -Channel "Verbose"
        $results | ForEach-Object { Write-Debug -Message $_ -Channel "Verbose" }

        # Ensure results exist before filtering
        if (-not $results -or $results.Count -eq 0) {
            Write-Debug -Message "No results returned from winget." -Channel "Warning"
            return
        }

        # Output results
        Write-Debug -Message "Results found:" -Channel "Success"
        $results | ForEach-Object { Write-Debug -Message $_ -Channel "Verbose" }
    }

    function Iterative-WingetSearch {
        Write-Debug -Message "Entering iterative Winget search mode..." -Channel "Information"
        $terms = @()

        do {
            $term = Read-Host "Enter search term (or press Enter to finish)"
            if ($term) {
                $terms += $term
                Search-Winget -Terms $terms
            }
        } while ($term)
    }

    # 🔹 **Execution Logic**
    if ($Terms -and $Terms.Count -gt 0) {
        # Use provided terms, no need to prompt
        Search-Winget -Terms $Terms
    }
    elseif ($Iter) {
        # Enter iterative mode if -Iter is used
        Iterative-WingetSearch
    }
    else {
        # Fallback: prompt for terms
        $Terms = Read-Host "Enter search terms separated by commas" -split ","
        Search-Winget -Terms $Terms
    }
}

# Define aliases
Set-Alias ua Update-AllPackages
Set-Alias myupdate Update-AllPackages
Set-Alias wingsea Start-WingetSearch

# Export module functions and aliases
Export-ModuleMember -Function Update-AllPackages, Start-WingetSearch
Export-ModuleMember -Alias ua, myupdate, wingsea

