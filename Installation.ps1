# Install winget
if (-not (Get-Command -Name winget -ErrorAction SilentlyContinue)) {
    Invoke-WebRequest -Uri "https://aka.ms/winget-cli" -OutFile "$env:TEMP\winget-cli.msixbundle"
    Add-AppxPackage -Path "$env:TEMP\winget-cli.msixbundle"
}

# Install packages from installed-packages.txt
$packages = Get-Content -Path "installed-packages.txt"
$adminPrivilegesRequested = $false

foreach ($package in $packages) {
    $packageInfo = winget show -e --id $package

    if ($packageInfo.InstallerType -eq "msixbundle" -and !$adminPrivilegesRequested) {
        Start-Process -FilePath "winget install -e --id $package" -Verb RunAs
        $adminPrivilegesRequested = $true
    }
    else {
        winget install -e --id $package
    }
}

# Check if the W11-powershell specific directory or file exists
$repoPath = Join-Path -Path $PWD -ChildPath "Scripts\Profiles\ProfileCUCH.ps1"

if (-not (Test-Path $repoPath)) {
    Set-Location "$env:USERPROFILE"
    mkdir sources -ErrorAction SilentlyContinue
    Set-Location sources
    git clone https://github.com/MaxCarlson/W11-powershell.git
    Set-Location W11-powershell
}

# Clone the W11-powershell repo if the specific directory or file doesn't exist
$repoPath = "$PWD\Scripts\Profiles\ProfileCUCH.ps1"
if (-not (Test-Path $repoPath)) {
    git clone https://github.com/MaxCarlson/W11-powershell.git "$pwd\W11-powershell"
    Set-Location "$env:USERPROFILE\sources\W11-powershell"
}

Scripts\Profiles\ProfileCUCH.ps1

# Add all subfolders in Scripts (except StartupScripts) to the PATH
$scriptsPath = Join-Path $repoPath "Scripts"
Get-ChildItem $scriptsPath -Directory | Where-Object Name -ne 'StartupScripts' | ForEach-Object {
    $pathToAdd = $_.FullName
    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if (-not ($currentPath -like "*$pathToAdd*")) {
        $newPath = "$currentPath;$pathToAdd"
        [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    }
}

# Setup Task Scheduler to run scripts in StartupScripts at every system startup
$startupScriptsPath = Join-Path $scriptsPath "StartupScripts"
Get-ChildItem $startupScriptsPath -File | ForEach-Object {
    $scriptFullPath = $_.FullName
    $taskName = "Run" + $_.BaseName
    $action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-File `"$scriptFullPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Description "Run script at startup" -User "SYSTEM"
}

Write-Output "Installation and setup complete. Scripts added to PATH and StartupScripts scheduled to run at startup."