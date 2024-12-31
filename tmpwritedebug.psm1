function Write-Debug {
    param (
        [string]$Message = "",

        [Parameter()]
        [ValidateSet("Error", "Warning", "Verbose", "Information", "Debug")]
        [string]$Channel = "Debug",

        [AllowNull()]
        [object]$Condition = $true
    )

    # Ensure DebugProfile is enabled
    if (-not $DebugProfile) {
        return
    }

    # Validate and convert the Condition parameter
    $isConditionMet = $true
    if ($Condition -ne $null) {
        try {
            $isConditionMet = [bool]$Condition
        } catch {
            Write-Warning "Invalid Condition value for Write-Debug: '$Condition'. Defaulting to `$false`."
            $isConditionMet = $false
        }
    }

    if (-not $isConditionMet) {
        return
    }

    # Get caller information for debugging
    $callerFile = $MyInvocation.ScriptName
    $callerLine = $MyInvocation.ScriptLineNumber

    # Define channel colors
    $colorMap = @{
        "Error"       = "Red"
        "Warning"     = "Yellow"
        "Verbose"     = "Gray"
        "Information" = "Cyan"
        "Debug"       = "Green"
    }

    $color = $colorMap[$Channel]
    if ($color) {
        Write-Host "[$callerFile:$callerLine] $Message" -ForegroundColor $color
    } else {
        Write-Warning "Invalid channel specified: $Channel"
    }
}

# Export the function
Export-ModuleMember -Function Write-Debug
