<#
.SYNOPSIS
    Installs Chocolatey, Cygwin base, downloads Cygwin setup, and installs Rust (rustup).
.DESCRIPTION
    - Checks for `choco` and installs via the official PowerShell script if missing.
    - Checks for Cygwin (`bash.exe`), installs base via WinGet if missing, then downloads setup-x86_64.exe.
    - Checks for `rustup` and installs via WinGet if missing; adds .cargo/bin to session PATH.
#>

# --- Chocolatey ---
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "Chocolatey installation command executed."
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Warning "Chocolatey installation might have failed or requires a new shell. Please check manually."
        }
    } catch {
        Write-Error "Failed to download or run Chocolatey install script: $_"
    }
} else {
    Write-Host "Chocolatey is already installed."
}

# --- Cygwin ---
$cygwinBasePath = 'C:\cygwin64'
$cygwinBashPath = Join-Path $cygwinBasePath 'bin\bash.exe'
$cygwinSetupExePath = Join-Path $cygwinBasePath 'setup-x86_64.exe'

if (-not (Test-Path $cygwinBashPath)) {
    Write-Host "Cygwin not found at $cygwinBashPath. Installing Cygwin base via WinGet..."
    try {
        winget install --id=Cygwin.Cygwin --exact -e --accept-package-agreements --accept-source-agreements
        if (-not (Test-Path $cygwinBashPath)) {
            Write-Warning "Cygwin installation via winget may have failed or installed to a different location."
        }
    } catch {
        Write-Error "Failed to install Cygwin using winget: $_"
    }
} else {
    Write-Host "Cygwin bash.exe found at $cygwinBashPath."
}

if (Test-Path $cygwinBasePath -and -not (Test-Path $cygwinSetupExePath)) {
    Write-Host "Downloading the official Cygwin setup program to $cygwinSetupExePath..."
    try {
        Invoke-WebRequest -Uri 'https://cygwin.com/setup-x86_64.exe' -OutFile $cygwinSetupExePath
        Write-Host "Cygwin setup downloaded."
    } catch {
        Write-Error "Failed to download Cygwin setup-x86_64.exe: $_"
    }
} elseif (Test-Path $cygwinSetupExePath) {
    Write-Host "Cygwin setup-x86_64.exe already exists at $cygwinSetupExePath."
} else {
    Write-Warning "Cygwin base directory $cygwinBasePath not found. Cannot download setup.exe."
}


# --- Rust (Rustup) ---
if (-not (Get-Command rustup -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Rust (rustup) via WinGet..."
    try {
        winget install --id Rustlang.Rustup -e --accept-package-agreements --accept-source-agreements
        Write-Host "Rustup installation command executed."
        # Rustup usually prompts for installation options. This unattended install might choose defaults.
        # Attempt to add .cargo/bin to the current session's PATH
        $cargoBinPath = Join-Path $env:USERPROFILE ".cargo\bin"
        if (Test-Path $cargoBinPath -and -not (($env:PATH -split ';') -contains $cargoBinPath)) {
            Write-Host "Adding $cargoBinPath to current session PATH."
            $env:PATH = "$($cargoBinPath);$($env:PATH)"
            Write-Host "If 'cargo' command is not found, a new terminal or sourcing profile might be needed after rustup finishes its own setup."
        }
         if (-not (Get-Command rustup -ErrorAction SilentlyContinue)) {
            Write-Warning "Rustup installation might have failed or requires a new shell/PATH update. Please check manually."
        }
    } catch {
        Write-Error "Failed to install Rust (rustup) using winget: $_"
    }
} else {
    Write-Host "Rust (rustup) is already installed."
    # Ensure .cargo/bin is in path for the current session if it's not already
    $cargoBinPath = Join-Path $env:USERPROFILE ".cargo\bin"
    if (Test-Path $cargoBinPath -and -not (($env:PATH -split ';') -contains $cargoBinPath)) {
        Write-Host "Adding $cargoBinPath to current session PATH."
        $env:PATH = "$($cargoBinPath);$($env:PATH)"
    }
}

Write-Host "Package manager checks complete."
