# DebugUtils.psm1
#
#Write-Host "Inside DebugUtils"
#Write-Host "DebugProfile value: ${DebugProfile}"

# Define channel colors
$script:colorMap = @{
    "Error"       = "Red"
    "Warning"     = "Yellow"
    "Verbose"     = "Gray"
    "Information" = "Cyan"
    "Debug"       = "Magenta"
    "Success"     = "Green"
}

function Write-Debug {
    param (
        [string]$Message = "",

        [Parameter()]
        [ValidateSet("Error", "Warning", "Verbose", "Information", "Debug", "Success")]
        [string]$Channel = "Debug",

        [AllowNull()]
        [object]$Condition = $true,

        [switch]$FileAndLine # Flag to include caller file and line number
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

    # Prepare the message with optional caller information
    $outputMessage = $Message
    if ($FileAndLine) {
        # Get caller information for debugging
        $caller = Get-PSCallStack | Select-Object -Skip 1 -First 1
        $callerFile = $caller.ScriptName
        $callerLine = $caller.ScriptLineNumber
        $outputMessage = "[${callerFile}:${callerLine}] $Message"
    }


    $color = $colorMap[$Channel]
    if ($color) {
        Write-Host $outputMessage -ForegroundColor $color
    } else {
        Write-Warning "Invalid channel specified: ${Channel}"
    }
}


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

function Write-TestAllColors {
    $all_colors = @(
        "Black", "Blue", "Cyan", "DarkBlue", "DarkCyan", "DarkGray", "DarkGreen",
        "DarkMagenta", "DarkRed", "DarkYellow", "Gray", "Green", "Magenta", "Red",
        "White", "Yellow"
    )

    Write-Host "Writing Each PWSH Color Available... "
    foreach ($color in $all_colors) {
        Write-Host "This is $color text" -ForegroundColor $color
    }

    Write-Host "`nWriting the current Write-Debug colors..."
    foreach ($entry in $colorMap.GetEnumerator()){
        $channel = $entry.Key
        $color = $entry.Value
        Write-Host "Channel: ${channel} → $color" -ForegroundColor $color
    }
}



# Export the function for use outside the module
Export-ModuleMember -Function Debug-Action, Write-Debug, Write-TestAllColors 


#Write-Host "DebugProfile value: ${DebugProfile}"
#Write-Host "Exiting DebugUtils"
