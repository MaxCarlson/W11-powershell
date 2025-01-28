# ClipboardModule.psm1
$script:DEBUG_CLIPBOARD_MODULE=$false
$script:DEBUG_MODULE=$DEBUG_CLIPBOARD_MODULE -and $DebugProfile

<#
.SYNOPSIS
    Replaces the contents of a file with the current clipboard data.

.DESCRIPTION
    The Set-FileClipboard function takes the text data currently stored in the clipboard and
    writes it to the specified file, replacing any existing content. It then outputs the new
    contents of the file to the terminal.

.PARAMETER Path
    The full path to the file that should be overwritten with clipboard contents.

.EXAMPLE
    Set-FileClipboard -Path "C:\Users\Example\output.txt"

    Replaces the contents of "output.txt" with the clipboard's text data and displays the new file contents.

.EXAMPLE
    sfc "C:\Users\Example\notes.txt"

    Uses the alias "sfc" to replace "notes.txt" with clipboard data.

.NOTES
    - Ensure you want to replace the entire contents of the file before running this function.
    - Only works with text-based files.
    - If the clipboard is empty, the file will be overwritten with an empty string.

.LINK
    Set-FileClipboard
#>
function Set-FileClipboard {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    if (-Not (Test-Path $Path -PathType Leaf)) {
        Write-Host "Error: File '$Path' does not exist." -ForegroundColor Red
        return
    }

    $Content = Get-Content -Raw -Path $Path
    Write-Debug -Message $Content -Channel "Information" -Condition $DEBUG_MODULE # Display file contents
    $Content | Set-Clipboard
    Write-Debug -Message "Copied to clipboard." -Channel "Success"
}
Set-Alias -Name sfc -Value Set-FileClipboard

<#
.SYNOPSIS
    Retrieves the contents of a file, displays them, and copies them to the clipboard.

.DESCRIPTION
    The Get-FileClipboard function reads the contents of a specified file, outputs them to the terminal,
    and copies them to the clipboard. This allows for quick copying and pasting of file contents
    without modifying the file.

.PARAMETER Path
    The full path to the file whose contents should be copied.

.EXAMPLE
    Get-FileClipboard -Path "C:\Users\Example\document.txt"

    Retrieves the contents of "document.txt", displays them in the terminal, and copies them to the clipboard.

.EXAMPLE
    gfc "C:\Users\Example\script.ps1"

    Uses the alias "gfc" to copy the contents of "script.ps1" to the clipboard.

.NOTES
    - This function only works with text-based files.
    - Ensure that the file exists before running this function.

.LINK
    Get-FileClipboard
#>
function Get-FileClipboard {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    if (-Not (Test-Path $Path -PathType Leaf)) {
        Write-Debug -Message "Error: File '$Path' does not exist." -Channel "Error" -Condition $true
        return
    }

    $ClipboardContent = Get-Clipboard
    $ClipboardContent | Set-Content -Path $Path
    Write-Debug -Message $ClipboardContent -Channel "Information" -Condition $DEBUG_MODULE  # Display new contents
    Write-Debug "Replaced contents of '$Path' with clipboard data." -Channel "Success" -Condition $true
}
Set-Alias -Name gfc -Value Get-FileClipboard

<#
.SYNOPSIS
    Appends the current clipboard content to the specified text file.

.DESCRIPTION
    This function retrieves the text data currently stored in the clipboard and appends it to a specified file. 
    It ensures that clipboard formatting is preserved by writing the content to a temporary file before appending.
    If the target file does not end with a newline, a newline is added to separate the new content properly.

.PARAMETER FilePath
    Specifies the full path of the text file where the clipboard content will be appended.

.EXAMPLE
    Add-ClipboardToFile -FilePath "C:\Users\Public\example.txt"

    Appends the current clipboard content to 'example.txt' while ensuring correct formatting.

.EXAMPLE
    actf "C:\Users\Public\log.txt"

    Uses the alias "actf" to append clipboard content to 'log.txt'.

.NOTES
    - This function is intended for text-based files only.
    - If the clipboard is empty or contains only whitespace, no changes will be made.
    - The function ensures that the existing content of the file is not overwritten, only appended.

.LINK
    Get-Clipboard
    Set-Clipboard
#>
function Add-ClipboardToFile {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    $tempFilePath = [System.IO.Path]::GetTempFileName()

    try {
        $clipboardContent = Get-Clipboard
        if (-not [string]::IsNullOrWhiteSpace($clipboardContent)) {
            # Write clipboard content to a temporary file
            $clipboardContent | Set-Content -Path $tempFilePath

            # Append a newline to the target file if it doesn't end with one
            $fileContent = Get-Content -Path $FilePath -Raw
            if (-not [string]::IsNullOrWhiteSpace($fileContent) -and -not $fileContent.EndsWith("`n")) {
                Add-Content -Path $FilePath -Value "`n"
            }

            # Append the temporary file content to the target file
            Get-Content -Path $tempFilePath | Add-Content -Path $FilePath
        } else {
            Write-Warning "Clipboard is empty or contains only whitespace."
        }
    } finally {
        # Clean up temporary file
        Remove-Item -Path $tempFilePath -Force
    }
}

Set-Alias -Name actf -Value Add-ClipboardToFile
