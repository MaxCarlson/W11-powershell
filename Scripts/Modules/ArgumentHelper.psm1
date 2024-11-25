function Get-Arguments {
    param (
        [string]$HelpMessage = "This script does something. Customize the HelpMessage argument.",
        [hashtable]$Parameters
    )

    $parsedArgs = @{}
    foreach ($key in $Parameters.Keys) {
        if (-not $PSBoundParameters.ContainsKey($key)) {
            # Add default values if specified
            if ($Parameters[$key].ContainsKey('DefaultValue')) {
                $parsedArgs[$key] = $Parameters[$key]['DefaultValue']
            } else {
                Write-Error "Missing required parameter: -$key"
                Write-Host $HelpMessage
                throw "Missing required parameter: -$key"  # Stop execution on error
            }
        } else {
            $parsedArgs[$key] = $PSBoundParameters[$key]
        }
    }

    # Check if help was requested
    if ($PSBoundParameters.ContainsKey('h') -and $PSBoundParameters['h']) {
        Write-Host $HelpMessage
        exit 0  # Terminate execution immediately
    }

    return $parsedArgs
}


function Show-ScriptHelp {
    param ([string]$Message)
    Write-Host @"
Usage:
$Message

Example:
  .\YourScript.ps1 -Param1 Value1 -Param2 Value2
"@
}

Export-ModuleMember -Function Get-Arguments, Show-ScriptHelp

