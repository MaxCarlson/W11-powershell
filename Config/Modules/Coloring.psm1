function Write-Color {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet(
            "Error", "Warning", "Success", "Info", "Debug", 
            "Critical", "Processing", "Prompt",
            "Red", "Yellow", "Green", "Cyan", "Gray", 
            "DarkRed", "DarkCyan", "Blue", "White"
        )]
        [string]$Type = "White"
    )

    # Map message types to PowerShell colors
    $colorMapping = @{
        "Error"       = "Red"
        "Warning"     = "Yellow"
        "Success"     = "Green"
        "Info"        = "Cyan"
        "Debug"       = "Gray"
        "Critical"    = "DarkRed"
        "Processing"  = "DarkCyan"
        "Prompt"      = "Blue"
    }

    # Resolve the color from the mapping, default to the provided color if not in the mapping
    $color = if ($colorMapping.ContainsKey($Type)) {
        $colorMapping[$Type]
    } else {
        $Type
    }

    # Output the message with the resolved color
    Write-Host $Message -ForegroundColor $color
}

Export-ModuleMember -Function Write-Color
