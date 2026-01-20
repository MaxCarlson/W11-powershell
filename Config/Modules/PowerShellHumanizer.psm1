<#
.SYNOPSIS
    Converts raw byte sizes in objects to human-readable formats (KB, MB, GB, TB).

.DESCRIPTION
    The PowerShellHumanizer module provides tools to make raw data more readable for users.
    The primary function, Add-HumanSize, accepts objects from the pipeline, detects properties
    containing byte counts (like Length, Size, UsedSpace), and appends a new property with
    a formatted, human-readable string.

.AUTHOR
    Max Carlson

.DATE
    2025-12-10
#>

function Add-HumanSize {
    <#
    .SYNOPSIS
        Adds a human-readable size property to objects with byte counts.

    .DESCRIPTION
        Takes an input object, checks for standard size properties (or custom ones specified by the user),
        and adds a new NoteProperty ending in "HR" (Human Readable) containing the formatted size string.

    .PARAMETER InputObject
        The object to process. Typically passed via the pipeline.

    .PARAMETER SizeProperty
        The name(s) of the property to inspect for byte values. 
        Defaults to 'Length', 'Size', 'TotalSize', 'UsedSpace', 'FreeSpace'.

    .EXAMPLE
        Get-ChildItem | Add-HumanSize | Select-Object Name, LengthHR
        
        Description
        -----------
        Lists files in the current directory and shows their size in the most appropriate unit (KB, MB, etc.).

    .EXAMPLE
        Get-VirtualDisk | Add-HumanSize | Format-Table FriendlyName, SizeHR

        Description
        -----------
        Displays virtual disks with their sizes formatted as TB or GB.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [psobject]$InputObject,

        [Parameter(Mandatory=$false)]
        [string[]]$SizeProperty = @('Length', 'Size', 'TotalSize', 'UsedSpace', 'FreeSpace')
    )

    process {
        # Create a copy of the object to avoid modifying the original if passed by ref in some contexts
        # Select-Object * creates a PSCustomObject copy
        $NewObject = $InputObject | Select-Object *

        foreach ($PropName in $SizeProperty) {
            # Check if the object actually has this property
            if ($InputObject.PSObject.Properties.Name -contains $PropName) {
                $RawValue = $InputObject.$PropName
                
                # Check if the value is a valid number and greater than 0
                if (($RawValue -is [long] -or $RawValue -is [int] -or $RawValue -is [double] -or $RawValue -is [decimal]) -and ($RawValue -gt 0)) {
                    
                    # Logic to determine the correct unit and format the string
                    $FormattedSize = if ($RawValue -ge 1PB) { "{0:N2} PB" -f ($RawValue / 1PB) }
                    elseif ($RawValue -ge 1TB) { "{0:N2} TB" -f ($RawValue / 1TB) }
                    elseif ($RawValue -ge 1GB) { "{0:N2} GB" -f ($RawValue / 1GB) }
                    elseif ($RawValue -ge 1MB) { "{0:N2} MB" -f ($RawValue / 1MB) }
                    elseif ($RawValue -ge 1KB) { "{0:N2} KB" -f ($RawValue / 1KB) }
                    else { "{0:N0} B" -f $RawValue }
                    
                    # Define the new property name (e.g., Size -> SizeHR)
                    $NewPropertyName = $PropName + "HR" 

                    # Add the new property to the object
                    # We use force to overwrite if it somehow already exists on the object
                    $NewObject | Add-Member -MemberType NoteProperty -Name $NewPropertyName -Value $FormattedSize -Force
                }
            }
        }
        # Output the modified object to the pipeline
        return $NewObject
    }
}

# Export the function so it is visible when the module is imported
Export-ModuleMember -Function Add-HumanSize
