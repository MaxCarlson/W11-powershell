Import-Module "$PSScriptRoot/Coloring.psm1"


<#
.SYNOPSIS
Adds a directory to the system PATH.

.DESCRIPTION
Appends a specified directory to the system PATH variable for the current session or permanently.

.PARAMETER Path
The directory to add to the PATH.

.PARAMETER Permanent
Specifies whether the change should be permanent.

.EXAMPLE
Add-PathItem -Path "C:\MyTools" -Permanent
#>
function Add-PathItem {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Directory
    )

    # Retrieve the current PATH
    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)

    if ($currentPath -like "*$Directory*") {
        Write-Color -Message "Directory already exists in PATH: $Directory" -Color Yellow
        return
    }

    try {
        # Add the directory to PATH
        [System.Environment]::SetEnvironmentVariable("PATH", "$currentPath;$Directory", [System.EnvironmentVariableTarget]::User)
        Write-Color -Message "Directory added to PATH successfully: $Directory" -Color Green
    } catch {
        Write-Color -Message "Failed to add directory to PATH: $_" -Color Red
    }
}

Export-ModuleMember -Function Add-PathItem
