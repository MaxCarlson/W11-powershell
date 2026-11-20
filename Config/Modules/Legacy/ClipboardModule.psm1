# LEGACY MODULE — NOT LOADED AUTOMATICALLY
# - Superseded by Python `clipboard_tools` (`c2c`, `gcb`, `scb`, `pclip`, `cld`, `rwc`, `sfcb`, `apc`, `otc`, `cb2c`, `cb2cf`).
# - Retained temporarily for historical reference.
# - Not loaded automatically by ModuleLoader.psm1 (located under Config/Modules/Legacy/).
# - Not intended for normal interactive sessions.

# pwsh/ClipboardModule.psm1

# Requires your setup to have put bin/ on PATH so the wrappers exist.
# Commands used below: print_clipboard, set_clipboard_text, copy_to_clipboard,
#                      replace_with_clipboard, append_clipboard, output_to_clipboard

function Get-ClipboardContents {
    [CmdletBinding()]
    param()
    # Print the clipboard via Python (consistent stats/formatting)
    print_clipboard --no-stats
}
Set-Alias -Name gcb -Value Get-ClipboardContents

function Set-ClipboardContent {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [string[]]$InputArgs,
        [switch]$Append
    )
    if (-not $InputArgs -or $InputArgs.Count -eq 0) {
        Write-Error "Set-ClipboardContent requires a file path or literal text."
        return
    }
    if ($InputArgs.Count -eq 1 -and -not $InputArgs[0].StartsWith('-')) {
        $single = $InputArgs[0]
        if (Test-Path -LiteralPath $single -PathType Leaf) {
            if ($Append) {
                copy_to_clipboard -r -a -- $single
            } else {
                copy_to_clipboard -r -- $single
            }
        } else {
            if ($Append) {
                $single | set_clipboard_text -a
            } else {
                $single | set_clipboard_text
            }
        }
        return
    }
    $fwd = @()
    if ($Append) { $fwd += '-a' }
    $fwd += $InputArgs
    $c2cExe = Get-Command c2c.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($c2cExe) {
        & $c2cExe.Source @fwd
    } else {
        copy_to_clipboard @fwd
    }
}
Set-Alias -Name scb -Value Set-ClipboardContent
Set-Alias -Name c2c -Value Set-ClipboardContent  # preserves literal-or-file compat; forwards flags/multi-files to c2c.exe

function Set-FileClipboard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    # Replace file contents with clipboard (Python handles stats & errors)
    replace_with_clipboard -- $Path
}
function Add-ClipboardToFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    append_clipboard -- $FilePath
}

function Invoke-CommandToClipboard {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Command,
        [switch]$Wrap,
        [switch]$Append
    )
    # Forward to the Python script (uses shell wrapper logic for aliases/functions)
    $argsList = @()
    if ($Wrap)   { $argsList += "-w" }
    if ($Append) { $argsList += "-a" }
    $argsList += "--"
    $argsList += $Command
    output_to_clipboard @argsList
}

# rwc, apc, otc are served directly by Python clipboard_tools console entry points on PATH.
# sfc is intentionally not aliased here so Windows System File Checker (sfc.exe) is not shadowed.
Export-ModuleMember `
  -Function Get-ClipboardContents, Set-ClipboardContent, Set-FileClipboard, Add-ClipboardToFile, Invoke-CommandToClipboard `
  -Alias gcb, scb, c2c
