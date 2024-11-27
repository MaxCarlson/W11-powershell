param (
    [Parameter(Mandatory = $true)]
    [string]$FolderPath,  # The path to the folder

    [Parameter(Mandatory = $true)]
    [string]$UserName,    # The username to grant access

    [Parameter(Mandatory = $false)]
    [bool]$Recursive = $true  # Whether to apply permissions recursively (default: true)
)

# Check if the folder exists
if (-not (Test-Path -Path $FolderPath)) {
    Write-Color -Message "The folder '$FolderPath' does not exist. Exiting." -Type "Error"
    exit 1
}

# Grant access
try {
    Write-Color -Message "Granting access to $UserName for folder '$FolderPath'..." -Type "Processing"

    # Build the icacls command
    $Command = if ($Recursive) {
        "icacls $FolderPath /grant '${UserName}:(OI)(CI)F' /T"
    } else {
        "icacls $FolderPath /grant '${UserName}:(OI)(CI)F'"
    }

    # Execute the command
    Invoke-Expression $Command

    Write-Color -Message "Access successfully granted to ${UserName} on '${FolderPath}'." -Type "Success"
} catch {
    Write-Color -Message "Failed to grant access to ${UserName} on '${FolderPath}'. Error: $_" -Type "Error"
    exit 1
}
