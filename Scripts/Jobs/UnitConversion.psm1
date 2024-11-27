# Unit Conversion Utilities

# Converts bytes to megabytes
function Convert-BytesToMB {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Bytes
    )
    return [math]::Round(${Bytes} / 1MB, 2)
}

# Converts bytes to gigabytes
function Convert-BytesToGB {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Bytes
    )
    return [math]::Round(${Bytes} / 1GB, 2)
}

# Formats a percentage
function Convert-ToPercentage {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Value,

        [Parameter(Mandatory = $true)]
        [double]$Total
    )
    return [math]::Round((${Value} / ${Total}) * 100, 2)
}

# Converts milliseconds to seconds
function Convert-MillisecondsToSeconds {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Milliseconds
    )
    return [math]::Round(${Milliseconds} / 1000, 2)
}

# Converts seconds to minutes
function Convert-SecondsToMinutes {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Seconds
    )
    return [math]::Round(${Seconds} / 60, 2)
}

# Converts minutes to hours
function Convert-MinutesToHours {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Minutes
    )
    return [math]::Round(${Minutes} / 60, 2)
}
