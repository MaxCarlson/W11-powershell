Import-Module "$PSScriptRoot/Coloring.psm1"

<#
.SYNOPSIS
Downloads a file from a given URL.

.DESCRIPTION
Retrieves a file from a specified URL and saves it to the target directory.

.PARAMETER URL
The URL of the file to download.

.PARAMETER OutputPath
The path where the file will be saved.

.EXAMPLE
Get-File -URL "https://example.com/file.zip" -OutputPath "C:\Downloads"
#>
function Get-File {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [switch]$Overwrite
    )

    if (Test-Path -Path $DestinationPath) {
        if (-not $Overwrite) {
            Write-Color -Message "File already exists: $DestinationPath. Skipping download." -Color Yellow
            return $false
        }
        Write-Color -Message "Deleting existing file: $DestinationPath" -Color Yellow
        Remove-Item -Path $DestinationPath -Force
    }

    try {
        Write-Color -Message "Downloading file from $Url to $DestinationPath..." -Color Yellow
        Invoke-WebRequest -Uri $Url -OutFile $DestinationPath -ErrorAction Stop
        Write-Color -Message "File downloaded successfully: $DestinationPath" -Color Green
        return $true
    } catch {
        Write-Color -Message "Error downloading file: $_" -Color Red
        return $false
    }
}

Export-ModuleMember -Function Get-File
