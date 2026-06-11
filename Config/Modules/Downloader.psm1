function Write-ModuleColor {
    param(
        [Parameter(Mandatory)][string]$Message,
        [string]$Type = 'White',
        [string]$Color
    )

    $map = @{
        Error      = 'Red'
        Warning    = 'Yellow'
        Success    = 'Green'
        Info       = 'Cyan'
        Processing = 'DarkCyan'
    }
    $resolved = if ($Color) { $Color } elseif ($map.ContainsKey($Type)) { $map[$Type] } else { $Type }
    Write-Host $Message -ForegroundColor $resolved
}

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
            Write-ModuleColor -Message "File already exists: $DestinationPath. Skipping download." -Color Yellow
            return $false
        }
        Write-ModuleColor -Message "Deleting existing file: $DestinationPath" -Color Yellow
        Remove-Item -Path $DestinationPath -Force
    }

    try {
        Write-ModuleColor -Message "Downloading file from $Url to $DestinationPath..." -Color Yellow
        Invoke-WebRequest -Uri $Url -OutFile $DestinationPath -ErrorAction Stop
        Write-ModuleColor -Message "File downloaded successfully: $DestinationPath" -Color Green
        return $true
    } catch {
        Write-ModuleColor -Message "Error downloading file: $_" -Color Red
        return $false
    }
}

Export-ModuleMember -Function Get-File
