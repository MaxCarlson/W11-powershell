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
$downloadSuccess = Get-File -Url $Url -DestinationPath $DownloadPath -Overwrite:$OverwriteDownload

# Step 2: Extract the file if download succeeded
if ($downloadSuccess) {
    $extractSuccess = Expand-CustomArchive -ArchivePath $DownloadPath -DestinationPath $ExtractPath -Overwrite:$OverwriteExtract

    Write-Color -Message "Extract Success: ${extractSuccess}" -Color Yellow

    # Step 3: Add the directory to PATH if extraction succeeded and $AddToPath is set
     if ($extractSuccess -and $AddToPath) {
    Write-Color -Message "DEBUG: Starting to search for .exe files in $ExtractPath" -Color Green

    # Step 1: Collect all .exe files
    try {
        $exeFiles = Get-ChildItem -Path $ExtractPath -Recurse -Filter '*.exe' -ErrorAction Stop
        Write-Color -Message "DEBUG: Found $($exeFiles.Count) .exe file(s)." -Color Green

        if ($exeFiles.Count -eq 0) {
            Write-Color -Message "DEBUG: No .exe files found in the directory tree." -Color Red
        } else {
            Write-Color -Message "DEBUG: Listing all .exe files found:" -Color Cyan
            foreach ($exeFile in $exeFiles) {
                Write-Color -Message "DEBUG: File Path: $($exeFile.FullName)" -Color Yellow
                Write-Color -Message "DEBUG: Containing Directory: $($exeFile.DirectoryName)" -Color Yellow
            }
        }
    } catch {
        Write-Color -Message "DEBUG: Error during Get-ChildItem: $_" -Color Red
        return
    }

    # Step 2: Extract unique directories containing executables
    try {
        $exeFolders = $exeFiles | ForEach-Object {
            $dir = $_.DirectoryName
            if ([string]::IsNullOrWhiteSpace($dir)) {
                Write-Color -Message "DEBUG: Skipping empty directory for file -> $($_.FullName)" -Color Red
                continue
            }
            if (Test-Path -Path $dir) {
                Write-Color -Message "DEBUG: Adding valid directory -> $dir" -Color Cyan
                $dir
            } else {
                Write-Color -Message "DEBUG: Skipping invalid directory -> $dir" -Color Red
            }
        } | Sort-Object -Unique

        if ($exeFolders.Count -eq 0) {
            Write-Color -Message "DEBUG: No valid directories containing executables were identified." -Color Red
        } else {
            Write-Color -Message "DEBUG: Unique directories containing executables:" -Color Cyan
            foreach ($folder in $exeFolders) {
                Write-Color -Message "DEBUG: $folder" -Color Yellow
            }
        }
    } catch {
        Write-Color -Message "DEBUG: Error during unique directory collection: $_" -Color Red
        return
    }

    # Step 3: Prompt the user if folders were found
    if ($exeFolders.Count -gt 0) {
        Write-Color -Message "Found the following folders containing executables:" -Color Green
        #for ($i = 0; $i -lt $exeFolders.Count; $i++) {
        #    Write-Color -Message "$($i + 1). $($exeFolders[$i])" -Color Cyan
        #}

        # Ensure $exeFolders is treated as an array
        $exeFolders = @($exeFolders)

        for ($i = 0; $i -lt $exeFolders.Count; $i++) {
            Write-Color -Message "DEBUG: Processing folder index ${i}: $($exeFolders[$i])" -Color Yellow
            Write-Color -Message "$($i + 1). $($exeFolders[$i])" -Color Cyan
        }

        # Prompt user for selection
        do {
            $selection = Read-Host -Prompt "Enter the number corresponding to the folder you want to add to PATH (or '0' to skip)"
            try {
                $selection = [int]$selection
            } catch {
                Write-Color -Message "DEBUG: Invalid input. Please enter a valid number." -Color Red
                $selection = -1 # Reset selection to loop again
            }
        } while ($selection -lt 0 -or $selection -gt $exeFolders.Count)

        if ($selection -ne 0) {
            $selectedPath = $exeFolders[$selection - 1]
            Write-Color -Message "DEBUG: Selected folder to add to PATH: $selectedPath" -Color Green
            Add-PathItem -Directory $selectedPath -Verbose
        } else {
            Write-Color -Message "No folder added to PATH." -Color Green
        }
    } else {
        Write-Color -Message "DEBUG: No unique folders with executables found." -Color Red
    }
}

} else {
    Write-Color -Message "Skipping extraction and PATH addition because download failed." -Color Red
}

