<#
.SYNOPSIS
    Concatenates and prints the contents of files in a directory.

.DESCRIPTION
    By default, prints all .txt files in the current directory.
    Supports filtering by one or more extensions, explicit file lists,
    glob patterns, recursion, limiting lines per file, and a custom source folder.

.PARAMETER Extensions
    One or more file extensions (with or without leading “.”) to include. 
    Default is txt.

.PARAMETER Files
    One or more specific file paths or names to print. If relative, they are resolved
    under –Source.

.PARAMETER Pattern
    Glob-style file name filter (e.g. *.log or report-??.csv).

.PARAMETER Source
    Folder path from which to search or to resolve relative –Files. Defaults to “.”.

.PARAMETER Recursive
    If set, recurse into subdirectories when enumerating files.

.PARAMETER MaxLines
    Maximum number of lines to print from each file. If omitted, prints all lines.

.EXAMPLE
    # Default behavior: prints all .txt in .\
    .\CatFiles.ps1

.EXAMPLE
    # Print only .log and .md files under C:\Logs, recursing, max 20 lines each
    .\CatFiles.ps1 -Extensions log md -Source C:\Logs -Recursive -MaxLines 20

.EXAMPLE
    # Print two specific files (relative to C:\Data)
    .\CatFiles.ps1 -Files foo.csv bar.json -Source C:\Data

#>

[CmdletBinding()]
param(
    [Parameter()]
    [string[]] $Extensions = @("txt"),

    [Parameter()]
    [string[]] $Files,

    [Parameter()]
    [string] $Pattern,

    [Parameter()]
    [string] $Source = ".",

    [Parameter()]
    [switch] $Recursive,

    [Parameter()]
    [int] $MaxLines
)

# Normalize extensions (remove leading dots)
$NormalizedExts = $Extensions | ForEach-Object { $_.TrimStart('.') }

# Collect file info objects
$AllFiles = @()

if ($Files) {
    foreach ($f in $Files) {
        if ([System.IO.Path]::IsPathRooted($f)) {
            $path = $f
        } else {
            $path = Join-Path -Path $Source -ChildPath $f
        }
        if (Test-Path $path) {
            $AllFiles += Get-Item -Path $path -ErrorAction SilentlyContinue
        } else {
            Write-Warning "File not found: $path"
        }
    }
} else {
    $AllFiles = Get-ChildItem -Path $Source `
                              -Recurse:$Recursive.IsPresent `
                              -File
}

# Apply extension & pattern filters
$ToCat = $AllFiles | Where-Object {
    $ext = $_.Extension.TrimStart('.')
    ($NormalizedExts -contains $ext) -and
    (!$Pattern -or $_.Name -like $Pattern)
}

# Print each file with header/footer and count
[int] $count = 0
foreach ($file in $ToCat) {
    Write-Host "===>> ${file.FullName} <<==="

    if ($MaxLines) {
        Get-Content -Path $file.FullName -TotalCount $MaxLines
    } else {
        Get-Content -Path $file.FullName
    }

    "`n"  # blank line between files
    $count++
}

Write-Host "Total files printed: $count"
