#Set-Location ~
#mkdir sources
#Set-Location sources
#
#gh repo clone W11-powershell

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
