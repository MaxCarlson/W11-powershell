<#
.SYNOPSIS
    Creates a hard link using cmd's mklink command, with options to handle existing files.

.DESCRIPTION
    This script uses cmd's mklink command to create a hard link.
    If a file already exists at the hard link path, the script handles it based on the provided flags or user input.
    For backups, it ensures unique filenames by appending a numerical suffix if a file with the same name already exists.

.PARAMETER LinkPath
    The path where the hard link will be created.
    Defaults to the standard PowerShell profile path.

.PARAMETER TargetPath
    The path to the target file for the hard link.
    Defaults to "ProfileCUCH.ps1" in the script's directory.

.PARAMETER Replace
    Specifies how to handle an existing file at the link location.
    Acceptable values:
        - `n` (do not erase)
        - `y` (erase and save a backup)
        - `a` (erase without saving a backup)
    If not provided, the script prompts the user interactively.

.EXAMPLE
    .\HardLinkProfile.ps1 -r y

    Creates a hard link, erasing the existing file and saving a unique backup.

.EXAMPLE
    .\HardLinkProfile.ps1 -r n

    Creates a hard link but aborts if a file already exists.
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$LinkPaths = @("$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1", "C:\Program Files\PowerShell\7\profile.ps1")

    [Parameter(Mandatory = $false)]
    [string]$TargetPath = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "ProfileCUCH.ps1"),

    [Parameter(Mandatory = $false, ParameterSetName = "Short")]
    [Alias("r")]
    [ValidateSet("n", "y", "a")]
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

# Function to get a unique backup file name
function Get-UniqueBackupPath {
    param (
        [string]$Path
    )
    $directory = Split-Path -Parent $Path
    $filename = Split-Path -Leaf $Path
    $basename = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    $extension = [System.IO.Path]::GetExtension($filename)
    $uniquePath = $Path
    $counter = 1

    while (Test-Path $uniquePath) {
        $uniquePath = Join-Path -Path $directory -ChildPath "$basename($counter)$extension"
        $counter++
    }

    return $uniquePath
}



# Ensure the target file exists
if (-not (Test-Path $TargetPath)) {
    Write-Color "The target file '$TargetPath' does not exist." -Color Red
    exit 1
}

# Check if a file already exists at the link location
foreach ($LinkPath in $LinkPaths) {
    if (Test-Path $LinkPath) {
      Write-Color "A file already exists at the link location: $LinkPath" -Color Red

      if (-not $Replace) {
          # Interactive mode: Prompt for user input if no flag was set
          $Replace = Read-Host "Do you want to (n)ot erase, (y) erase & backup, or (a) erase without backup?"
      }

      # Handle based on user input or flag
      switch ($Replace.ToLower()) {
          'n' {
              Write-Color "Operation aborted. No changes made." -Color Yellow
              exit 0
          }
          'y' {
              # Save a unique backup
              $backupPath = Get-UniqueBackupPath -Path (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath (Split-Path -Leaf $LinkPath))
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
