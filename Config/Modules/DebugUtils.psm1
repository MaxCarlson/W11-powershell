# DebugUtils.psm1
#
<#
.SYNOPSIS
    Provides debugging utilities for logging and color-coded debug messages in PowerShell scripts.

.DESCRIPTION
    The DebugUtils module contains functions to help with debugging scripts. It provides a flexible
    `Write-Debug` function that allows color-coded messages based on severity levels, `Debug-Action`
    for conditional debugging execution, and `Write-TestAllColors` to visually test available colors.

.FUNCTIONS
    - Write-Debug: Logs messages with color-coded channels for structured debugging output.
    - Debug-Action: Executes a script block with optional verbose or suppressed output modes.
    - Write-TestAllColors: Prints out all available PowerShell console colors and displays the
      predefined Write-Debug color mappings.

.EXAMPLE
    Write-Debug -Message "This is a debug message" -Channel "Debug"
    Outputs a debug message in the predefined "Debug" color.

.EXAMPLE
    Debug-Action -VerboseAction { Write-Host "Executing in verbose mode" }
    Runs an action with verbosity enabled if DebugProfile is set.

.EXAMPLE
    Write-TestAllColors
    Prints all PowerShell-supported colors and the defined color mappings for debugging messages.

.LINK
    Write-Debug, Debug-Action, Write-TestAllColors
#>

# Define channel colors
$script:colorMap = @{
    "Error"       = "Red"
    "Warning"     = "Yellow"
    "Verbose"     = "Gray"
    "Information" = "Cyan"
    "Debug"       = "Magenta"
    "Success"     = "Green"
}

<#
.SYNOPSIS
    Logs a message to the console with color-coded output based on the specified channel.

.DESCRIPTION
    The Write-Debug function allows structured logging of debug messages by specifying a channel.
    The message is only displayed if DebugProfile is enabled. Optionally, it can include file and line
    information to assist in tracking execution flow.

.PARAMETER Message
    The debug message to display.

.PARAMETER Channel
    Specifies the type of message. Supports: Error, Warning, Verbose, Information, Debug, Success.
    "Info" is an alias for "Information".

.PARAMETER Condition
    If provided, the message will only be logged if the condition evaluates to $true.

.PARAMETER FileAndLine
    If specified, includes the script file name and line number where the debug message originated.

.EXAMPLE
    Write-Debug -Message "Initialization complete" -Channel "Success"
    Displays a green success message.
#>
function Write-Debug {
    param (
        [string]$Message = "",

        [Parameter()]
        [ValidateSet("Error", "Warning", "Verbose", "Information", "Info", "Debug", "Success")]
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

    if($Channel -eq "Info"){
        $Channel = "Information"
    }

    $color = $colorMap[$Channel]
    if ($color) {
        Write-Host $outputMessage -ForegroundColor $color
    } else {
        Write-Warning "Invalid channel specified: ${Channel}"
    }
}

<#
.SYNOPSIS
    Executes a script block with optional verbose or suppressed debugging output.

.DESCRIPTION
    The Debug-Action function runs a provided script block and can either enable verbose mode
    or suppress debug output depending on the DebugProfile setting.

.PARAMETER VerboseAction
    Enables additional debug messages during execution.

.PARAMETER SuppressOutput
    Suppresses output if DebugProfile is disabled.

.PARAMETER Action
    The script block to execute.

.EXAMPLE
    Debug-Action -VerboseAction { Write-Host "Running action..." }
    Runs the provided action in verbose mode.
#>

<#
.SYNOPSIS
    Displays all PowerShell-supported colors and the current Write-Debug color mappings.

.DESCRIPTION
    This function prints each color available in PowerShell's console and also displays
    the predefined Write-Debug color mappings for structured debugging.

.EXAMPLE
    Write-TestAllColors
    Prints all PowerShell-supported colors and the defined debug color mappings.
#>
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
