# Copy the ProfileCUCH.ps1 to the active profile
# TODO: If other profiles are added for different powershell shell situations, add options in script to select which profile to copy

$sourcePath = "C:\Projects\W11-powershell\Scripts\Profiles\ProfileCUCH.ps1"
$destinationPath = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

Copy-Item -Path $sourcePath -Destination $destinationPath
