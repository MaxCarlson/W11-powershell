<#
.SYNOPSIS
    Creates a hard link for the PowerShell profile, with options to handle existing files.

.DESCRIPTION
    This script creates a hard link using cmd's `mklink` command. It handles existing files
    at the link location based on the provided options and backs up files to a timestamped
    folder before overwriting them. If the target and link files are identical, the script skips replacement.

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

# Import DebugUtils module (assumes it's available in $PSScriptRoot/../Config/Modules/)
$DebugUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath "../Config/Modules/DebugUtils.psm1"
if (Test-Path $DebugUtilsPath) {
    Import-Module $DebugUtilsPath -Force
} else {
    Write-Host "⚠️ DebugUtils module not found at: $DebugUtilsPath" -ForegroundColor Yellow
}

# Function to compare two files by hash
function FilesAreIdentical {
    param (
        [string]$File1,
        [string]$File2
    )

    if (!(Test-Path $File1) -or !(Test-Path $File2)) {
        return $false  # If either file does not exist, they are not identical
    }

    $hash1 = (Get-FileHash -Path $File1 -Algorithm SHA256).Hash
    $hash2 = (Get-FileHash -Path $File2 -Algorithm SHA256).Hash

    return $hash1 -eq $hash2
}

# Function to get a unique, timestamped backup path
function Get-UniqueBackupPath {
    param (
        [string]$Path
    )
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
    Write-Debug -Message "❌ The target file '$TargetPath' does not exist." -Channel "Error"
    exit 1
}

# Process each link path
foreach ($LinkPath in $LinkPaths) {

    # Skip linking if the files are already identical
    if (FilesAreIdentical -File1 $LinkPath -File2 $TargetPath) {
        Write-Debug -Message "✅ Skipping: '$LinkPath' already links to an identical profile." -Channel "Success"
        continue
    }

    if (Test-Path $LinkPath) {
        Write-Debug -Message "⚠️ A file already exists at: $LinkPath" -Channel "Warning"

        if (-not $Replace) {
            # Prompt for user input if no flag was provided
            $Replace = Read-Host "Do you want to (n)ot erase, (y) erase & backup, or (a) erase without backup?"
        }

        switch ($Replace.ToLower()) {
            'n' {
                Write-Debug -Message "⏩ Operation aborted. No changes made." -Channel "Warning"
                continue
            }
            'y' {
                # Backup existing file
                $backupPath = Get-UniqueBackupPath -Path $LinkPath
                Copy-Item -Path $LinkPath -Destination $backupPath -Force
                Write-Debug -Message "📂 Backup created at: $backupPath" -Channel "Information"
                Remove-Item -Path $LinkPath -Force
                Write-Debug -Message "🗑️ Original file deleted: $LinkPath" -Channel "Information"
            }
            'a' {
                # Remove without backup
                Remove-Item -Path $LinkPath -Force
                Write-Debug -Message "❗ Existing file erased without backup." -Channel "Warning"
            }
            default {
                Write-Debug -Message "❌ Invalid option. Operation aborted." -Channel "Error"
                exit 1
            }
        }
    }

    # Use cmd to create the hard link
    $cmdCommand = "mklink /H `"$LinkPath`" `"$TargetPath`""
    Write-Debug -Message "🔗 Executing: $cmdCommand" -Channel "Debug"
    cmd /c $cmdCommand

    # Confirm success
    if (Test-Path $LinkPath) {
        Write-Debug -Message "✅ Hard link created successfully: $LinkPath -> $TargetPath" -Channel "Success"
    } else {
        Write-Debug -Message "❌ Failed to create the hard link." -Channel "Error"
    }
}

