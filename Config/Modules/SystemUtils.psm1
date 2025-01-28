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

<#
.SYNOPSIS
    Ensures a specified directory is in the user's or system's PATH.

.DESCRIPTION
    Checks if the given directory is already in the PATH; if not, adds it to either the user or system PATH.

.PARAMETER PathToAdd
    The directory to add to the PATH.

.PARAMETER System
    If specified, adds the directory to the system PATH instead of the user PATH.
#>
function Set-PathVariable {
    param(
        [Parameter(Mandatory = $true)] [string]$PathToAdd,
        [switch]$System
    )
    
    $scope = if ($System) { "Machine" } else { "User" }
    $currentPath = [System.Environment]::GetEnvironmentVariable("Path", $scope)
    
    if ($currentPath -eq $null -or $currentPath -match "^$") {
        Write-Debug -Message "ERROR: Current $scope PATH is null. Aborting to prevent corruption." -Channel "Error"
        exit 1
    }
    
    if ($currentPath -match "(^|;)$([regex]::Escape($PathToAdd))(;|$)") {
        Write-Debug -Message "$PathToAdd is already in $scope PATH." -Channel "Success"
        return
    }
    
    try {
        Write-Debug -Message "Adding $PathToAdd to $scope PATH" -Channel "Info"
        $newPath = "$currentPath;$PathToAdd"
        [System.Environment]::SetEnvironmentVariable("Path", $newPath, $scope)
        Write-Debug -Message "Added $PathToAdd to $scope PATH. Restart your shell to apply changes." -Channel "Success"
    } catch {
        Write-Debug -Message "Failed to modify $scope PATH. Ensure you have proper permissions." -Channel "Error"
    }
}

function Get-PathVariables {
    param(
        [switch]$System,
        [switch]$Both,
        [switch]$Compressed=$false
    )
    function Write-Path {
        param(
            [string]$path,
            [switch]$Compressed
        )
        if($Compressed){
            $path
        } else {
            $path -split ";"
        }
    }

    if ($Both){
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-Debug -Message "Getting System & User PATH's..."
        Write-Debug -Message "Getting User (${User}) PATH..." 
        Write-Path $userPath -Compressed $Compressed
        $System = $true
    } 
    if ($System){
        Write-Debug -Message "Getting System PATH..."
    } else {
        Write-Debug -Message "Getting User (${User}) PATH..."
    }
    
    $scope = if ($System) { "Machine" } else { "User" }
    $currentPath = [System.Environment]::GetEnvironmentVariable("Path", $scope)
    Write-Path $currentPath -Compressed $Compressed

}

Export-ModuleMember -Function New-FileLink, Set-PathVariable, Get-PathVariables

