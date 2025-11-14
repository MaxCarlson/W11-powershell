<#
.SYNOPSIS
    (Re)create a hard link for your PowerShell CurrentUserCurrentHost profile.

.DESCRIPTION
    This script creates or replaces a hard link at
      $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
    pointing to your repo’s CustomProfile.ps1.  It avoids touching any
    system profiles under Program Files, so you won’t double-load.

.PARAMETER LinkPath
    The profile path to link. Defaults to the CurrentUserCurrentHost path.

.PARAMETER TargetPath
    The file you want your profile link to point at. Defaults to
      <script dir>\CustomProfile.ps1

.PARAMETER Replace
    How to handle an existing file at the link location:
      - n : do nothing (abort)
      - y : backup then overwrite
      - a : overwrite without backup

.EXAMPLE
    .\HardLinkProfile.ps1
    # ensures your Documents\PowerShell profile is hard-linked to your CustomProfile

.EXAMPLE
    .\HardLinkProfile.ps1 -Replace y
    # backs up any existing profile, then recreates the link
#>

param(
    [string]$LinkPath   = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1",
    [string]$TargetPath = (Join-Path $PSScriptRoot 'CustomProfile.ps1'),
    [ValidateSet('n','y','a')][string]$Replace
)

function Write-Color {
    param([string]$Message, [ConsoleColor]$Color = 'White')
    Write-Host $Message -ForegroundColor $Color
}

function Get-BackupPath {
    param([string]$Path)
    $dir       = Join-Path $PSScriptRoot 'ProfileBackup'
    (New-Item -Path $dir -ItemType Directory -Force) | Out-Null
    $timeStamp = (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')
    $name      = Split-Path $Path -Leaf
    return Join-Path $dir "$timeStamp-$name"
}

# ensure target exists
if (-not (Test-Path $TargetPath)) {
    Write-Color "ERROR: Cannot find target file:`n  $TargetPath" Red
    exit 1
}

# handle existing link/file
if (Test-Path $LinkPath) {
    Write-Color "A file already exists at:`n  $LinkPath" Yellow
    if (-not $Replace) {
        $Replace = Read-Host "Overwrite? (n=abort, y=backup+overwrite, a=overwrite w/o backup)"
    }
    switch ($Replace.ToLower()) {
        'n' {
            Write-Color 'Aborted, no changes.' Yellow
            exit 0
        }
        'y' {
            $backup = Get-BackupPath -Path $LinkPath
            Copy-Item -Path $LinkPath -Destination $backup -Force
            Write-Color "Backed up to: $backup" Yellow
            Remove-Item $LinkPath -Force
        }
        'a' {
            Remove-Item $LinkPath -Force
            Write-Color 'Existing file removed without backup.' Yellow
        }
        default {
            Write-Color 'Invalid choice; aborting.' Red
            exit 1
        }
    }
}

# create the hard link
$cmd = "mklink /H `"$LinkPath`" `"$TargetPath`""
Write-Color "Executing: $cmd" Yellow
cmd /c $cmd | Out-Null

if (Test-Path $LinkPath) {
    Write-Color "OK: Link created: $LinkPath -> $TargetPath" Green
} else {
    Write-Color "ERROR: Failed to create link." Red
    exit 1
}
