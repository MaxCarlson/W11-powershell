# PowerShell Script to Remove ReadOnly Attribute from a Directory

# Prompt the user for the directory path
$directoryPath = Read-Host "Please enter the directory path"

# Check if the directory exists
if (Test-Path -Path $directoryPath) {
    # Get the current attributes of the directory
    $currentAttributes = (Get-Item $directoryPath).Attributes

    # Check if the ReadOnly attribute is set
    if ($currentAttributes -band [System.IO.FileAttributes]::ReadOnly) {
        # Calculate the new attributes, excluding ReadOnly
        $newAttributes = $currentAttributes -band -bnot [System.IO.FileAttributes]::ReadOnly
        
        # Use attrib command to remove the ReadOnly attribute, since Set-ItemProperty might cause issues
        attrib -R "$directoryPath"
        
        # Display the updated attributes
        Write-Output "ReadOnly attribute has been removed. Updated attributes are:"
        Get-Item $directoryPath | Select-Object Attributes
    }
    else {
        Write-Output "No ReadOnly attribute is set. Current attributes are:"
        Get-Item $directoryPath | Select-Object Attributes
    }
}
else {
    Write-Error "The specified directory does not exist."
}
