<#
.SYNOPSIS
    Provides utilities for formatting PowerShell output.
.DESCRIPTION
    This module contains functions to measure output, apply table or list formatting, 
    and enhance readability of command outputs.
#>

$script:DebugModule = $false


function Measure-FormattedOutput {
    <#
    .SYNOPSIS
        Counts the number of lines or items in a given output.
    .DESCRIPTION
        Determines whether the input is formatted as a table/list and counts either lines or items.
        If input is unformatted, it defaults to counting lines.
    .PARAMETER InputObject
        The output to measure.
    .PARAMETER Pattern
        Optional regex pattern to filter lines/items before counting.
    .PARAMETER Lines
        Forces counting lines instead of items.
    .PARAMETER Items
        Forces counting items instead of lines.
    .EXAMPLE
        Get-UserDefinedFunctions | Measure-FormattedOutput
    .EXAMPLE
        Get-UserDefinedFunctions | Measure-FormattedOutput -Pattern "cd"
    #>
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$InputObject,

        [string]$Pattern = "",
        [switch]$Lines,
        [switch]$Items
    )

    begin {
        $data = @()
    }

    process {
        $data += $_
    }

    end {
        if ($Pattern) {
            Write-Debug -Message "Applying filter pattern: $Pattern" -Channel "Information"
            $data = $data | Where-Object { $_ -match $Pattern }
        }

        $isFormatted = ($data -match "^-+$" -or $data -match "^\s*\w+\s+\w+")

        if ($Items -or ($isFormatted -and -not $Lines)) {
            Write-Debug -Message "Counting items in formatted output" -Channel "Information"
            Write-Debug -Message "Total Items: $($data.Count - 2)" -Channel "Success"
        } else {
            Write-Debug -Message "Counting lines in unformatted output" -Channel "Information"
            Write-Debug -Message "Total Lines: $($data.Count)" -Channel "Success"
        }
    }
}

function Format-Output {
    <#
    .SYNOPSIS
        Automatically applies table or list formatting to output.
    .DESCRIPTION
        Determines whether output is structured as a table or list and applies the correct formatting.
    .PARAMETER InputObject
        The input data to format.
    .PARAMETER ForceTable
        Forces table formatting.
    .PARAMETER ForceList
        Forces list formatting.
    .EXAMPLE
        Get-UserDefinedFunctions | Format-Output
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$InputObject,

        [switch]$ForceTable,
        [switch]$ForceList
    )

    Write-Debug -Message "Applying formatting to output" -Channel "Information"
    $isFormatted = ($InputObject -is [array] -and $InputObject.Count -gt 1) -or ($InputObject -match "^-+$")

    if ($ForceList -or (-not $ForceTable -and -not $isFormatted)) {
        Write-Debug -Message "Using list formatting" -Channel "Success"
        return $InputObject | Format-List
    } else {
        Write-Debug -Message "Using table formatting" -Channel "Success"
        return $InputObject | Format-Table -AutoSize
    }
}

function Limit-Output {
    <#
    .SYNOPSIS
        Limits long text output while preserving readability.
    .DESCRIPTION
        Limits long output at a specified character limit and appends "..." if needed.
    .PARAMETER InputObject
        The text or output to truncate.
    .PARAMETER CharLimit
        The maximum number of characters allowed before truncation.
    .EXAMPLE
        "This is a long line that needs truncation." | Limit-Output -CharLimit 20
    #>
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string]$InputObject,

        [int]$CharLimit = 80
    )

    process {
        if ($InputObject.Length -gt $CharLimit) {
            Write-Debug -Message "Truncating output to $CharLimit characters" -Channel "Warning" -Condition $DebugModule
            return $InputObject.Substring(0, $CharLimit) + "..."
        } else {
            return $InputObject
        }
    }
}

function Format-OutputSpacing {
    <#
    .SYNOPSIS
        Cleans up excessive spaces and line breaks from output.
    .DESCRIPTION
        Replaces multiple spaces with a single space and removes unnecessary line breaks.
    .PARAMETER InputObject
        The text or output to clean.
    .EXAMPLE
        "  This   has  too  many  spaces.  " | Format-OutputSpacing
    #>
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string]$InputObject
    )

    process {
        Write-Debug -Message "Cleaning output spacing" -Channel "Information"
        return ($InputObject -replace "\s{2,}", " ").Trim()
    }
}

function Format-FunctionDefinitions {
    <#
    .SYNOPSIS
        Cleans up function definitions for display.
    .DESCRIPTION
        Removes unnecessary newlines, trims spaces, and applies a character limit if needed.
    .PARAMETER Functions
        The function list to process.
    .PARAMETER CharLimit
        Maximum character length for function definitions (or -1 for no limit).
    .EXAMPLE
        $functions | Format-FunctionDefinitions -CharLimit 100
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Functions,

        [int]$CharLimit
    )

    Write-Debug -Message "Processing function definitions with CharLimit = $CharLimit" -Channel "Information"

    return $Functions | ForEach-Object {
        $_.Definition = ($_.Definition -replace "\s*\r?\n\s*", " ").Trim()

        if ($CharLimit -gt 0 -and $_.Definition.Length -gt $CharLimit) {
            Write-Debug -Message "Truncating function: $($_.Name)" -Channel "Warning" -Condition $DebugModule
            $_.Definition = $_.Definition.Substring(0, $CharLimit) + "..."
        }
        $_
    }
}

Export-ModuleMember -Function Measure-FormattedOutput, Format-Output, Limit-Output, Format-OutputSpacing, Format-FunctionDefinitions
