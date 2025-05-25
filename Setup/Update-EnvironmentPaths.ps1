<#
.SYNOPSIS
    Adds necessary directories to the Windows User PATH if not already present and if the directory exists.
.DESCRIPTION
    This script ensures that commonly used command-line tools installed by package managers
    are accessible from the command line by adding their directories to the User PATH.
    It only adds paths that physically exist on the system.
    It also updates the current session's $env:PATH.
#>

function Add-PathToUserEnvironment {
    param(
        [string]$PathToAdd,
        [string]$PathNameForLog = $PathToAdd 
    )

    if (-not (Test-Path $PathToAdd -PathType Container)) { 
        Write-Host "Path to add for '$PathNameForLog' does not exist or is not a directory: '$PathToAdd'. Skipping." -ForegroundColor Yellow
        return $false
    }

    $currentUserPathString = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $pathArray = $currentUserPathString -split ';' | ForEach-Object { $_.TrimEnd('\/') } | Where-Object { $_.Trim() -ne "" }
    $normalizedPathToAdd = $PathToAdd.TrimEnd('\/')

    if ($pathArray -contains $normalizedPathToAdd) {
        Write-Host "$PathNameForLog ('$normalizedPathToAdd') is already in the User PATH."
    } else {
        Write-Host "Adding $PathNameForLog ('$normalizedPathToAdd') to User PATH."
        $newPathString = ($pathArray + $normalizedPathToAdd) -join ';' # Add the normalized one for consistency in the PATH string
        try {
            [System.Environment]::SetEnvironmentVariable("Path", $newPathString, "User")
            Write-Host "$PathNameForLog added to User PATH. A new terminal session may be required for changes to take full effect." -ForegroundColor Green

            if (-not (($env:PATH -split ';' | ForEach-Object { $_.TrimEnd('\/') }) -contains $normalizedPathToAdd)) {
                $env:PATH = "$PathToAdd;$($env:PATH)" # Prepend original $PathToAdd to current session
                Write-Host "$PathNameForLog added to current session's PATH." -ForegroundColor Green
            }
            return $true 
        } catch {
            Write-Error "Failed to set User PATH environment variable for $PathNameForLog: $($_.Exception.Message)"
            return $false
        }
    }
    return $false 
}

Write-Host "Updating environment paths..."
$global:pathUpdateOccurredInScript = $false 

# --- Standard Paths Managed by This Script ---

# Cygwin Bin
$cygwinBinPath = 'C:\cygwin64\bin'
if (Add-PathToUserEnvironment -PathToAdd $cygwinBinPath -PathNameForLog "Cygwin Bin") {
    $global:pathUpdateOccurredInScript = $true
}

# Rust Cargo Bin
$cargoBinPath = Join-Path $env:USERPROFILE ".cargo\bin"
if (Add-PathToUserEnvironment -PathToAdd $cargoBinPath -PathNameForLog "Rust Cargo Bin") {
    $global:pathUpdateOccurredInScript = $true
}

# Scoop Shims
$scoopShimsPath = Join-Path $env:USERPROFILE "scoop\shims"
if (Add-PathToUserEnvironment -PathToAdd $scoopShimsPath -PathNameForLog "Scoop Shims") {
    $global:pathUpdateOccurredInScript = $true
}

# Chocolatey Bin (ProgramData)
$chocoBinPath = Join-Path $env:ProgramData "chocolatey\bin" 
if (Add-PathToUserEnvironment -PathToAdd $chocoBinPath -PathNameForLog "Chocolatey Bin") {
    $global:pathUpdateOccurredInScript = $true
}

# User's Local WindowsApps (shims for Store apps etc.)
$userWindowsAppsPath = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps"
if (Add-PathToUserEnvironment -PathToAdd $userWindowsAppsPath -PathNameForLog "User WindowsApps") {
    $global:pathUpdateOccurredInScript = $true
}

# Winget Links (shims for Winget packages)
$wingetLinksPath = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links"
if (Add-PathToUserEnvironment -PathToAdd $wingetLinksPath -PathNameForLog "Winget Links") {
    $global:pathUpdateOccurredInScript = $true
}

# Custom W11-PowerShell Scripts Bin Path
# Assuming $env:PWSH_REPO is set by the parent Setup.ps1 script
if ($env:PWSH_REPO) {
    $customScriptsBinPath = Join-Path $env:PWSH_REPO "bin"
    if (Add-PathToUserEnvironment -PathToAdd $customScriptsBinPath -PathNameForLog "W11-PowerShell Scripts Bin") {
        $global:pathUpdateOccurredInScript = $true
    }
} else {
    Write-Warning "\$env:PWSH_REPO not defined. Cannot evaluate W11-PowerShell scripts bin path for PATH addition."
}

# Custom C:\Tools\min Path (if you use this convention)
$customToolsMinPath = "C:\Tools\min" 
if (Add-PathToUserEnvironment -PathToAdd $customToolsMinPath -PathNameForLog "Custom C:\Tools\min") {
    $global:pathUpdateOccurredInScript = $true
}

# --- Final Broadcast ---
if ($global:pathUpdateOccurredInScript) {
    Write-Warning "PATH has been updated. Please open a new terminal or re-source your profile for these changes to be effective in all new sessions."
    
    try {
        if (-not ([System.Management.Automation.PSTypeName]'BroadcastSettingChange').Type) {
            Add-Type -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;
            public class BroadcastSettingChange {
                [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
                public static extern IntPtr SendMessageTimeout(
                    IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
                    uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
                
                public static readonly IntPtr HWND_BROADCAST = new IntPtr(0xffff);
                public const uint WM_SETTINGCHANGE = 0x001A;
                public const uint SMTO_ABORTIFHUNG = 0x0002;
            }
"@ -ErrorAction SilentlyContinue 
        }

        if ([BroadcastSettingChange]::SendMessageTimeout(
                [BroadcastSettingChange]::HWND_BROADCAST,
                [BroadcastSettingChange]::WM_SETTINGCHANGE,
                [UIntPtr]::Zero, "Environment", 
                [BroadcastSettingChange]::SMTO_ABORTIFHUNG, 
                5000, 
                [out][UIntPtr]::Zero) -ne [IntPtr]::Zero) { 
            Write-Host "Successfully broadcast environment setting change." -ForegroundColor DarkCyan
        } else {
            Write-Warning "Failed to broadcast environment setting change or timed out. Return code: $([System.Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        }
    } catch {
        Write-Warning "An exception occurred while attempting to broadcast environment setting change: $($_.Exception.Message)"
    }
} else {
    Write-Host "No User PATH updates were necessary for the configured directories."
}

Write-Host "Environment path update process finished."
