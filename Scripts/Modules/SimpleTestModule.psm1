# SimpleTestModule.psm1
function Get-Test {
    Write-Host "Test function executed"
}

Export-ModuleMember -Function Get-Test

