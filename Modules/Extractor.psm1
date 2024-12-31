Import-Module "$PSScriptRoot/Coloring.psm1"

<#
.SYNOPSIS
Extracts the contents of an archive file.

.DESCRIPTION
Supports various archive formats and extracts their contents to the specified directory.

.PARAMETER ArchivePath
The path to the archive file.

.PARAMETER DestinationPath
The directory where the archive contents will be extracted.

.EXAMPLE
Expand-CustomArchive -ArchivePath "C:\Downloads\file.zip" -DestinationPath "C:\Extracted"
#>
function Expand-CustomArchive {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [switch]$Overwrite
    )

    try {
        if (Test-Path -Path $DestinationPath) {
            if (-not $Overwrite) {
                Write-Color -Message "Destination directory already exists: $DestinationPath. Skipping extraction." -Color Yellow
                return $false
            }

            Write-Color -Message "Deleting existing directory: $DestinationPath" -Color Yellow
            Remove-Item -Recurse -Force $DestinationPath
        }

        Write-Color -Message "Unzipping file: $ArchivePath to $DestinationPath..." -Color Yellow
        Expand-Archive -Path $ArchivePath -DestinationPath $DestinationPath -Force
        Write-Color -Message "File unzipped successfully to: $DestinationPath" -Color Green
        return $true
    } catch {
        Write-Color -Message "Error during extraction: $_" -Color Red
        return $false
    }
}

Export-ModuleMember -Function Expand-CustomArchive


