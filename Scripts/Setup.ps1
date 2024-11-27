#Set-Location ~
# Example Setup Script
#mkdir sources
#Set-Location sources
#
#gh repo clone W11-powershell

$modulesToLink = @(
    @{ Path = ".\Modules\SessionTools.psm1"; LinkType = "hard"; Target = "system"}
    #@{ Path = "C:\YourLocalModules\AnotherModule"; Target = "system"; LinkType = "symbolic" Target = "user" }
)

foreach ($module in $modulesToLink) {
    # Call the LinkModule.ps1 script with arguments
    & ".\Helpers\LinkModule.ps1" -ModulePath $module.Path -TargetLocation $module.Target -LinkType $module.LinkType
}

return

# Recursively get a list of SetupSchedule.ps1 files
$setupFiles = Get-ChildItem -Path $baseDirectory -Filter "SetupSchedule.ps1" -Recurse

# Iterate over each setup file found and execute it
foreach ($file in $setupFiles) {
    # Full path to the SetupSchedule.ps1 script
    $setupFilePath = $file.FullName
    
    # Check if the file exists to avoid errors
    if (Test-Path -Path $setupFilePath) {
        # Run the setup script
        & $setupFilePath
    }
}
