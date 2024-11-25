# ArgumentsHelperMin.psm1

function Get-Arguments {
    param (
        [Parameter(Mandatory = $false)]
        [string]$HelpMessage = "Help message not provided.",

        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,

        [Parameter(Mandatory = $true)]
        [hashtable]$PassedArgs
    )

    Write-Host "DEBUG: Inside Get-Arguments" -ForegroundColor Cyan
    Write-Host "DEBUG: Full PassedArgs: $PassedArgs" -ForegroundColor Yellow

    # Initialize parsedArgs to hold the final arguments
    $parsedArgs = @{}

    # Loop through all defined parameters
    foreach ($key in $Parameters.Keys) {
        if ($PassedArgs.ContainsKey($key)) {
            # If argument is passed, use it
            $parsedArgs[$key] = $PassedArgs[$key]
            Write-Host "DEBUG: Using passed value for -${key}: $($PassedArgs[$key])" -ForegroundColor Green
        }
        elseif ($Parameters[$key] -is [hashtable] -and $Parameters[$key].ContainsKey('DefaultValue')) {
            # Use default value if provided
            $parsedArgs[$key] = $Parameters[$key]['DefaultValue']
            Write-Host "DEBUG: Using default value for -${key}: $($Parameters[$key]['DefaultValue'])" -ForegroundColor Cyan
        }
        else {
            # If no default value and not passed, throw an error for mandatory parameters
            Write-Error "Missing required parameter: -$key"
            throw "Error: Missing required parameter: -$key"
        }
    }

    # Detect the help flag
    if ($parsedArgs.ContainsKey('h') -and $parsedArgs['h'] -eq $true) {
        Write-Host "DEBUG: Help flag detected in PassedArgs." -ForegroundColor Green
        Write-Host $HelpMessage
        exit 0
    }

    Write-Host "DEBUG: Final parsed arguments: $parsedArgs" -ForegroundColor Cyan
    return $parsedArgs
}

function Test-Arguments {
    param (
        [hashtable]$Arguments,
        [hashtable]$ValidationRules
    )

    foreach ($key in $ValidationRules.Keys) {
        if ($ValidationRules[$key] -is [scriptblock]) {
            $isValid = & $ValidationRules[$key] $Arguments[$key]
            if (-not $isValid) {
                Write-Error "Validation failed for -${key}: $($Arguments[$key])"
                throw "Error: Validation failed for -${key}"
            }
        }
    }
    Write-Host "DEBUG: Validation passed for all arguments." -ForegroundColor Green
}

Export-ModuleMember -Function Get-Arguments, Test-Arguments