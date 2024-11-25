# MinimumDebug.ps1
param (
    [switch]$h  # Define the help flag in the parent script
)

# Debugging: Check and display the resolved path for the module
#Write-Host "DEBUG: Calculating module path..." -ForegroundColor Yellow
#$modulePath = "${PSScriptRoot}\..\Modules\ArgumentHelperMin.psm1"
#Write-Host "DEBUG: Module path: $modulePath" -ForegroundColor Cyan

# Validate if the module exists at the calculated path
#if (-not (Test-Path $modulePath)) {
#    Write-Error "Module not found at: $modulePath"
#    exit 1
#}

Write-Host "DEBUG: Importing ArgumentHelper module..." -ForegroundColor Yellow
Import-Module "C:\Projects\W11-powershell\Scripts\Modules\ArgumentHelperMin.psm1" -Verbose -Force
#Import-Module -Name $modulePath -Verbose

Write-Host "DEBUG: Defining parameters..." -ForegroundColor Yellow
$parameters = @{
    h = @{ DefaultValue = $false }
}

Write-Host "DEBUG: Defining help message..." -ForegroundColor Yellow
$helpMessage = @"
This is a minimal debug script.
"@

Write-Host "DEBUG: Starting argument parsing..." -ForegroundColor Yellow
$args = Get-Arguments -HelpMessage $helpMessage -Parameters $parameters -PassedArgs $PSBoundParameters

Write-Host "DEBUG: Parsed arguments: $args" -ForegroundColor Green
Write-Host "DEBUG: Help flag value: $($args.h)" -ForegroundColor Yellow

# Handle help flag
if ($args.h -eq $true) {
    Write-Host "DEBUG: Exiting due to help flag." -ForegroundColor Yellow
    exit 0
}

Write-Host "DEBUG: Script completed successfully!" -ForegroundColor Green
