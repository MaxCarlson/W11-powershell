
┃# Tracking collections   
$script:ModuleLoadFailures = @()   
$script:ModuleLoadStats    = @{}
function Test-Function {
  Write-Host 'Hello from MinimalLoader'
}

Export-ModuleMember -Function Test-Function
