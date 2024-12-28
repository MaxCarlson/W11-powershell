# Import the Argument Helper Module
Write-Host "DEBUG: Importing ArgumentHelper module..." -ForegroundColor Yellow
Import-Module -Name "$PSScriptRoot\..\Modules\ArgumentHelperMin.psm1"

# Define the parameters for the script
Write-Host "DEBUG: Defining parameters..." -ForegroundColor Yellow
$parameters = @(
    @{ Name = "SourcePaths"; DefaultValue = @(); Mandatory = $false }
    @{ Name = "DestinationFolder"; DefaultValue = $null; Mandatory = $false }
    @{ Name = "LinkNames"; DefaultValue = @(); Mandatory = $false }
    @{ Name = "LinkType"; DefaultValue = "auto"; Mandatory = $false }
    @{ Name = "DeleteLinks"; DefaultValue = $false; Mandatory = $false }
    @{ Name = "Help"; Aliases = @("--help", "-h", "-?"); DefaultValue = $false; Mandatory = $false }
)

# Help message for the script
Write-Host "DEBUG: Defining help message..." -ForegroundColor Yellow
$helpMessage = @"
Creates or deletes symbolic links and hardlinks for files/folders.

Parameters:
  -SourcePaths        A single source file/folder or a list of files/folders.
                      Required for creating or deleting links.
  -DestinationFolder  The folder where symbolic links should be created.
                      Required for creating links.
  -LinkNames          (Optional) Custom names for the symbolic links.
                      If not provided, the source names are used.
  -LinkType           (Optional) Specify 'file', 'directory', or 'auto' (default: auto).
  -DeleteLinks        (Optional) Deletes the specified links in SourcePaths.
                      Does not remove the original data.
  --help, -h, -?      Display this help message.

Examples:
  Create Symbolic Links:
    .\CreateSymbolicLinks.ps1 -SourcePaths "C:\anime\Show1" -DestinationFolder "C:\TopAnime"

  Delete Symbolic Links:
    .\CreateSymbolicLinks.ps1 -SourcePaths "C:\TopAnime\Show1" -DeleteLinks

  With Custom Names:
    .\CreateSymbolicLinks.ps1 -SourcePaths "C:\anime\Show1" -DestinationFolder "C:\TopAnime" -LinkNames "CustomName"
"@

# Parse the arguments and display help if requested
Write-Host "DEBUG: Starting argument parsing..." -ForegroundColor Yellow
try {
    $args = Get-Arguments -HelpMessage $helpMessage -Parameters $parameters -PassedArgs $PSBoundParameters
    Write-Host "DEBUG: Parsed arguments: $args" -ForegroundColor Green

    if ($args.Help) {
        Write-Host $helpMessage
        return
    }
} catch {
    Write-Host "DEBUG: Exception caught during argument parsing - $($_.Exception.Message)" -ForegroundColor Red
    return
}

# Ensure SourcePaths is provided if deleting or creating links
if (-not $args.SourcePaths.Count) {
    Write-Error "Error: At least one SourcePath must be specified."
    return
}

# Handle link deletion
if ($args.DeleteLinks) {
    Write-Host "DEBUG: Deleting specified links..." -ForegroundColor Yellow
    foreach ($path in $args.SourcePaths) {
        if (-not (Test-Path $path)) {
            Write-Host "Path does not exist: $path" -ForegroundColor Yellow
            continue
        }

        $item = Get-Item $path
        if ($item.Attributes -contains "ReparsePoint") {
            # Handle symbolic link
            Write-Host "Deleting symbolic link: $path" -ForegroundColor Cyan
        } else {
            # Handle hardlink or regular file
            $hardlinkCount = (Get-Item $item.FullName).HardLinkCount
            if ($hardlinkCount -eq 1) {
                $confirmation = Read-Host "This appears to be the last hardlink reference to the file. Are you sure you want to delete it? (y/n)"
                if ($confirmation -notin @("y", "Y")) {
                    Write-Host "Skipping deletion of $path" -ForegroundColor Yellow
                    continue
                }
            }
            Write-Host "Deleting hardlink or regular file: $path" -ForegroundColor Cyan
        }

        # Safely delete the symlink or hardlink
        try {
            Remove-Item -Path $path -Force
            Write-Host "Deleted link: $path" -ForegroundColor Green
        } catch {
            Write-Error "Failed to delete link: $path. Error: $_"
        }
    }

    return
}

# Ensure DestinationFolder is provided for creating links
if (-not $args.DestinationFolder) {
    Write-Error "Error: DestinationFolder must be specified for creating links."
    return
}

# Ensure the destination folder exists
Write-Host "DEBUG: Ensuring destination folder exists..." -ForegroundColor Yellow
if (-not (Test-Path $args.DestinationFolder)) {
    Write-Host "Creating destination folder: $($args.DestinationFolder)" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $args.DestinationFolder | Out-Null
}

# Process each source path for creating links
Write-Host "DEBUG: Processing source paths for link creation..." -ForegroundColor Yellow
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
    } catch {
        Write-Error "Failed to create symbolic link for $source. Error: $_"
    }
}

Write-Host "DEBUG: Script completed successfully!" -ForegroundColor Green
