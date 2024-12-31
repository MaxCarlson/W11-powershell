# DebugUtils.psm1
#
#Write-Host "Inside DebugUtils"
#Write-Host "DebugProfile value: ${DebugProfile}"
function Debug-Action {
    param (
        [switch]$VerboseAction,  # If true, enable verbose actions (like -Verbose or extra logging)
        [switch]$SuppressOutput, # If true, suppress output entirely when DebugProfile is off
        [scriptblock]$Action     # The script block of code to execute
    )

    if ($null -eq $Action) {
        Write-Debug "No action provided to Debug-Action function" -Channel "Warning"
        return
    }

    # Save the original Write-Debug and Write-Host so we can restore them later
    $originalWriteDebug = Get-Command Write-Debug
    $originalWriteHost = Get-Command Write-Host

    if ($DebugProfile) {
        # If DebugProfile is enabled, execute normally
        if ($VerboseAction) {
            Write-Host "Executing verbose action..."
            $Action.Invoke()  # Execute the provided action with verbosity
        }
        else {
            Write-Host "Executing action normally with DebugProfile enabled..."
            $Action.Invoke()  # Execute the provided action normally
        }
    }
    else {
        # If DebugProfile is off, suppress output or handle accordingly
        if ($SuppressOutput) {
            Write-Host "Suppressing output due to DebugProfile being off..."

            # Override Write-Debug and Write-Host to suppress output
            Function Write-Debug { return }
            Function Write-Host { return }

            $Action.Invoke()  # Execute but discard output from Write-Debug, Write-Host, etc.

            # Restore the original Write-Debug and Write-Host functions
            Set-Command -Name Write-Debug -CommandType Cmdlet -Value $originalWriteDebug
            Set-Command -Name Write-Host -CommandType Cmdlet -Value $originalWriteHost
        }
        else {
            Write-Debug "Executing action normally with DebugProfile disabled..."
            $Action.Invoke()  # Execute the provided action normally, but output is shown
        }
    }
}

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
            Write-Warning "Invalid Condition value for Write-Debug: '${Condition}'. Defaulting to `${false}`."
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
        Write-Host "[${callerFile}:${callerLine}] ${Message}" -ForegroundColor $color
    } else {
        Write-Warning "Invalid channel specified: ${Channel}"
    }
}

# Export the function for use outside the module
Export-ModuleMember -Function Debug-Action, Write-Debug


#Write-Host "DebugProfile value: ${DebugProfile}"
#Write-Host "Exiting DebugUtils"
