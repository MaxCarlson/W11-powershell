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

function aliasGrepFunction {
    param(
        [string]$Pattern
    )
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
