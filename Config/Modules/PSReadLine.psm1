# Import guard so repeated profile imports do not register duplicate keybindings.
if (-not $script:ModuleImportedPSReadLine) {
    $script:ModuleImportedPSReadLine = $true
} else {
    return
}

if (-not (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) -or
    -not (Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue)) {
    return
}

# Makes up and down arrow cycle through text similar to bash
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Predictive Intellegence
try {
    if ($Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected) {
        Set-PSReadLineOption -PredictionSource History
    }
} catch {
    # Skip prediction if the host does not support it.
}

# Expand recognized cd* location macros in command position on Tab, preserving
# normal Tab completion for all other inputs.
if (-not $script:CdMacroTabHandlerRegistered) {
    $script:CdMacroTabHandlerRegistered = $true
    $existingTabHandler = Get-PSReadLineKeyHandler -Key Tab -ErrorAction SilentlyContinue | Select-Object -First 1
    $script:PreviousTabFunction = if ($existingTabHandler -and $existingTabHandler.Function -and $existingTabHandler.Function -ne 'Custom') {
        $existingTabHandler.Function
    } else {
        'TabCompleteNext'
    }

    Set-PSReadLineKeyHandler -Key Tab -BriefDescription 'ExpandCdMacroOrComplete' -LongDescription 'Expand cd* location macros in command position, otherwise run normal Tab completion' -ScriptBlock {
        param($key, $arg)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        $expansion = $null
        if (Get-Command Get-CdMacroExpansion -ErrorAction SilentlyContinue) {
            $expansion = Get-CdMacroExpansion -Line $line -Cursor $cursor
        }

        if ($expansion) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($expansion.StartOffset, $expansion.Length, $expansion.Replacement)
            return
        }

        $fallbackName = $script:PreviousTabFunction
        $psrlType = [Microsoft.PowerShell.PSConsoleReadLine]
        if ($fallbackName -and $psrlType.GetMethod($fallbackName)) {
            $psrlType::$fallbackName($key, $arg)
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext($key, $arg)
        }
    }
}

# Add command to history without executing
$parameters = @{
    Key = 'Alt+w'
    BriefDescription = 'SaveInHistory'
    LongDescription = 'Save current line in history but do not execute'
    ScriptBlock = {
        param($key, $arg)   # The arguments are ignored in this example

        # GetBufferState gives us the command line (with the cursor position)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        # AddToHistory saves the line in history, but does not execute it.
        [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)

        # RevertLine is like pressing Escape.
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    }
}
Set-PSReadLineKeyHandler @parameters
