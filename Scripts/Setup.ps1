#Set-Location ~
# Example Setup Script
#mkdir sources
#Set-Location sources
#
#gh repo clone W11-powershell
# Example Setup Script with Fixes

.\SetupScripts\StartSSHAgent.ps1

$modulesToLink = @(
    @{ Path = ".\Modules\Coloring.psm1"; LinkType = "hard"; Target = "user" }
    @{ Path = ".\Modules\Installer.psm1"; LinkType = "hard"; Target = "user" }
    @{ Path = ".\Modules\SessionTools.psm1"; LinkType = "hard"; Target = "user" }
    @{ Path = ".\Modules\Downloader.psm1"; LinkType = "hard"; Target = "user" }
    @{ Path = ".\Modules\Extractor.psm1"; LinkType = "hard"; Target = "user" }
    @{ Path = ".\Modules\PathManager.psm1"; LinkType = "hard"; Target = "user" }
)

foreach ($module in $modulesToLink) {
    # Ensure $module.Path is valid
    if (-not (Test-Path -Path $module.Path)) {
        Write-Host "Error: Module path '$($module.Path)' does not exist." -ForegroundColor Red
        continue
    }

    # Call the LinkModule.ps1 script with arguments
    try {
        & ".\Helpers\LinkModule.ps1" -ModulePath $module.Path -TargetLocation $module.Target -LinkType $module.LinkType
        Write-Host "Linked module $($module.Path) successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to link module $($module.Path). Error: $_" -ForegroundColor Red
        continue
    }

    # Check if the module is already imported
    $moduleName = (Get-Item $module.Path).BaseName
    if (-not (Get-Module -Name $moduleName -ListAvailable)) {
        try {
            Import-Module -Name $module.Path
            Write-Host "Imported Module $moduleName successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to import module $moduleName. Error: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Module '$moduleName' already exists. Skipping import." -ForegroundColor Yellow
    }
}

# Ensure package managers are installed
#Install-WingetPackageManager
Install-ChocolateyPackageManager
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
