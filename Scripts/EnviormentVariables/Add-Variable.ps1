# Define the function to add a variable permanently
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
        Write-Host "The variable '$VariableName' is reserved by PowerShell. Choose a different name." -ForegroundColor Yellow
        return
    }

    # Define the path to the current user profile
    $profilePath = $PROFILE

    # Ensure the profile exists or ask to create one
    if (-not (Test-Path $profilePath)) {
        Write-Host "The profile does not exist at: $profilePath" -ForegroundColor Yellow
        $createProfile = Read-Host "Would you like to create a new profile? (y/n)"
        if ($createProfile -notmatch "^(y|Y)$") {
            Write-Host "Profile creation aborted. Exiting without changes." -ForegroundColor Red
            return
        }

        # Create a new profile file without overwriting existing files
        Write-Host "Creating a new profile at: $profilePath" -ForegroundColor Green
        New-Item -ItemType File -Path $profilePath -Force
    }

    # Read the profile content
    $profileContent = Get-Content -Path $profilePath -Raw

    # Define the magic header text
    $magicHeader = "#### Permenant Variables - Added to Profile manually or bybusing Add-PersistentVariable function. ####"

    # Check if the magic header exists
    if ($profileContent -notmatch [regex]::Escape($magicHeader)) {
        if ($InsertHeader.IsPresent) {
            # Insert the header at the appropriate location
            if ($profileContent -match "oh-my-posh init") {
                # After oh-my-posh initialization
                $profileContent = $profileContent -replace "(oh-my-posh init .+?Invoke-Expression)", "`$1`n$magicHeader"
            } else {
                # After the first non-commented line
                $profileContent = $profileContent -replace "(?<=^(?!#).+$)", "$magicHeader`n`$0", 1
            }
            Write-Host "Magic header added to the profile." -ForegroundColor Green
        } else {
            Write-Host "Warning: Magic header not found in the profile." -ForegroundColor Yellow
            Write-Host "Add the following line manually to your profile or use -InsertHeader to add it automatically:" -ForegroundColor Yellow
            Write-Host "`n$magicHeader`n" -ForegroundColor Cyan
            return
        }
    }

    # Split the profile content into lines
    $lines = $profileContent -split "`n"

    # Find the line index where variables should be added
    $headerIndex = $lines.IndexOf($magicHeader)
    $insertIndex = $headerIndex + 1

    while ($insertIndex -lt $lines.Count -and $lines[$insertIndex] -match "^\$global:[a-zA-Z0-9_]+\s*=\s*.+$") {
        $insertIndex++
    }

    # Check if the variable already exists in the profile
    if ($lines -match "^\$global:$VariableName\s*=\s*.+$") {
        Write-Host "The variable '$VariableName' is already declared in the profile." -ForegroundColor Yellow
        return
    }

    # Add the new variable
    $newVariable = "`$global:$VariableName = '$Value'"
    $lines.Insert($insertIndex, $newVariable)

    # Write the updated content back to the profile
    Set-Content -Path $profilePath -Value ($lines -join "`n")

    Write-Host "The variable '$VariableName' has been added and will be available in future sessions." -ForegroundColor Green
}

# Example usage
# Add a variable and insert the header automatically
# Add-PersistentVariable -VariableName "NEW_VARIABLE" -Value "ExampleValue" -InsertHeader

# Add a variable without inserting the header automatically
# Add-PersistentVariable -VariableName "NEW_VARIABLE" -Value "ExampleValue"
