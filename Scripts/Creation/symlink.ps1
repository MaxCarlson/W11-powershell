# Import the Argument Helper Module
Write-Host "DEBUG: Importing ArgumentHelper module..." -ForegroundColor Yellow
Import-Module -Name "$PSScriptRoot\..\Modules\ArgumentHelperMin.psm1"

# Define the parameters for the script
Write-Host "DEBUG: Defining parameters..." -ForegroundColor Yellow
$parameters = @{
    SourcePaths       = @{ DefaultValue = @() }
    DestinationFolder = @{ DefaultValue = $null }
    LinkNames         = @{ DefaultValue = @() }
    LinkType          = @{ DefaultValue = "auto" }
    h                 = @{ DefaultValue = $false }
}

# Help message for the script
Write-Host "DEBUG: Defining help message..." -ForegroundColor Yellow
$helpMessage = @"
Creates symbolic links for one or more files/folders in a specified destination folder.

Parameters:
  -SourcePaths        A single source file/folder or a list of files/folders.
  -DestinationFolder  The folder where symbolic links should be created.
  -LinkNames          (Optional) Custom names for the symbolic links.
                      If not provided, the source names are used.
  -LinkType           (Optional) Specify 'file', 'directory', or 'auto' (default: auto).
  -h                  Display this help message.

Examples:
  Single Source:
    .\CreateSymbolicLinks.ps1 -SourcePaths "C:\anime\Dandadan" -DestinationFolder "C:\TopAnime"

  Multiple Sources:
    .\CreateSymbolicLinks.ps1 -SourcePaths "C:\anime\Show1", "C:\anime\Show2" -DestinationFolder "C:\TopAnime"

  With Custom Names:
    .\CreateSymbolicLinks.ps1 -SourcePaths "C:\anime\Show1", "C:\anime\Show2" -DestinationFolder "C:\TopAnime" -LinkNames "Custom1", "Custom2"
"@

Write-Host "DEBUG: Starting argument parsing..." -ForegroundColor Yellow
Write-Host "DEBUG: $PSBoundParameters" -ForegroundColor Cyan

# Ensure we explicitly check how parameters are passed before invoking Get-Arguments
Write-Host "DEBUG: SourcePaths: $($PSBoundParameters['SourcePaths'])" -ForegroundColor Yellow
Write-Host "DEBUG: DestinationFolder: $($PSBoundParameters['DestinationFolder'])" -ForegroundColor Yellow

# Now proceed with calling Get-Arguments
try {
    $args = Get-Arguments -HelpMessage $helpMessage -Parameters $parameters -PassedArgs $PSBoundParameters
    Write-Host "DEBUG: Parsed arguments: $args" -ForegroundColor Green
}
catch {
    Write-Host "DEBUG: Exception caught - $($_.Exception.Message)" -ForegroundColor Red
    return
}


# Stop execution if no valid arguments exist
if (-not $args.SourcePaths.Count) {
    Write-Host "DEBUG: Missing SourcePaths argument!" -ForegroundColor Red
    Write-Error "Error: At least one SourcePath must be specified."
    return
}

if (-not $args.DestinationFolder) {
    Write-Host "DEBUG: Missing DestinationFolder argument!" -ForegroundColor Red
    Write-Error "Error: DestinationFolder must be specified."
    return
}

Write-Host "DEBUG: Ensuring destination folder exists..." -ForegroundColor Yellow
if (-not (Test-Path $args.DestinationFolder)) {
    Write-Host "Creating destination folder: $($args.DestinationFolder)" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $args.DestinationFolder | Out-Null
}

Write-Host "DEBUG: Processing source paths..." -ForegroundColor Yellow
for ($i = 0; $i -lt $args.SourcePaths.Count; $i++) {
    $source = $args.SourcePaths[$i]
    $linkName = if ($args.LinkNames.Count -gt $i) { $args.LinkNames[$i] } else { Split-Path -Leaf $source }
    $linkPath = Join-Path -Path $args.DestinationFolder -ChildPath $linkName

    $type = $args.LinkType
    if ($type -eq "auto") {
        $type = if (Test-Path $source -PathType Container) { "directory" }
        elseif (Test-Path $source -PathType Leaf) { "file" }
        else { throw "Source path does not exist: $source" }
    }

    Write-Host "DEBUG: Creating symbolic link - $linkPath -> $source" -ForegroundColor Green
    try {
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $source -Force
        Write-Host "Symbolic link created: $linkPath -> $source" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create symbolic link for $source. Error: $_"
    }
}

Write-Host "DEBUG: Script completed successfully!" -ForegroundColor Green

