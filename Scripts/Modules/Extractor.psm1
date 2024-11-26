Import-Module "$PSScriptRoot/Coloring.psm1"

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


