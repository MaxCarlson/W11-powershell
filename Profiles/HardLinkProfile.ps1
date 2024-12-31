<#
.SYNOPSIS
    Creates a hard link for the PowerShell profile, with options to handle existing files.

.DESCRIPTION
    This script creates a hard link using cmd's `mklink` command. It handles existing files
    at the link location based on the provided options and backs up files to a timestamped
    folder before overwriting them.

.PARAMETER LinkPaths
    Array of paths where the hard link will be created. Defaults to common PowerShell profile paths.

.PARAMETER TargetPath
    Path to the target file for the hard link. Defaults to `CustomProfile.ps1` in the script directory.

.PARAMETER Replace
    Specifies how to handle an existing file at the link location:
        - `n`: Do not overwrite.
        - `y`: Overwrite with backup.
        - `a`: Overwrite without backup.

.EXAMPLE
    .\HardLinkProfile.ps1 -Replace y
#>

param (
    [string[]]$LinkPaths = @(
        "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1",
        "C:\Program Files\PowerShell\7\profile.ps1"
    ),
    [string]$TargetPath = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "CustomProfile.ps1"),
    [string]$Replace
)

# Function for colored output
function Write-Color {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    switch ($Color.ToLower()) {
        "red" { Write-Host $Message -ForegroundColor Red }
        "green" { Write-Host $Message -ForegroundColor Green }
        "yellow" { Write-Host $Message -ForegroundColor Yellow }
        default { Write-Host $Message }
    }
}

# Function to get a unique, timestamped backup path
function Get-UniqueBackupPath {
    param (
        [string]$Path
    )
    # Use $PSScriptRoot to reliably get the script's directory
    $directory = Join-Path -Path $PSScriptRoot -ChildPath "ProfileBackup"
    if (-not (Test-Path $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }
    $timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
    $filename = Split-Path -Leaf $Path
    return Join-Path -Path $directory -ChildPath "$timestamp-$filename"
}


# Ensure the target file exists
if (-not (Test-Path $TargetPath)) {
    Write-Color "The target file '$TargetPath' does not exist." -Color Red
    exit 1
}

# Process each link path
foreach ($LinkPath in $LinkPaths) {
    if (Test-Path $LinkPath) {
        Write-Color "A file already exists at the link location: $LinkPath" -Color Yellow

        if (-not $Replace) {
            # Prompt for user input if no flag was provided
            $Replace = Read-Host "Do you want to (n)ot erase, (y) erase & backup, or (a) erase without backup?"
        }

        switch ($Replace.ToLower()) {
            'n' {
                Write-Color "Operation aborted. No changes made." -Color Yellow
                exit 0
            }
            'y' {
                # Backup existing file
                $backupPath = Get-UniqueBackupPath -Path $LinkPath
                Copy-Item -Path $LinkPath -Destination $backupPath -Force
                Write-Color "Existing file backed up to: $backupPath" -Color Yellow
                Remove-Item -Path $LinkPath -Force
                Write-Color "Original file deleted: $LinkPath" -Color Yellow
            }
            'a' {
                # Remove without backup
                Remove-Item -Path $LinkPath -Force
                Write-Color "Existing file erased without backup." -Color Yellow
            }
            default {
                Write-Color "Invalid option. Operation aborted." -Color Red
                exit 1
            }
        }
    }

    # Use cmd to create the hard link
    $cmdCommand = "mklink /H `"$LinkPath`" `"$TargetPath`""
    Write-Color "Executing: $cmdCommand" -Color Yellow
    cmd /c $cmdCommand

    # Confirm success
    if (Test-Path $LinkPath) {
        Write-Color "Hard link created successfully: $LinkPath -> $TargetPath" -Color Green
    } else {
        Write-Color "Failed to create the hard link." -Color Red
    }
}

