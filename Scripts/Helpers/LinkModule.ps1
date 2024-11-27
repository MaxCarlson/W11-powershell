param (
    [Parameter(Mandatory = $true)]
    [string]$ModulePath,                # Full or relative path to the module source folder
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("user", "system")]
    [string]$TargetLocation,            # 'user' or 'system' for target directory

    [Parameter(Mandatory = $true)]
    [ValidateSet("symbolic", "hard")]
    [string]$LinkType                   # 'symbolic' or 'hard' for link type
)

# Resolve the absolute path of the source module
$resolvedModulePath = Resolve-Path -Path $ModulePath -ErrorAction Stop

# Define user and system module directories
$userModulesDir = "$HOME\Documents\PowerShell\Modules"
$systemModulesDir = "C:\Program Files\WindowsPowerShell\Modules"
$targetModulesDir = if ($TargetLocation -eq "user") { $userModulesDir } else { $systemModulesDir }

# Validate the resolved source module path
if (-not (Test-Path $resolvedModulePath)) {
    Write-Host "Error: Module path '$resolvedModulePath' does not exist." -ForegroundColor Red
    exit 1
}

# Extract the module name from the path
$moduleName = Split-Path -Leaf $resolvedModulePath
$targetPath = Join-Path -Path $targetModulesDir -ChildPath $moduleName

# Check if the module already exists in the target location
if (Test-Path $targetPath) {
    Write-Host "Error: Module '$moduleName' already exists in $targetModulesDir." -ForegroundColor Yellow
    exit 1
}

# Ensure the target directory exists
if (-not (Test-Path $targetModulesDir)) {
    Write-Host "Creating target directory: $targetModulesDir" -ForegroundColor Green
    New-Item -Path $targetModulesDir -ItemType Directory -Force
}

# Create the appropriate link
try {
    if ($LinkType -eq "symbolic") {
        # Create a symbolic link (supports relative or absolute paths)
        New-Item -Path $targetPath -ItemType SymbolicLink -Value $resolvedModulePath -Force
        Write-Host "Symbolic link created: $moduleName -> $targetPath" -ForegroundColor Green
    } elseif ($LinkType -eq "hard") {
        # Create a hard link (only works for individual files, not directories)
        cmd /c "mklink /h `"$targetPath`" `"$resolvedModulePath`""
        Write-Host "Hard link created: $moduleName -> $targetPath" -ForegroundColor Green
    }
} catch {
    Write-Host "Error creating link: $_" -ForegroundColor Red
    exit 1
}
