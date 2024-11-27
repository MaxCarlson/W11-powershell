# Unit Conversion Utilities

# Converts bytes to megabytes
function Convert-BytesToMB {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Bytes
    )
    return [math]::Round($Bytes / 1MB, 2)
}

# Converts bytes to gigabytes
function Convert-BytesToGB {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Bytes
    )
    return [math]::Round($Bytes / 1GB, 2)
}

# Formats a percentage
function Convert-ToPercentage {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Value,

        [Parameter(Mandatory = $true)]
        [double]$Total
    )
    return [math]::Round(($Value / $Total) * 100, 2)
}
