<#
.SYNOPSIS
    Provides utilities for file linking and PATH management.

.DESCRIPTION
    This module contains functions for creating hard or symbolic links for specified files
    and ensuring a given directory is in the user's or system's PATH.

#>

<#
.SYNOPSIS
    Creates either a hard link or a symbolic link for a given file.

.DESCRIPTION
    If -Symbolic is specified, a symbolic link is created; otherwise, a hard link is created.

.PARAMETER SourcePath
    The source file path for the link.

.PARAMETER TargetPath
    The target file path where the link will be created.

.PARAMETER Symbolic
    If specified, creates a symbolic link instead of a hard link.
#>
function New-FileLink {
    param(
        [Parameter(Mandatory = $true)] [string]$SourcePath,
        [Parameter(Mandatory = $true)] [string]$TargetPath,
        [switch]$Symbolic
    )
    
    if (Test-Path $TargetPath) {
        Write-Debug -Message "Target path $TargetPath already exists. Skipping creation." -Channel "Error"
        return
    }
    
    try {
        if ($Symbolic) {
            Write-Debug -Message "Creating symbolic link: $TargetPath -> $SourcePath" -Channel "Info"
            New-Item -ItemType SymbolicLink -Path $TargetPath -Target $SourcePath -ErrorAction Stop | Out-Null
        } else {
            Write-Debug -Message "Creating hard link: $TargetPath -> $SourcePath" -Channel "Info"
            New-Item -ItemType HardLink -Path $TargetPath -Target $SourcePath -ErrorAction Stop | Out-Null
        }
    } catch {
        Write-Debug -Message "Failed to create link: $TargetPath. Ensure permissions are correct." -Channel "Error"
    }
}

Export-ModuleMember -Function New-FileLink

