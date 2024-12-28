function New-Link {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$SourcePaths,

        [Parameter(Mandatory = $true)]
        [string]$DestinationFolder,

        [Parameter(Mandatory = $false)]
        [string[]]$LinkNames = @(),

        [switch]$Symbolic,  # Default behavior
        [switch]$Hard
    )

    # Default to symbolic if no flag is provided
    if (-not $Symbolic -and -not $Hard) {
        $Symbolic = $true
    }

    # Validate link type
    if ($Symbolic -and $Hard) {
        Write-Error "Error: Both -Symbolic and -Hard flags cannot be specified simultaneously."
        return
    }

    $itemType = if ($Hard) { "HardLink" } else { "SymbolicLink" }

    # Ensure the destination folder exists
    Write-Host "Ensuring destination folder exists..." -ForegroundColor Yellow
    if (-not (Test-Path $DestinationFolder)) {
        Write-Host "Creating destination folder: $DestinationFolder" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $DestinationFolder | Out-Null
    }

    # Process each source path for creating links
    Write-Host "Processing source paths for link creation..." -ForegroundColor Yellow
    for ($i = 0; $i -lt $SourcePaths.Count; $i++) {
        $source = $SourcePaths[$i]
        $linkName = if ($LinkNames.Count -gt $i) { $LinkNames[$i] } else { Split-Path -Leaf $source }
        $linkPath = Join-Path -Path $DestinationFolder -ChildPath $linkName

        if ($Hard -and (Test-Path $source -PathType Container)) {
            Write-Error "Error: Hard links cannot be created for directories. Skipping: $source"
            continue
        }

        Write-Host "Creating $itemType link - $linkPath -> $source" -ForegroundColor Green
        try {
            New-Item -ItemType $itemType -Path $linkPath -Target $source -Force
            Write-Host "$itemType link created: $linkPath -> $source" -ForegroundColor Green
        } catch {
            Write-Error "Failed to create $itemType link for $source. Error: $_"
        }
    }

    Write-Host "Operation completed successfully!" -ForegroundColor Green
}

function Remove-Link {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,  # Path to a link or directory containing multiple links

        [switch]$Symbolic,  # Optional flag to target symbolic links
        [switch]$Hard,      # Optional flag to target hard links
        [switch]$Force      # Auto-confirm deletion without user prompt
    )

    # Validate link type and autodetect if no flag is provided
    if (-not $Symbolic -and -not $Hard) {
        $item = Get-Item $Path
        if ($item.Attributes -contains "ReparsePoint") {
            $Symbolic = $true
        } else {
            $Hard = $true
        }
    }

    if ($Symbolic -and $Hard) {
        Write-Error "Error: Both -Symbolic and -Hard flags cannot be specified simultaneously."
        return
    }

    # Check if the path exists
    if (-not (Test-Path $Path)) {
        Write-Error "Error: The specified path '$Path' does not exist."
        return
    }

    # Handle directory containing multiple links
    if ((Get-Item $Path).PSIsContainer) {
        $items = Get-ChildItem -Path $Path | Where-Object {
            if ($Symbolic) { $_.Attributes -contains "ReparsePoint" }
            elseif ($Hard) { -not ($_.Attributes -contains "ReparsePoint") }
        }

        $linkCount = $items.Count
        if ($linkCount -eq 0) {
            Write-Host "No $($Symbolic ? "symbolic" : "hard") links found in the specified directory." -ForegroundColor Yellow
            return
        }

        Write-Host "Found $linkCount $($Symbolic ? "symbolic" : "hard") links:" -ForegroundColor Cyan
        $items | ForEach-Object { Write-Host " - $_" }

        if (-not $Force) {
            $confirmation = Read-Host "Are you sure you want to delete these links? (y/n)"
            if ($confirmation -notin @("y", "Y")) {
                Write-Host "Operation canceled." -ForegroundColor Yellow
                return
            }
        }

        Write-Host "Deleting links..." -ForegroundColor Yellow
        foreach ($item in $items) {
            try {
                Remove-Item -Path $item.FullName -Force
                Write-Host "Deleted: $item" -ForegroundColor Green
            } catch {
                Write-Error "Failed to delete $item. Error: $_"
            }
        }

        Write-Host "Operation completed." -ForegroundColor Green
        return
    }

    # Handle a single link
    $item = Get-Item $Path
    if ($Symbolic) {
        if ($item.Attributes -notcontains "ReparsePoint") {
            Write-Error "Error: The specified path '$Path' is not a symbolic link."
            return
        }
    }

    if ($Hard) {
        $hardlinkCount = $item.HardLinkCount
        if ($hardlinkCount -eq 1 -and -not $Force) {
            $confirmation = Read-Host "This appears to be the last hardlink reference to the file. Are you sure you want to delete it? (y/n)"
            if ($confirmation -notin @("y", "Y")) {
                Write-Host "Skipping deletion of $Path" -ForegroundColor Yellow
                return
            }
        }
    }

    # Remove the link
    try {
        Remove-Item -Path $Path -Force
        Write-Host "Deleted $($Symbolic ? "symbolic link" : "hard link"): $Path" -ForegroundColor Green
    } catch {
        Write-Error "Failed to delete $($Symbolic ? "symbolic link" : "hard link"): $Path. Error: $_"
    }
}

