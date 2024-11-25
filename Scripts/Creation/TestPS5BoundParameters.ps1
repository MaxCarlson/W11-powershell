param (
    [switch]$h
)

Write-Host "DEBUG: Full PSBoundParameters: $PSBoundParameters" -ForegroundColor Yellow
if ($PSBoundParameters.ContainsKey('h')) {
    Write-Host "DEBUG: Help flag detected: $($PSBoundParameters['h'])" -ForegroundColor Green
} else {
    Write-Host "DEBUG: Help flag not found in PSBoundParameters." -ForegroundColor Red
}

