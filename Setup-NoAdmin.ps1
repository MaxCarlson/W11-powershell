# File: Setup-NoAdmin.ps1
# Non-Administrator Setup Script
# Performs user-level configuration only (no package installation, no scheduled tasks)

$ErrorActionPreference = 'Stop'

# --- Script Base Path ---
$ScriptBase = $PSScriptRoot
Write-Host "Setup script running from: $ScriptBase" -ForegroundColor Cyan

# --- Global Variable for Repository Root ---
$env:PWSH_REPO = $ScriptBase
Write-Host "Setting PWSH_REPO environment variable for this session to: $($env:PWSH_REPO)" -ForegroundColor Green

# --- User-Level Environment Variable Setup ---
Write-Host ""
Write-Host "--- Setting user-level environment variables... ---" -ForegroundColor Cyan
try {
    # Set PWSH_REPO permanently at user level
    [System.Environment]::SetEnvironmentVariable('PWSH_REPO', $ScriptBase, [System.EnvironmentVariableTarget]::User)
    Write-Host "OK: Set PWSH_REPO user environment variable: $ScriptBase" -ForegroundColor Green
} catch {
    Write-Warning "Could not set user environment variable: $_"
}

# --- Profile Linking ---
Write-Host ""
Write-Host "--- Setting up PowerShell profile link... ---" -ForegroundColor Cyan
$linkScript = Join-Path $ScriptBase "Profiles\HardLinkProfile.ps1"
if (Test-Path $linkScript) {
    $currentProfile = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

    # Check if profile already points to CustomProfile.ps1
    if (Test-Path $currentProfile) {
        $item = Get-Item $currentProfile -ErrorAction SilentlyContinue
        if ($item.LinkType -eq 'HardLink') {
            Write-Host "OK: Profile already hard-linked" -ForegroundColor Green
        } else {
            Write-Host "Profile exists but not linked. Running HardLinkProfile.ps1..." -ForegroundColor Yellow
            & $linkScript -Replace 'y'
        }
    } else {
        Write-Host "Creating profile link..." -ForegroundColor Yellow
        & $linkScript
    }
} else {
    Write-Warning "HardLinkProfile.ps1 not found at: $linkScript"
    Write-Host "You can manually create the link later by running:" -ForegroundColor Yellow
    Write-Host "  .\Profiles\HardLinkProfile.ps1" -ForegroundColor Yellow
}

# --- Update CustomProfile.ps1 Path Detection ---
Write-Host ""
Write-Host "--- Checking CustomProfile.ps1 path configuration... ---" -ForegroundColor Cyan
$customProfile = Join-Path $ScriptBase "Profiles\CustomProfile.ps1"
if (Test-Path $customProfile) {
    Write-Host "OK: CustomProfile.ps1 uses dynamic path detection" -ForegroundColor Green
} else {
    Write-Warning "CustomProfile.ps1 not found at: $customProfile"
}

# --- Integration with scripts repo ---
Write-Host ""
Write-Host "--- Checking integration with scripts repo... ---" -ForegroundColor Cyan
$scriptsDir = Join-Path (Split-Path $ScriptBase -Parent) "scripts"
if (Test-Path $scriptsDir) {
    Write-Host "OK: Found scripts repo at: $scriptsDir" -ForegroundColor Green

    # Check if scripts setup has been run
    $scriptsVenv = Join-Path $scriptsDir ".venv"
    if (Test-Path $scriptsVenv) {
        Write-Host "OK: Scripts repo venv exists" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Scripts repo venv not found. Run bootstrap in scripts repo:" -ForegroundColor Yellow
        Write-Host "  cd $scriptsDir" -ForegroundColor Yellow
        Write-Host "  .\bootstrap.ps1 -v" -ForegroundColor Yellow
    }

    # Check if dotfiles dynamic configs exist
    $dotfilesDir = Join-Path (Split-Path $ScriptBase -Parent) "dotfiles"
    if (Test-Path $dotfilesDir) {
        $dynamicDir = Join-Path $dotfilesDir "dynamic"
        if (Test-Path $dynamicDir) {
            Write-Host "OK: Found dotfiles dynamic configs at: $dynamicDir" -ForegroundColor Green

            # List what's available
            $configs = @(
                "setup_pyscripts_aliases.ps1"
                "setup_pyscripts_functions.ps1"
                "venv_auto_activation.ps1"
            )
            foreach ($cfg in $configs) {
                $cfgPath = Join-Path $dynamicDir $cfg
                if (Test-Path $cfgPath) {
                    Write-Host "  OK: $cfg" -ForegroundColor DarkGreen
                } else {
                    Write-Host "  MISSING: $cfg" -ForegroundColor DarkGray
                }
            }
        } else {
            Write-Host "WARNING: Dotfiles dynamic directory not found" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "Scripts repo not found at expected location: $scriptsDir" -ForegroundColor DarkGray
}

# --- Environment Check ---
Write-Host ""
Write-Host "--- Environment Check ---" -ForegroundColor Cyan
$tools = @{
    "oh-my-posh" = "Oh My Posh (prompt theme)"
    "eza" = "Modern replacement for ls"
    "zoxide" = "Smarter cd command"
    "fnm" = "Fast Node Manager"
    "git" = "Git"
    "python" = "Python"
}

$missingTools = @()
foreach ($tool in $tools.Keys) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Host "  OK: $tool - $($tools[$tool])" -ForegroundColor Green
    } else {
        Write-Host "  MISSING: $tool - $($tools[$tool])" -ForegroundColor DarkGray
        $missingTools += $tool
    }
}

# --- Optional Tool Installation ---
if ($missingTools.Count -gt 0) {
    Write-Host ""
    Write-Host "--- Optional Tool Installation ---" -ForegroundColor Cyan
    Write-Host "Missing tools detected: $($missingTools -join ', ')" -ForegroundColor Yellow
    $installTools = Read-Host "Install missing tools via winget? (y/N)"

    if ($installTools -eq 'y') {
        $wingetPackages = @{
            "oh-my-posh" = "JanDeDobbeleer.OhMyPosh"
            "eza" = "eza-community.eza"
            "zoxide" = "ajeetdsouza.zoxide"
            "fnm" = "Schniz.fnm"
            "git" = "Git.Git"
        }

        foreach ($tool in $missingTools) {
            if ($wingetPackages.ContainsKey($tool)) {
                Write-Host "Installing $tool..." -ForegroundColor Cyan
                try {
                    winget install --id $wingetPackages[$tool] -e --silent --accept-package-agreements --accept-source-agreements
                    Write-Host "  OK: $tool installed" -ForegroundColor Green
                } catch {
                    Write-Warning "Failed to install $tool : $_"
                }
            }
        }

        # Configure oh-my-posh themes path if installed
        if ($missingTools -contains "oh-my-posh" -and (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
            Write-Host "Configuring oh-my-posh themes..." -ForegroundColor Cyan
            $themesPath = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
            if (Test-Path $themesPath) {
                [System.Environment]::SetEnvironmentVariable('POSH_THEMES_PATH', $themesPath, [System.EnvironmentVariableTarget]::User)
                Write-Host "  OK: POSH_THEMES_PATH set to $themesPath" -ForegroundColor Green
            }
        }

        Write-Host ""
        Write-Host "Tools installed. Restart PowerShell to use them." -ForegroundColor Yellow
    }
}

# --- Final Instructions ---
Write-Host ""
Write-Host "--- Setup Complete (Non-Admin Mode) ---" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Close and reopen PowerShell to load the new profile" -ForegroundColor Yellow
Write-Host "  2. Your custom modules will auto-load from: $ScriptBase\Config\Modules\" -ForegroundColor Yellow
Write-Host "  3. To enable venv auto-activation, ensure scripts repo is set up" -ForegroundColor Yellow
Write-Host ""
Write-Host "To run admin-only setup (packages, scheduled tasks, WSL):" -ForegroundColor Cyan
Write-Host "  Run: .\Setup.ps1 (as Administrator)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Environment variables set:" -ForegroundColor Cyan
Write-Host "  PWSH_REPO = $ScriptBase" -ForegroundColor Yellow

# --- Optional: Test Profile Load ---
Write-Host ""
$testProfile = Read-Host "Test load the custom profile now? (y/N)"
if ($testProfile -eq 'y') {
    Write-Host ""
    Write-Host "Testing profile load..." -ForegroundColor Cyan
    try {
        . "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        Write-Host "OK: Profile loaded successfully!" -ForegroundColor Green
    } catch {
        Write-Warning "Profile load failed: $_"
        Write-Host "Check the profile for errors." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "--- Done ---" -ForegroundColor Green
