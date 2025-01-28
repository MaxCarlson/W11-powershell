# This was designed as a sma ddbug fike flr clipboard issues

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

function Get-ClipboardContents {
    Write-Debug -Message "Getting Clipboard Contents:" -Channel "Information"

    $clipboardContent = Get-Clipboard -Raw | Out-String
    if ([string]::IsNullOrWhiteSpace($clipboardContent)) {
        Write-Debug -Message "Clipboard is empty." -Channel "Warning"
    } else {
        Write-Host $clipboardContent
        Write-Debug -Message "Clipboard Contents:`n$clipboardContent" -Channel "Success"
    }
}
