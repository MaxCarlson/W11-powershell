#Set-Location ~
# Example Setup Script
#mkdir sources
#Set-Location sources
#
#gh repo clone W11-powershell
# Example Setup Script with Fixes

.\Scripts\SetupScripts\StartSSHAgent.ps1
.\Scripts\SetupScripts\ProgramBackup.ps1 -Setup -BackupFrequency Daily -UpdateFrequency Daily

# Define the modules to link
#$modulesToLink = @(
#    @{ Path = ".\Modules\Coloring.psm1"; LinkType = "hard"; Target = "user" }
#    @{ Path = ".\Modules\Installer.psm1"; LinkType = "hard"; Target = "user" }
#    @{ Path = ".\Modules\SessionTools.psm1"; LinkType = "hard"; Target = "user" }
#    @{ Path = ".\Modules\Downloader.psm1"; LinkType = "hard"; Target = "user" }
#    @{ Path = ".\Modules\Extractor.psm1"; LinkType = "hard"; Target = "user" }
#    @{ Path = ".\Modules\PathManager.psm1"; LinkType = "hard"; Target = "user" }
#    @{ Path = ".\Modules\Add-ToPath.psm1"; LinkType = "hard"; Target = "user" }
#    @{ Path = ".\Modules\LinkManager.psm1"; LinkType = "hard"; Target = "user" }
#    @{ Path = ".\Modules\BackupAndRestore.psm1"; LinkType = "hard"; Target = "user" }
#    @{ Path = ".\Modules\HelpModule.psm1"; LinkType = "hard"; Target = "user" }
)

# PowerShell Modules path
$userModulesPath = "${env:USERPROFILE}\Documents\PowerShell\Modules"

foreach ($module in $modulesToLink) {
    # Ensure $module.Path is valid
    if (-not (Test-Path -Path $module.Path)) {
        Write-Host "Error: Module path '$($module.Path)' does not exist." -ForegroundColor Red
        continue
    }

    # Get the module name from the file name
    $moduleName = (Get-Item $module.Path).BaseName
    $moduleTargetPath = Join-Path -Path $userModulesPath -ChildPath $moduleName

    # Ensure the target folder exists
    if (-not (Test-Path -Path $moduleTargetPath)) {
        New-Item -ItemType Directory -Path $moduleTargetPath -Force | Out-Null
        Write-Host "Created directory for module: $moduleTargetPath" -ForegroundColor Cyan
    }

    # Create a hard link for the .psm1 file inside the target folder
    $targetLinkPath = Join-Path -Path $moduleTargetPath -ChildPath "$moduleName.psm1"
    if (-not (Test-Path -Path $targetLinkPath)) {
        New-Item -ItemType HardLink -Path $targetLinkPath -Target $module.Path
        Write-Host "Linked module $($module.Path) to $targetLinkPath successfully." -ForegroundColor Green
    } else {
        Write-Host "Hard link for module $moduleName already exists. Skipping." -ForegroundColor Yellow
    }

    # Import the module to ensure it's available in the current session
    if (-not (Get-Module -Name $moduleName -ListAvailable)) {
        try {
            Import-Module -Name $targetLinkPath
            Write-Host "Imported Module $moduleName successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to import module $moduleName. Error: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Module '$moduleName' already exists. Skipping import." -ForegroundColor Yellow
    }
}

# Setup any & all Executable scripts in bin/
& "${PWSH_REPO}/Setup/SetupExecutables.ps1"


# ── Ensure package managers and export current package lists ──
. "$PSScriptRoot\Setup\Ensure-PackageManagers.ps1"
# ── Package-list management & installation ──
. "$PSScriptRoot\Setup\Install-Packages.ps1"


# Recursively get a list of SetupSchedule.ps1 files
$setupFiles = Get-ChildItem -Path $baseDirectory -Filter "Scripts\MoveFiles\SetupSchedule.ps1" -Recurse

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

return

# Ensure package managers are installed
#Install-WingetPackageManager
#Install-ChocolateyPackageManager
#Install-ScoopPackageManager

# Install programs
$Programs = @(
    @{ Name = "fzf"; WingetID = "junegunn.fzf"; ChocoID = "fzf"; ScoopID = "fzf"; Module = "" },
    @{ Name = "PSFzf"; WingetID = ""; ChocoID = ""; ScoopID = ""; Module = "PSFzf" },
    @{ Name = "ZLocation"; WingetID = ""; ChocoID = ""; ScoopID = ""; Module = "ZLocation" },
    @{ Name = "eza"; WingetID = "eza.eza"; ChocoID = ""; ScoopID = "eza"; Module = "" },
    @{ Name = "Atuin"; WingetID = ""; ChocoID = ""; ScoopID = "atuin"; Module = "" },
    @{ Name = "direnv"; WingetID = "Direnv.Direnv"; ChocoID = "direnv"; ScoopID = "direnv"; Module = "" },
    @{ Name = "PSReadLine"; WingetID = ""; ChocoID = ""; ScoopID = ""; Module = "PSReadLine" },
    @{ Name = "posh-git"; WingetID = ""; ChocoID = ""; ScoopID = ""; Module = "posh-git" },
    @{ Name = "oh-my-posh"; WingetID = "JanDeDobbeleer.OhMyPosh"; ChocoID = "oh-my-posh"; ScoopID = "oh-my-posh"; Module = "" },
    @{ Name = "Terminal-Icons"; WingetID = ""; ChocoID = ""; ScoopID = ""; Module = "Terminal-Icons" },
    @{ Name = "BurntToast"; WingetID = ""; ChocoID = ""; ScoopID = ""; Module = "BurntToast" },
    @{ Name = "PSPing"; WingetID = ""; ChocoID = "psping"; ScoopID = "psping"; Module = "" },
    @{ Name = "Git"; WingetID = "Git.Git"; ChocoID = "git"; ScoopID = "git"; Module = "" },
    @{ Name = "PSScriptAnalyzer"; WingetID = ""; ChocoID = ""; ScoopID = ""; Module = "PSScriptAnalyzer" },
    @{ Name = "TabExpansionPlusPlus"; WingetID = ""; ChocoID = ""; ScoopID = ""; Module = "TabExpansionPlusPlus" }
)

foreach ($Program in $Programs) {
    Install-Program -ProgramName $Program.Name `
                    -WingetID $Program.WingetID `
                    -ChocoID $Program.ChocoID `
                    -ScoopID $Program.ScoopID `
                    -PowerShellModuleName $Program.Module
}

Write-Color -Message "All programs are now installed and up-to-date." -Type "Success"

return
