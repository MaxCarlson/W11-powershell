param (
    [Parameter(Mandatory = $true)]
    [string]$Url,                        # URL to download

    [Parameter(Mandatory = $true)]
    [string]$DownloadPath,               # File download destination

    [Parameter(Mandatory = $true)]
    [string]$ExtractPath,                # Extraction destination

    [switch]$AddToPath,                  # Add extracted directory to PATH after extraction

    [switch]$OverwriteDownload,          # Overwrite existing file before downloading

    [switch]$OverwriteExtract            # Delete extraction directory if it already exists
)

# Resolve the module directory dynamically
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../Modules"

# Import modules
Import-Module -Name (Join-Path -Path $ModulePath -ChildPath "Downloader.psm1")
Import-Module -Name (Join-Path -Path $ModulePath -ChildPath "Extractor.psm1")
Import-Module -Name (Join-Path -Path $ModulePath -ChildPath "PathManager.psm1")
Import-Module -Name (Join-Path -Path $ModulePath -ChildPath "Coloring.psm1")

# Step 1: Download the file
$downloadSuccess = $false
if (-not (Test-Path -Path $DownloadPath) -or $OverwriteDownload) {
    $downloadSuccess = Get-File -Url $Url -DestinationPath $DownloadPath -Overwrite:$OverwriteDownload
    Write-Color -Message "Download Success: $downloadSuccess" -Color Green
} else {
    Write-Color -Message "File already exists at $DownloadPath. Skipping download." -Color Yellow
    $downloadSuccess = $true
}

# Step 2: Extract the file if download succeeded or if skipping download
$extractSuccess = $false
if ($downloadSuccess -or $AddToPath) {
    if (-not (Test-Path -Path $ExtractPath) -or $OverwriteExtract) {
        $extractSuccess = Expand-CustomArchive -ArchivePath $DownloadPath -DestinationPath $ExtractPath -Overwrite:$OverwriteExtract
        Write-Color -Message "Extract Success: $extractSuccess" -Color Green
    } else {
        Write-Color -Message "Folder already exists at $ExtractPath. Skipping extraction." -Color Yellow
        $extractSuccess = $true
    }

    # Step 3: Add the directory to PATH if AddToPath is set
    if ($AddToPath -and ($extractSuccess -or $downloadSuccess)) {
        Write-Color -Message "Starting to search for .exe files in $ExtractPath" -Color Green

        # Step 1: Collect all .exe files
        try {
            $exeFiles = Get-ChildItem -Path $ExtractPath -Recurse -Filter '*.exe' -ErrorAction Stop
            Write-Color -Message "Found $($exeFiles.Count) .exe file(s)." -Color Green

            if ($exeFiles.Count -eq 0) {
                Write-Color -Message "No .exe files found in the directory tree." -Color Red
            } else {
                Write-Color -Message "Listing all .exe files found:" -Color Cyan
                foreach ($exeFile in $exeFiles) {
                    Write-Color -Message "File Path: $($exeFile.FullName)" -Color Yellow
                    Write-Color -Message "Containing Directory: $($exeFile.DirectoryName)" -Color Yellow
                }
            }
        } catch {
            Write-Color -Message "Error during Get-ChildItem: $_" -Color Red
            return
        }

        # Step 2: Extract unique directories containing executables
        try {
            $exeFolders = $exeFiles | ForEach-Object {
                $dir = $_.DirectoryName
                if ([string]::IsNullOrWhiteSpace($dir)) {
                    Write-Color -Message "Skipping empty directory for file -> $($_.FullName)" -Color Red
                    continue
                }
                if (Test-Path -Path $dir) {
                    Write-Color -Message "Adding valid directory -> $dir" -Color Cyan
                    $dir
                } else {
                    Write-Color -Message "Skipping invalid directory -> $dir" -Color Red
                }
            } | Sort-Object -Unique

            if ($exeFolders.Count -eq 0) {
                Write-Color -Message "No valid directories containing executables were identified." -Color Red
            } else {
                Write-Color -Message "Unique directories containing executables:" -Color Cyan
                foreach ($folder in $exeFolders) {
                    Write-Color -Message "$folder" -Color Yellow
                }
            }
        } catch {
            Write-Color -Message "Error during unique directory collection: $_" -Color Red
            return
        }

        # Step 3: Prompt the user if folders were found
        if ($exeFolders.Count -gt 0) {
            Write-Color -Message "Found the following folders containing executables:" -Color Green

            # Ensure $exeFolders is treated as an array
            $exeFolders = @($exeFolders)

            for ($i = 0; $i -lt $exeFolders.Count; $i++) {
                Write-Color -Message "Processing folder index ${i}: $($exeFolders[$i])" -Color Yellow
                Write-Color -Message "$($i + 1). $($exeFolders[$i])" -Color Cyan
            }

            # Prompt user for selection
            do {
                $selection = Read-Host -Prompt "Enter the number corresponding to the folder you want to add to PATH (or '0' to skip)"
                try {
                    $selection = [int]$selection
                } catch {
                    Write-Color -Message "Invalid input. Please enter a valid number." -Color Red
                    $selection = -1 # Reset selection to loop again
                }
            } while ($selection -lt 0 -or $selection -gt $exeFolders.Count)

            if ($selection -ne 0) {
                $selectedPath = $exeFolders[$selection - 1]
                Write-Color -Message "Selected folder to add to PATH: $selectedPath" -Color Green
                Add-PathItem -Directory $selectedPath -Verbose
            } else {
                Write-Color -Message "No folder added to PATH." -Color Green
            }
        } else {
            Write-Color -Message "No unique folders with executables found." -Color Red
        }
    }

} else {
    Write-Color -Message "Skipping extraction and PATH addition because download failed." -Color Red
}

