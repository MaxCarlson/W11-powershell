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
    $parsedArgs = @{}
    foreach ($key in $Parameters.Keys) {
        if ($PassedArgs.ContainsKey($key)) {
            $parsedArgs[$key] = $PassedArgs[$key]
        } elseif ($Parameters[$key].ContainsKey('DefaultValue')) {
            $parsedArgs[$key] = $Parameters[$key]['DefaultValue']
        } else {
            Write-Error "Missing required parameter: -$key"
            throw "Error: Missing required parameter: -$key"
        }
    }
    if ($parsedArgs.ContainsKey('h') -and $parsedArgs['h'] -eq $true) {
        Write-Host $HelpMessage
        exit 0
    }
    return $parsedArgs
}

function Validate-Arguments {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Arguments,
        [Parameter(Mandatory = $true)]
        [hashtable]$ValidationRules
    )
    Write-Host "DEBUG: Validating arguments..." -ForegroundColor Cyan
    foreach ($key in $ValidationRules.Keys) {
        if ($ValidationRules[$key] -is [scriptblock]) {
            $isValid = & $ValidationRules[$key] $Arguments[$key]
            if (-not $isValid) {
                Write-Error "Validation failed for -$key: $($Arguments[$key])"
                throw "Error: Validation failed for -$key"
            }
        }
    }
    Write-Host "DEBUG: Validation passed for all arguments." -ForegroundColor Green
}

Export-ModuleMember -Function Get-Arguments, Validate-Arguments

