# UserFunctionsAliases.psm1

# these are defined in $PROFILE so nothing can be skipped
# Ensure session variables are only set once
#if (-not $global:UserFunctionsBeforeModules) {
#    $global:UserFunctionsBeforeModules = Get-Command -CommandType Function | Select-Object -ExpandProperty Name
#    $global:UserAliasesBeforeModules = Get-Alias | Select-Object -ExpandProperty Name
#}


function Get-UserDefinedFunctions {
    <#
    .SYNOPSIS
        Retrieves user-defined functions.
    .DESCRIPTION
        Lists user-defined PowerShell functions, filtering out built-in ones.
        Supports limiting output and formatting function definitions properly.
    .PARAMETER Limit
        Limits the number of functions displayed.
    .PARAMETER CharLimit
        Maximum character length for function definitions (-1 to disable).
    .EXAMPLE
        Get-UserDefinedFunctions
    .EXAMPLE
        Get-UserDefinedFunctions -Limit 5 -CharLimit 100
    #>
    param(
        [int]$Limit = 0,  
        [int]$CharLimit = 0  
    )

    Write-Debug -Message "Retrieving user-defined functions" -Channel "Information"

    # Auto-size CharLimit if not provided
    $terminalWidth = $Host.UI.RawUI.WindowSize.Width
    $definitionPrefixLength = ("Definition : ").Length
    $autoSizeLimit = $terminalWidth - $definitionPrefixLength

    if ($CharLimit -eq 0) {
        $CharLimit = $autoSizeLimit
        Write-Debug -Message "Auto-sized CharLimit to $CharLimit" -Channel "Success"
    }

    $multiLineAllowed = ($CharLimit -eq -1) -or ($CharLimit -gt $autoSizeLimit)

    # Get all user-defined functions
    $allFunctions = Get-Command -CommandType Function | Select-Object -ExpandProperty Name
    $newFunctions = $allFunctions | Where-Object { $_ -notin $global:UserFunctionsBeforeModules }

    $functions = Get-Command -CommandType Function | Where-Object { $_.Name -in $newFunctions } |
        Select-Object Name, Definition

    # Process function definitions
    $functions = Format-FunctionDefinitions -Functions $functions -CharLimit $CharLimit

    # Apply entry limit
    if ($Limit -gt 0) {
        Write-Debug -Message "Applying function limit: $Limit" -Channel "Information"
        $functions = $functions | Select-Object -First $Limit
    }

    # Format the output using FormattingModule
    return Format-Output -InputObject $functions -ForceList:$multiLineAllowed
}

function Get-UserDefinedAliases {
    param(
        [int]$Limit = 0  # Limit the number of results
    )

    $allAliases = Get-Alias | Select-Object -ExpandProperty Name
    $newAliases = $allAliases | Where-Object { $_ -notin $global:UserAliasesBeforeModules }
    
    $aliases = Get-Alias | Where-Object { $_.Name -in $newAliases } |
        Select-Object @{Name="DisplayName"; Expression={ "$($_.Name) -> $($_.Definition)" }}, Definition

    # Apply limit
    if ($Limit -gt 0) {
        $aliases = $aliases | Select-Object -First $Limit
    }

    return $aliases | Format-Table -AutoSize
}

function Get-UserDefinedFunctionsAndAliases {
    param(
        [int]$Limit = 0,   # Limit the number of results
        [int]$MaxLength = 0  # Limit function definition length
    )

    Write-Host "`n=== User-Defined Functions ===" -ForegroundColor Cyan
    Get-UserDefinedFunctions -Limit $Limit -MaxLength $MaxLength

    Write-Host "`n=== User-Defined Aliases ===" -ForegroundColor Cyan
    Get-UserDefinedAliases -Limit $Limit
}

Export-ModuleMember -Function Get-UserDefinedFunctions, Get-UserDefinedAliases, Get-UserDefinedFunctionsAndAliases
