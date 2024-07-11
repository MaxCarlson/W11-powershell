# Define the function to add a variable permanently
function Add-PersistentVariable {
    param (
        [Parameter(Mandatory = $true)]
        [string]$VariableName,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    # Check if the variable name is already in use
    if (Get-Variable -Name $VariableName -ErrorAction SilentlyContinue) {
        Write-Host "The variable '$VariableName' is already in use. Choose a different name."
    }
    else {
        # Add the variable to the current session
        Set-Variable -Name $VariableName -Value $Value

        # Add the variable to the PowerShell profile
        $profilePath = $PROFILE

        # Check if the profile file exists
        if (-not (Test-Path $profilePath)) {
            # Create an empty profile file
            New-Item -ItemType File -Path $profilePath -Force
        }

        # Append the variable definition to the profile file
        Add-Content -Path $profilePath -Value "`n`$global:$VariableName = '$Value'"

        Write-Host "The variable '$VariableName' has been added and will be available in future sessions."
    }
}

# Example usage
# Add-PersistentVariable -VariableName "MyVar" -Value "MyValue"
