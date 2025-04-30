# AutoExport.psm1

# Capture baseline at module load
$script:BaseFunctions = Get-Command -CommandType Function | Select-Object -Expand Name
$script:BaseAliases   = Get-Alias | Select-Object -Expand Name

function Export-AutoExportFunctions {
    [CmdletBinding()]
    param(
        [string[]]$Exclude = @(),
        [switch]$DebugPrint
    )
    $all = Get-Command -CommandType Function | Select-Object -Expand Name
    $new = $all | Where-Object { $script:BaseFunctions -notcontains $_ }
    $toExport = $new | Where-Object { $Exclude -notcontains $_ }
    if ($DebugPrint) {
        Write-Debug "Detected functions: $($new -join ', ')"        -Condition $DebugProfile
        Write-Debug "Excluding: $($Exclude -join ', ')"            -Condition $DebugProfile
        Write-Debug "Exporting: $($toExport -join ', ')"           -Condition $DebugProfile
    }
    if ($toExport) { Export-ModuleMember -Function $toExport }
}

function Export-AutoExportAliases {
    [CmdletBinding()]
    param(
        [string[]]$Exclude = @(),
        [switch]$DebugPrint
    )
    $all = Get-Alias | Select-Object -Expand Name
    $new = $all | Where-Object { $script:BaseAliases -notcontains $_ }
    $toExport = $new | Where-Object { $Exclude -notcontains $_ }
    if ($DebugPrint) {
        Write-Debug "Detected aliases: $($new -join ', ')"          -Condition $DebugProfile
        Write-Debug "Excluding: $($Exclude -join ', ')"            -Condition $DebugProfile
        Write-Debug "Exporting: $($toExport -join ', ')"           -Condition $DebugProfile
    }
    if ($toExport) { Export-ModuleMember -Alias $toExport }
}
