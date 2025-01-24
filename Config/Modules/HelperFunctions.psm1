function Get-LinesOfOutput {
    <#
    .SYNOPSIS
    Counts the number of lines in the output of a PowerShell command.

    .DESCRIPTION
    This function executes a command and counts the number of lines in its output, 
    helping to quickly assess the amount of data returned.

    .PARAMETER Command
    The command whose output will be counted.

    .EXAMPLE
    Get-LinesOfOutput -Command "Get-Process"

    Counts the number of lines in the output of Get-Process.

    .NOTES
    Author: Your Name
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Command
    )

    Invoke-Expression $Command | Measure-Object -Line | Select-Object -ExpandProperty Lines
}
Set-Alias -Name clo -Value Get-LinesOfOutput

function Get-FileCount {
    <#
    .SYNOPSIS
    Counts the number of files in a specified directory.

    .PARAMETER Path
    The path to the directory.

    .EXAMPLE
    Get-FileCount -Path "C:\Users\Public"

    Counts the number of files in the Public folder.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    (Get-ChildItem -Path $Path -File).Count
}
Set-Alias -Name gfc -Value Get-FileCount

function Get-MatchingFileCount {
    <#
    .SYNOPSIS
    Counts the number of files matching a specified pattern in a directory.

    .PARAMETER Path
    The path to the directory.

    .PARAMETER Pattern
    The pattern to match files against.

    .EXAMPLE
    Get-MatchingFileCount -Path "C:\Users\Public" -Pattern "*.txt"

    Counts the number of .txt files in the Public folder.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$Pattern
    )

    (Get-ChildItem -Path $Path -File -Filter $Pattern).Count
}
Set-Alias -Name gmfc -Value Get-MatchingFileCount

function Get-DirectorySize {
    <#
    .SYNOPSIS
    Calculates the total size of files in a directory matching a specified pattern, optionally including subdirectories.

    .DESCRIPTION
    This function sums the sizes of all files that match a specific pattern in a directory. It can also recurse into subdirectories if specified.

    .PARAMETER Path
    The path to the directory where files are located.

    .PARAMETER Pattern
    The pattern to match files against (e.g., *.txt). Use the -p or -Pattern parameter to specify the pattern.

    .PARAMETER Recursive
    Specifies whether the size calculation should include subdirectories. Use the -r or -Recursive switch for recursive search.

    .EXAMPLE
    Get-DirectorySize -Path "C:\Users\Public" -Pattern "*.txt" -Recursive

    Calculates the total size of all .txt files in the Public folder, including those in subdirectories.

    .NOTES
    Author: Your Name
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [Alias('p')]
        [string]$Pattern,

        [Parameter(Mandatory=$false)]
        [Alias('r')]
        [switch]$Recursive
    )

    $searchOption = [System.IO.SearchOption]::TopDirectoryOnly
    if ($Recursive) {
        $searchOption = [System.IO.SearchOption]::AllDirectories
    }

    $files = Get-ChildItem -Path $Path -Filter $Pattern -File -Recurse:$Recursive
    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
    [PSCustomObject]@{
        Path = $Path
        Pattern = $Pattern
        Recursive = $Recursive
        TotalSize = $totalSize
        TotalSizeMB = [math]::Round($totalSize / 1MB, 2)
        TotalSizeGB = [math]::Round($totalSize / 1GB, 2)
    }
}
Set-Alias -Name gds -Value Get-DirectorySize


function Show-FileDiff {
    <#
    .SYNOPSIS
    Compares two files using git diff, independent of their current git repository status.

    .DESCRIPTION
    This function creates a temporary Git repository to compare two files using git diff.
    It handles files whether they are tracked by Git or not.

    .PARAMETER File1
    The full path to the first file to compare.

    .PARAMETER File2
    The full path to the second file to compare.

    .EXAMPLE
    Show-FileDiff -File1 "C:\path\to\file1.txt" -File2 "C:\path\to\file2.txt"

    Compares file1.txt and file2.txt using git diff.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$File1,
        [Parameter(Mandatory=$true)]
        [string]$File2
    )

    # Resolve the absolute paths for the files
    $resolvedFile1 = Resolve-Path -Path $File1
    $resolvedFile2 = Resolve-Path -Path $File2

    # Create a temporary directory for the git repository
    $tempRepoPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tempRepoPath -Force | Out-Null
    Push-Location -Path $tempRepoPath

    try {
        # Initialize a new git repository
        git init > $null

        # Copy files into this temporary repository
        $tempFile1 = "temp_file1"
        $tempFile2 = "temp_file2"
        Copy-Item -Path $resolvedFile1 -Destination $tempFile1
        Copy-Item -Path $resolvedFile2 -Destination $tempFile2

        # Stage the files to include them in git diff
        git add $tempFile1 $tempFile2 > $null
        git commit -m "Initial commit for diff" > $null

        # Output git diff
        git diff --no-index $tempFile1 $tempFile2
    }
    finally {
        # Clean up
        Pop-Location
        Remove-Item $tempRepoPath -Recurse -Force
    }
}
Set-Alias -Name sfd -Value Show-FileDiff

