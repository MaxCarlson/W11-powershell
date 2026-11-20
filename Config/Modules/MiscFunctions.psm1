# Miscellaneous functions
#
#
# 
#
#

function GitMan {
    param ($Subcommand)
    git help -m $Subcommand | groff -T ascii -man | more
}

Set-Alias gitman GitMan

# Winget setup for small devices
function swinget {
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    winget @Arguments | Format-Table -Wrap -AutoSize
}


# Sudo Simulation
function _ { Start-Process powershell -Verb runAs -ArgumentList ($args -join ' ') }

# ag searches for aliases whose commands match the pattern
Remove-Item Alias:ag -ErrorAction SilentlyContinue
Remove-Item Function:ag -ErrorAction SilentlyContinue

# Ensure PowerShell built-in gcb/scb aliases do not shadow Python clipboard entry points
Remove-Item Alias:gcb -ErrorAction SilentlyContinue
Remove-Item Alias:scb -ErrorAction SilentlyContinue

function aliasGrepFunction {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    $agExe = Get-Command ag.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($agExe) {
        $tmpFile = [System.IO.Path]::GetTempFileName()
        try {
            $items = [System.Collections.Generic.List[object]]::new()
            foreach ($a in (Get-Alias -ErrorAction SilentlyContinue)) {
                $items.Add([PSCustomObject]@{
                    name       = $a.Name
                    kind       = 'shell_alias'
                    source     = 'pwsh'
                    definition = [string]$a.Definition
                })
            }
            foreach ($f in (Get-Command -CommandType Function -ErrorAction SilentlyContinue)) {
                $def = ([string]$f.Definition) -replace '\r?\n', ' '
                if ($def.Length -gt 200) { $def = $def.Substring(0, 200) + '...' }
                $items.Add([PSCustomObject]@{
                    name       = $f.Name
                    kind       = 'shell_function'
                    source     = 'pwsh'
                    definition = $def
                })
            }
            @{ shell = 'pwsh'; items = $items } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $tmpFile -Encoding UTF8
            $prev = $env:AG_SHELL_INVENTORY_FILE
            $env:AG_SHELL_INVENTORY_FILE = $tmpFile
            try {
                & $agExe.Source @Arguments
                return
            } finally {
                if ($null -eq $prev) { Remove-Item Env:AG_SHELL_INVENTORY_FILE -ErrorAction SilentlyContinue } else { $env:AG_SHELL_INVENTORY_FILE = $prev }
            }
        } finally {
            Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
        }
    }

    $Pattern = if ($Arguments -and $Arguments.Count -gt 0) { $Arguments[0] } else { '' }
    Get-Alias | Where-Object { $_.Definition -match $Pattern -or $_.Name -match $Pattern } | Format-Table -Property Name, Definition
}

Set-Alias -Name ag -Value aliasGrepFunction 

# grep implementation for powershell
function grepFunction {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$InputObject
    )
    process {
        $InputObject | Select-String -Pattern $Pattern
    }
}

Set-Alias -Name grep -Value grepFunction
