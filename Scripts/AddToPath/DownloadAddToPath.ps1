param (
    [Parameter(Mandatory = $false)]
    [string]$Url,                        # URL to download, optional

    [Parameter(Mandatory = $false)]
    [string]$DownloadPath,               # File download destination, optional

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

# Step 1: Download the file if URL is provided and DownloadPath is specified
$downloadSuccess = $false
if ($Url) {
    if (!$DownloadPath) {
        Write-Color -Message "URL provided but no download path specified. Cannot proceed with download." -Type "Error"
        return
    }
    if (-not (Test-Path -Path $DownloadPath) -or $OverwriteDownload) {
        $downloadSuccess = Get-File -Url $Url -DestinationPath $DownloadPath -Overwrite:$OverwriteDownload
        Write-Color -Message "Download Success: $downloadSuccess" -Type "Success"
    } else {
        Write-Color -Message "File already exists at $DownloadPath. Skipping download." -Type "Warning"
        $downloadSuccess = $true
    }
} elseif ($DownloadPath) {
    if (Test-Path -Path $DownloadPath) {
        Write-Color -Message "File found at $DownloadPath. Proceeding without download." -Type "Info"
        $downloadSuccess = $true
    } else {
        Write-Color -Message "Download path specified but file does not exist and no URL provided. Cannot proceed." -Type "Error"
        return
    }
}

# Step 2: Extract the file if download succeeded or if file was already present or if no download is needed
$extractSuccess = $false
if ($downloadSuccess -or -not $DownloadPath) {
    if ($DownloadPath) {
        if (-not (Test-Path -Path $ExtractPath) -or $OverwriteExtract) {
            $extractSuccess = Expand-CustomArchive -ArchivePath $DownloadPath -DestinationPath $ExtractPath -Overwrite:$OverwriteExtract
            Write-Color -Message "Extract Success: $extractSuccess" -Type "Success"
        } else {
            Write-Color -Message "Folder already exists at $ExtractPath. Skipping extraction." -Type "Warning"
            $extractSuccess = $true
        }
    } else {
        Write-Color -Message "No download path provided; using extraction path to search for executables." -Type "Info"
        $extractSuccess = $true
    }

    # Step 3: Add the directory to PATH if AddToPath is set and extraction or file detection was successful
    if ($AddToPath -and $extractSuccess) {
        Write-Color -Message "Starting to search for .exe files in $ExtractPath" -Type "Info"

        # Step 1: Collect all .exe files
        try {
            $exeFiles = Get-ChildItem -Path $ExtractPath -Recurse -Filter '*.exe' -ErrorAction Stop
            Write-Color -Message "Found $($exeFiles.Count) .exe file(s)." -Type "Success"

            if ($exeFiles.Count -eq 0) {
                Write-Color -Message "No .exe files found in the directory tree." -Type "Error"
            } else {
                Write-Color -Message "Listing all .exe files found:" -Type "Info"
                foreach ($exeFile in $exeFiles) {
                    Write-Color -Message "File Path: $($exeFile.FullName)" -Type "Warning"
                    Write-Color -Message "Containing Directory: $($exeFile.DirectoryName)" -Type "Warning"
                }
            }
        } catch {
            Write-Color -Message "Error during Get-ChildItem: $_" -Type "Error"
            return
        }

        # Step 2: Extract unique directories containing executables
        try {
            $exeFolders = $exeFiles | ForEach-Object {
                $dir = $_.DirectoryName
                if ([string]::IsNullOrWhiteSpace($dir)) {
                    Write-Color -Message "Skipping empty directory for file -> $($_.FullName)" -Type "Error"
                    continue
                }
                if (Test-Path -Path $dir) {
                    Write-Color -Message "Adding valid directory -> $dir" -Type "Info"
                    $dir
                } else {
                    Write-Color -Message "Skipping invalid directory -> $dir" -Type "Error"
                }
            } | Sort-Object -Unique

            if ($exeFolders.Count -eq 0) {
                Write-Color -Message "No valid directories containing executables were identified." -Type "Error"
            } else {
                Write-Color -Message "Unique directories containing executables:" -Type "Info"
                foreach ($folder in $exeFolders) {
                    Write-Color -Message "$folder" -Type "Warning"
                }
            }
        } catch {
            Write-Color -Message "Error during unique directory collection: $_" -Type "Error"
            return
        }

        # Step 3: Prompt the user if folders were found and allow multiple selections
        if ($exeFolders.Count -gt 0) {
            Write-Color -Message "Found the following folders containing executables:" -Type "Success"

            # Ensure $exeFolders is treated as an array
            $exeFolders = @($exeFolders)

            for ($i = 0; $i -lt $exeFolders.Count; $i++) {
                Write-Color -Message "$($i + 1). $($exeFolders[$i])" -Type "Info"
            }

     	    # Prompt user for selection
     	    do {
     	        $selectionInput = Read-Host -Prompt "Enter the numbers corresponding to the folders you want to add to PATH (comma-separated, e.g., '1, 2' or '0' to skip)"
     	        $selections = $selectionInput -split ',' | ForEach-Object { $_.Trim() }
     	        $validSelections = $selections | Where-Object { $_ -and ($_ -match '^\d+$') -and ([int]$_ -le $exeFolders.Count) -and ([int]$_ -gt 0) }
     
     	        if ($validSelections.Count -gt 0) {
     	    	foreach ($selection in $validSelections) {
     	    	    $selectedPath = $exeFolders[[int]$selection - 1]
     	    	    Write-Color -Message "Selected folder to add to PATH: $selectedPath" -Type "Success"
     	    	    Add-PathItem -Directory $selectedPath -Verbose
     	    	}
     	        } elseif ($selectionInput -eq '0') {
     	    	Write-Color -Message "No folder added to PATH." -Type "Success"
     	        } else {
     	    	Write-Color -Message "Invalid input. Please enter valid numbers." -Type "Error"
     	    	$selectionInput = $null # Reset the input to continue prompting
     	        }
     	    } while (-not $selectionInput)
		    
        } else {
            Write-Color -Message "No unique folders with executables found." -Type "Error"
        }
    }
} else {
    Write-Color -Message "Skipping extraction and PATH addition because no file is available for processing and no URL was provided." -Type "Error"
}

