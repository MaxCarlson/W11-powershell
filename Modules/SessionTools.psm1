<#
.SYNOPSIS
Reloads the current session's PATH variable.

.DESCRIPTION
Combines user and machine PATH variables to refresh the current session's PATH.

.EXAMPLE
Refresh-Path
#>
function Refresh-Path {
    # Combine User and Machine PATH variables
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)

    # Update the current session's PATH
    $env:PATH = "${userPath};${machinePath}"

    # Output the reloaded PATH for verification
    Write-Host "PATH has been reloaded for the current session." -ForegroundColor Green
    Write-Host "${env:PATH}" -ForegroundColor Yellow
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

function Refresh-Environment {
    # Reload both PATH and PowerShell profile
    Refresh-Path
    Refresh-Profile
    Write-Host "Both PATH and PowerShell profile have been reloaded." -ForegroundColor Green
}

# Add a variable permenantly to the profilePath
<#
.SYNOPSIS
Adds a persistent variable to the PowerShell profile.

.DESCRIPTION
Writes a global variable definition to the PowerShell profile for use in all future sessions.

.PARAMETER VariableName
The name of the variable to add.

.PARAMETER Value
The value of the variable to add.

.EXAMPLE
Add-PersistentVariable -VariableName "MyPath" -Value "C:\MyTools"
#>
function Add-PersistentVariable {
    param (
        [Parameter(Mandatory = $true)]
        [string]$VariableName,
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [switch]$InsertHeader
    )

    # Reserved PowerShell variables
    $reservedVariables = Get-Variable | ForEach-Object { $_.Name }

    # Check if the variable name is reserved
    if ($reservedVariables -contains $VariableName) {
        Write-Host "The variable '${VariableName}' is reserved by PowerShell. Choose a different name." -ForegroundColor Yellow
        return
    }

    # Define the path to the current user profile
    $profilePath = ${PROFILE}

    # Ensure the profile exists or ask to create one
    if (-not (Test-Path ${profilePath})) {
        Write-Host "The profile does not exist at: ${profilePath}" -ForegroundColor Yellow
        $createProfile = Read-Host "Would you like to create a new profile? (y/n)"
        if ($createProfile -notmatch "^(y|Y)$") {
            Write-Host "Profile creation aborted. Exiting without changes." -ForegroundColor Red
            return
        }

        # Create a new profile file without overwriting existing files
        Write-Host "Creating a new profile at: ${profilePath}" -ForegroundColor Green
        New-Item -ItemType File -Path ${profilePath} -Force
    }

    # Read the profile content
    $profileContent = Get-Content -Path ${profilePath} -Raw

    # Define the magic header text
    $magicHeader = "# Variables Added to Profile from Add-Variable.ps1 script."

    # Check if the magic header exists
    if ($profileContent -notmatch [regex]::Escape($magicHeader)) {
        if ($InsertHeader.IsPresent) {
            # Insert the header at the appropriate location
            if ($profileContent -match "oh-my-posh init") {
                # After oh-my-posh initialization
                $profileContent = $profileContent -replace "(oh-my-posh init .+?Invoke-Expression)", "`${1}`n${magicHeader}"
            } else {
                # After the first non-commented line
                $profileContent = $profileContent -replace "(?<=^(?!#).+)", "${magicHeader}`n`${0}", 1
            }
            Write-Host "Magic header added to the profile." -ForegroundColor Green
        } else {
            Write-Host "Warning: Magic header not found in the profile." -ForegroundColor Yellow
            Write-Host "Add the following line manually to your profile or use -InsertHeader to add it automatically:" -ForegroundColor Yellow
            Write-Host "`n${magicHeader}`n" -ForegroundColor Cyan
            return
        }
    }

    # Split the profile content into lines
    $lines = $profileContent -split "`n"

    # Find the line index where variables should be added
    $headerIndex = $lines.IndexOf($magicHeader)
    $insertIndex = $headerIndex + 1

    while ($insertIndex -lt $lines.Count -and $lines[$insertIndex] -match "^\${global}:[a-zA-Z0-9_]+\s*=\s*.+$") {
        $insertIndex++
    }

    # Check if the variable already exists in the profile
    if ($lines -match "^\${global}:${VariableName}\s*=\s*.+$") {
        Write-Host "The variable '${VariableName}' is already declared in the profile." -ForegroundColor Yellow
        return
    }

    # Add the new variable
    $newVariable = "`${global}:${VariableName} = '${Value}'"
    $lines.Insert($insertIndex, $newVariable)

    # Write the updated content back to the profile
    Set-Content -Path ${profilePath} -Value ($lines -join "`n")

    Write-Host "The variable '${VariableName}' has been added and will be available in future sessions." -ForegroundColor Green
}

Export-ModuleMember -Function Add-PersistentVariable
