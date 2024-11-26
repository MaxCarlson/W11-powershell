function Write-Color {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Cyan", "Green", "Yellow", "Red", "White")]
        [string]$Color = "White"
    )

    switch ($Color) {
        "Cyan" { Write-Host $Message -ForegroundColor Cyan }
        "Green" { Write-Host $Message -ForegroundColor Green }
        "Yellow" { Write-Host $Message -ForegroundColor Yellow }
        "Red" { Write-Host $Message -ForegroundColor Red }
        default { Write-Host $Message }
    }
}

Export-ModuleMember -Function Write-Color
