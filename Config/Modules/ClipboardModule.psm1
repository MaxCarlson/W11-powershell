# ClipboardModule.psm1

$script:DEBUG_CLIPBOARD_MODULE = $false
$script:DEBUG_MODULE = $DEBUG_CLIPBOARD_MODULE -and $DebugProfile

# Ensure backup folder exists
$backupFolder = "$HOME/logs/Clipboard"
if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder | Out-Null
}

<#
.SYNOPSIS
    Prints the contents of the clipboard to the terminal.
.DESCRIPTION
    Retrieves the current clipboard contents and prints them to the terminal.
.EXAMPLE
    Get-ClipboardContents
#>
function Get-ClipboardContents {
    Write-Debug -Message "Getting Clipboard Contents:" -Channel "Information"

    $clipboardContent = Get-Clipboard -Raw
    if ([string]::IsNullOrWhiteSpace($clipboardContent)) {
        Write-Debug -Message "Clipboard is empty." -Channel "Warning"
    } else {
        Write-Host $clipboardContent
        Write-Debug -Message "Clipboard Contents:`n$clipboardContent" -Channel "Success"
    }
}
Set-Alias -Name gcb -Value Get-ClipboardContents

<#
.SYNOPSIS
    Sets the clipboard to a given string or file contents.
.DESCRIPTION
    Accepts either a string input or a file path and sets the clipboard content accordingly.
.PARAMETER InputData
    A string or file path to set as the clipboard content.
.EXAMPLE
    Set-ClipboardContent -InputData "Hello, World!"
.EXAMPLE
    Set-ClipboardContent -InputData "C:\path\to\file.txt"
#>
function Set-ClipboardContent {
    param(
        [Parameter(Mandatory=$true)]
        [string]$InputData
    )

    # Initialize clipboard data variable
    $ClipboardData = $null

    # Handle input source (File or String)
    if (Test-Path $InputData -PathType Leaf) {
        Write-Debug -Message "Reading file: $InputData" -Channel "Information"
        $ClipboardData = Get-Content -Raw -Path $InputData
    } else {
        Write-Debug -Message "Processing text input." -Channel "Information"
        $ClipboardData = $InputData
    }

    if ($null -eq $InputData -or [string]::IsNullOrWhiteSpace($InputData)) {
        Write-Debug -Message "Error: Input content is empty, skipping operation." -Channel "Error"
        return
    }

    # Validate clipboard content
    if ($null -eq $ClipboardData -or [string]::IsNullOrWhiteSpace($ClipboardData)) {
        Write-Debug -Message "Error: Clipboard content is empty, skipping operation." -Channel "Error"
        return
    }

    # Normalize text formatting
    $ClipboardData = $ClipboardData -replace "`r", ""  # Remove carriage returns
    $ClipboardData = $ClipboardData.Trim()             # Remove leading/trailing spaces

    # Try setting clipboard content
    try {
        Set-Clipboard -Value $ClipboardData
        Start-Sleep -Milliseconds 100  # Ensure clipboard registers new content
        Write-Debug -Message "Clipboard successfully updated." -Channel "Success"
    } catch {
        Write-Debug -Message "Set-Clipboard failed, falling back to Windows API." -Channel "Warning"
        Add-Type -TypeDefinition @"
            using System;
            using System.Windows.Forms;
            public class ClipboardHelper {
                public static void SetText(string text) {
                    if (!String.IsNullOrEmpty(text)) {
                        Clipboard.SetText(text);
                    }
                }
            }
"@ -ReferencedAssemblies System.Windows.Forms
        [ClipboardHelper]::SetText($ClipboardData)
    }

    # Confirm clipboard content after setting
    $VerifyClipboard = Get-Clipboard -Raw
    if ($VerifyClipboard -eq $ClipboardData) {
        Write-Debug -Message "Clipboard verification successful." -Channel "Success"
    } else {
        Write-Debug -Message "Clipboard verification failed, unexpected content stored." -Channel "Warning"
    }
}
Set-Alias -Name scb -Value Set-ClipboardContent

<#
.SYNOPSIS
    Overwrites a file with the current clipboard content, creating a backup.
.DESCRIPTION
    If clipboard contains data, replaces file content while backing up the original to ~/logs/Clipboard/.
.PARAMETER Path
    The file to overwrite with clipboard contents.
.EXAMPLE
    Set-FileClipboard -Path "C:\Users\Example\output.txt"
#>
function Set-FileClipboard {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    if (-Not (Test-Path $Path -PathType Leaf)) {
        Write-Debug -Message "Error: File '$Path' does not exist." -Channel "Error"
        return
    }

    $clipboardContent = Get-Clipboard -Raw
    if ([string]::IsNullOrWhiteSpace($clipboardContent)) {
        Write-Debug -Message "Clipboard is empty, no changes made." -Channel "Warning"
        return
    }

    # Get file info before modification
    $oldSize = (Get-Item $Path).Length / 1KB
    $oldLines = (Get-Content -Path $Path).Count

    # Create backup before overwriting
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $backupPath = "$backupFolder/$(Split-Path -Leaf $Path)_$timestamp"
    Copy-Item -Path $Path -Destination $backupPath -Force
    Write-Debug -Message "Backed up '$Path' to '$backupPath'" -Channel "Information"

    # Overwrite file with clipboard contents
    $clipboardContent | Set-Content -Path $Path

    # Get file info after modification
    $newSize = (Get-Item $Path).Length / 1KB
    $newLines = (Get-Content -Path $Path).Count

    Write-Debug -Message @"
File Info: (Length: $oldLines lines, Size: $([math]::Round($oldSize,2)) KB)
Overwriting file '$Path' with contents of clipboard...
File Info After Overwrite: (Length: $newLines lines, Size: $([math]::Round($newSize,2)) KB)
"@ -Channel "Success"
}
Set-Alias -Name sfc -Value Set-FileClipboard

<#
.SYNOPSIS
    Appends clipboard content to a file.
.DESCRIPTION
    If clipboard contains data, appends it to the target file, ensuring proper formatting.
.PARAMETER FilePath
    The file to append clipboard contents to.
.EXAMPLE
    Add-ClipboardToFile -FilePath "C:\Users\Example\log.txt"
#>
function Add-ClipboardToFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    $clipboardContent = Get-Clipboard -Raw
    if ([string]::IsNullOrWhiteSpace($clipboardContent)) {
        Write-Debug -Message "Clipboard is empty or contains only whitespace. No changes made." -Channel "Warning"
        return
    }

    # Ensure file exists
    if (-Not (Test-Path $FilePath -PathType Leaf)) {
        Write-Debug -Message "Creating new file: $FilePath" -Channel "Information"
        New-Item -Path $FilePath -ItemType File | Out-Null
    }

    # Get file info before modification
    $oldContent = Get-Content -Path $FilePath -Raw
    $oldLines = ($oldContent -split "`n").Count
    $oldSize = (Get-Item $FilePath).Length / 1KB

    # Ensure newline separation
    if (-not [string]::IsNullOrWhiteSpace($oldContent) -and -not $oldContent.EndsWith("`n")) {
        "`n" | Add-Content -Path $FilePath
    }

    # Append clipboard contents
    $clipboardContent | Add-Content -Path $FilePath

    # Get file info after modification
    $newContent = Get-Content -Path $FilePath -Raw
    $newLines = ($newContent -split "`n").Count
    $newSize = (Get-Item $FilePath).Length / 1KB

    Write-Debug -Message @"
Appending clipboard to end of '$FilePath'
(Old EOF line: $oldLines, New EOF line: $newLines, Size Before: $([math]::Round($oldSize,2)) KB, Size After: $([math]::Round($newSize,2)) KB)
"@ -Channel "Success"
}
Set-Alias -Name actf -Value Add-ClipboardToFile

# Export functions and aliases
Export-ModuleMember -Function Get-ClipboardContents, Set-ClipboardContent, Set-FileClipboard, Add-ClipboardToFile -Alias gcb, scb, sfc, actf
