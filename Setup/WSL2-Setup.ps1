<#
.SYNOPSIS
    Comprehensive script to install and configure Windows Subsystem for Linux 2 (WSL2),
    install an Ubuntu distribution, and set up an SSH server within Ubuntu for remote access.

.DESCRIPTION
    This PowerShell script automates the setup of a WSL2 environment with SSH capabilities.

    **Key Script Arguments:**
    ---------------------
    -Port <Int32>
        Specifies the TCP port on the Windows host for SSH connections. This port will be
        forwarded to port 22 of the WSL2 Ubuntu instance.
        Alias: -p
        Default: 2222
        Example: .\Setup-WSL2-SSH.ps1 -Port 2022

    -WhatIf
        Shows what actions the script would take without actually executing them.
        This is effectively a "dry run" mode to preview potential changes before they are made.
        Example: .\Setup-WSL2-SSH.ps1 -WhatIf

    -Confirm
        Prompts for confirmation before executing each major change or operation that
        modifies the system. This allows for step-by-step approval.
        Example: .\Setup-WSL2-SSH.ps1 -Confirm

    **Detailed Script Actions:**
    ------------------------
    The script performs the following actions:

    1.  Administrator Privileges Check: Ensures the script is run as an Administrator.
    2.  Enable WSL Features: Verifies and enables necessary Windows features.
    3.  Set WSL Default Version: Configures WSL to use version 2 as the default.
    4.  Install Ubuntu: Installs 'Ubuntu' WSL distribution if not present.
    5.  Install OpenSSH Server: Installs 'openssh-server' in Ubuntu.
    6.  Configure Systemd: **WARNING: This step will overwrite `/etc/wsl.conf` in Ubuntu**
        to ensure `systemd=true` is set under a `[boot]` section. Any previous custom
        configurations in this file will be lost.
    7.  Start SSH Service: Ensures the 'ssh' service (sshd) is running in Ubuntu.
    8.  WSL IP Retrieval: Fetches the IP address of the Ubuntu WSL2 instance.
    9.  Port Proxy Configuration: Creates/updates a Windows port proxy to WSL2.
    10. Firewall Rule Configuration: Creates/updates a Windows Firewall rule.

    The script is designed to be idempotent for most operations.

.PARAMETER Port
    The TCP port on the Windows host that will listen for incoming SSH connections and forward
    them to port 22 of the WSL2 Ubuntu instance.
    Default value: 2222
    Alias: -p

.EXAMPLE
    .\Setup-WSL2-SSH.ps1
    Runs the script with default settings (SSH on Windows host port 2222).

.EXAMPLE
    .\Setup-WSL2-SSH.ps1 -Port 2022
    Configures SSH forwarding from Windows host port 2022.

.EXAMPLE
    .\Setup-WSL2-SSH.ps1 -WhatIf
    Shows what actions would be taken without making changes.

.NOTES
    Author: Gemini AI (with inputs from user)
    Version: 2.7
    Last Modified: 2025-05-18
    For full details on prerequisites, execution policy, post-setup, and troubleshooting,
    run: Get-Help .\Setup-WSL2-SSH.ps1 -Full

.LINK
    Official WSL Documentation: https://docs.microsoft.com/en-us/windows/wsl/
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Alias('p')]
    [int]$Port = 2222
)

function Assert-Administrator {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        Write-Error "Administrator privileges are required. Please re-run this script as an Administrator."
        exit 1
    }
}

function Invoke-WslCommand {
    param(
        [string]$Distribution = "Ubuntu",
        [string]$Command,
        [switch]$AsRoot = $false,
        [string]$ErrorMessage
    )
    Write-Debug "Executing in WSL (${Distribution}): ${Command}"
    $fullCommand = if ($AsRoot) { "sudo --preserve-env=PATH env DEBIAN_FRONTEND=noninteractive $Command" } else { "env DEBIAN_FRONTEND=noninteractive $Command" }
    
    $output = wsl -d $Distribution -- $fullCommand 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $errMsgText = if ($ErrorMessage) { $ErrorMessage } else { "WSL command failed: '${Command}'" }
        Write-Error "${errMsgText} (Exit Code: ${exitCode}). Output: ${output}"
        return $false
    } else {
        Write-Debug "WSL Command Output: ${output}"
    }
    return $true
}

Assert-Administrator

Write-Host "Starting WSL2 and SSH setup..." -ForegroundColor Cyan
Write-Host "Target Windows SSH Port: ${Port}"

# --- Enable WSL Features ---
Write-Debug "Checking WSL features..."
$featuresToEnable = @(
    @{ Name = 'Microsoft-Windows-Subsystem-Linux'; FriendlyName = 'Windows Subsystem for Linux' }
    @{ Name = 'VirtualMachinePlatform'; FriendlyName = 'Virtual Machine Platform' }
)
$restartNeededForFeatures = $false

foreach ($featureInfo in $featuresToEnable) {
    $featureName = $featureInfo.Name
    $friendlyName = $featureInfo.FriendlyName
    $featureState = Get-WindowsOptionalFeature -Online -FeatureName $featureName -ErrorAction SilentlyContinue
    
    if (-not $featureState) {
        Write-Error "Could not query feature '${friendlyName}' (${featureName}). Please ensure DISM tools are available."
        continue
    }
    Write-Debug "Feature '${friendlyName}' (${featureName}): $($featureState.State)"

    if ($featureState.State -eq 'Disabled') {
        Write-Host "Enabling feature '${friendlyName}'..."
        if ($PSCmdlet.ShouldProcess("Windows Feature: ${friendlyName}", "Enable")) {
            Enable-WindowsOptionalFeature -Online -FeatureName $featureName -NoRestart -All | Out-Null
            if ($LASTEXITCODE -ne 0) { # Enable-WindowsOptionalFeature sets $LASTEXITCODE on failure
                Write-Error "Failed to enable feature '${friendlyName}'. Please check the DISM logs (e.g., C:\Windows\Logs\DISM\dism.log)."
            } else {
                Write-Host "Feature '${friendlyName}' enabled."
                $updatedFeatureState = Get-WindowsOptionalFeature -Online -FeatureName $featureName
                if ($updatedFeatureState.RestartNeeded -ne 'No') {
                    $restartNeededForFeatures = $true
                    Write-Warning "A restart is required to complete the enabling of '${friendlyName}'."
                }
            }
        }
    } elseif ($featureState.State -eq 'Enabled' -and $featureState.RestartNeeded -ne 'No') {
        $restartNeededForFeatures = $true
        Write-Warning "Feature '${friendlyName}' is enabled but requires a restart to be fully active."
    }
}

if ($restartNeededForFeatures) {
    Write-Warning "A system restart is recommended for some Windows features to take full effect. Please restart your system if you encounter issues with WSL functionality."
}

# --- Set WSL Default Version to 2 ---
Write-Debug "Setting WSL default version to 2..."
if ($PSCmdlet.ShouldProcess("WSL Configuration", "Set default version to 2")) {
    wsl --set-default-version 2
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to set WSL default version to 2. This might indicate WSL is not properly installed, a WSL update is needed ('wsl --update'), or a restart is pending for Windows Features."
        wsl -l -q > $null
        if ($LASTEXITCODE -ne 0 -and $restartNeededForFeatures) {
            Write-Error "WSL commands are not working. A system restart is likely required to activate WSL features. Please restart and re-run the script."
            exit 1
        }
    } else {
        Write-Debug "WSL default version set to 2."
    }
}

# --- Install Ubuntu if missing ---
$ubuntuDistroName = "Ubuntu"
Write-Debug "Checking if '${ubuntuDistroName}' WSL distribution is installed..."
$installedDistrosOutput = wsl.exe -l --quiet
$distroList = @($installedDistrosOutput | ForEach-Object { $_.Trim() } | Where-Object { $_ })

Write-Debug "Processed list of installed WSL distributions:"
$distroList | ForEach-Object { Write-Debug "- '${_}'" }

if (-not ($distroList -contains $ubuntuDistroName)) {
    Write-Host "'${ubuntuDistroName}' distro not found; installing..."
    if ($PSCmdlet.ShouldProcess("WSL Distribution: ${ubuntuDistroName}", "Install")) {
        wsl --install -d $ubuntuDistroName
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install '${ubuntuDistroName}'. Ensure virtualization is enabled in BIOS/UEFI, and your system is up to date. Try 'wsl --update' first."
            exit 1
        }
        Write-Host "'${ubuntuDistroName}' installed successfully."
    }
} else {
    Write-Debug "'${ubuntuDistroName}' is already installed."
}

# --- Install/Update OpenSSH server inside Ubuntu ---
Write-Host "Ensuring OpenSSH server is installed and updated in '${ubuntuDistroName}'..."
if ($PSCmdlet.ShouldProcess("'${ubuntuDistroName}' packages", "Update and Install openssh-server")) {
    Invoke-WslCommand -Distribution $ubuntuDistroName -Command "apt-get update -y" -AsRoot -ErrorMessage "Failed to update package lists in ${ubuntuDistroName}."
    Invoke-WslCommand -Distribution $ubuntuDistroName -Command "apt-get install -y openssh-server" -AsRoot -ErrorMessage "Failed to install openssh-server in ${ubuntuDistroName}."
}

# --- Configure /etc/wsl.conf for systemd (OVERWRITES FILE) ---
Write-Host "Configuring /etc/wsl.conf for systemd in '${ubuntuDistroName}'..." -ForegroundColor Yellow
Write-Warning "This step will OVERWRITE /etc/wsl.conf in '${ubuntuDistroName}' to ensure 'systemd=true' under '[boot]'."
Write-Warning "Any existing custom configurations in /etc/wsl.conf will be lost."

if ($PSCmdlet.ShouldProcess("'/etc/wsl.conf' in ${ubuntuDistroName}", "Overwrite with systemd=true config")) {
    # Using printf for safer string handling and explicit newlines.
    # The command string for bash. Note: \\n is used because this string is processed by PowerShell first.
    # Bash will receive printf '%s\n%s\n' '[boot]' 'systemd=true' > /etc/wsl.conf
    $wslConfOverwriteCommand = "printf '%s\\n%s\\n' '[boot]' 'systemd=true' > /etc/wsl.conf"
    Write-Debug "Command to set /etc/wsl.conf: ${wslConfOverwriteCommand}"
    
    if (-not (Invoke-WslCommand -Distribution $ubuntuDistroName -Command $wslConfOverwriteCommand -AsRoot -ErrorMessage "Failed to overwrite /etc/wsl.conf.")) {
        Write-Warning "Failed to configure /etc/wsl.conf. Manual configuration may be needed."
    } else {
        Write-Host "/etc/wsl.conf configured for systemd. A WSL restart ('wsl --shutdown') may be required for changes to take effect."
    }
}

# --- Start sshd service inside WSL ---
Write-Host "Ensuring sshd service is running in '${ubuntuDistroName}'..."
$sshCommand = "service ssh status >/dev/null 2>&1; if [ \$? -ne 0 ]; then service ssh start; else service ssh restart; fi && service ssh status"
if ($PSCmdlet.ShouldProcess("'sshd' service in ${ubuntuDistroName}", "Ensure running")) {
    if (-not (Invoke-WslCommand -Distribution $ubuntuDistroName -Command $sshCommand -AsRoot -ErrorMessage "Failed to start or check sshd service.")) {
        Write-Warning "Could not ensure sshd service is running. Manual check inside WSL may be needed: 'sudo service ssh status'"
    }
}

# --- Get WSL IP Address for the specific distribution ---
Write-Debug "Retrieving IP address for '${ubuntuDistroName}'..."
$wslIp = ""
for ($i = 1; $i -le 3; $i++) {
    $wslIp = (wsl -d $ubuntuDistroName -- hostname -I).Trim().Split(' ')[0]
    if ($wslIp) { break }
    Write-Debug "Attempt ${i} to get WSL IP failed. Waiting 2 seconds..."
    Start-Sleep -Seconds 2
}

if (-not $wslIp) {
    Write-Error "Could not retrieve IP address for '${ubuntuDistroName}' after multiple attempts. Ensure it is running and network is configured. You may need to restart WSL ('wsl --shutdown')."
    exit 1
}
Write-Debug "'${ubuntuDistroName}' IP Address: ${wslIp}"

# --- Create/Update Windows Port Proxy ---
$listenAddress = "0.0.0.0"
Write-Host "Configuring port proxy: Windows port ${Port} -> WSL (${ubuntuDistroName}) ${wslIp}:22..."
if ($PSCmdlet.ShouldProcess("Port Proxy for ${listenAddress}:${Port} -> ${wslIp}:22", "Configure")) {
    try {
        $existingProxies = netsh interface portproxy show v4tov4 | Out-String
        $regexPattern = "^\s*${listenAddress}\s+${Port}\s+${wslIp}\s+22\s*$" 
        if ($existingProxies -match $regexPattern) {
            Write-Debug "Port proxy for port ${Port} to ${wslIp}:22 already exists and is correct."
        } else {
            $anyRuleForPortExists = $false
            $existingProxies -split "`r`n" | ForEach-Object {
                if ($_ -match "^\s*${listenAddress}\s+${Port}\s+.*\s+.*$") {
                    $anyRuleForPortExists = $true
                }
            }

            if ($anyRuleForPortExists) {
                Write-Debug "Deleting existing port proxy rule(s) for listen port ${Port} on ${listenAddress}..."
                netsh interface portproxy delete v4tov4 listenaddress=$listenAddress listenport=$Port | Out-Null
                if ($LASTEXITCODE -ne 0) { Write-Warning "Failed to delete old port proxy rule for port ${Port}. This might be okay if it didn't exist." }
            }
            
            Write-Debug "Adding port proxy: Windows port ${Port} -> WSL ${wslIp}:22"
            netsh interface portproxy add v4tov4 listenaddress=$listenAddress listenport=$Port connectaddress=$wslIp connectport=22
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to add port proxy rule. Ensure 'IP Helper' service (iphlpsvc) is running. Command: netsh interface portproxy add v4tov4 listenaddress=${listenAddress} listenport=${Port} connectaddress=${wslIp} connectport=22"
            } else {
                Write-Host "Port proxy rule for ${Port} configured."
            }
        }
    } catch {
        Write-Error "An error occurred during port proxy configuration: $($_.Exception.Message)"
    }
}

# --- Create/Update Firewall Rule ---
$firewallRuleName = "WSL2 SSH Forward (Port ${Port})"
$oldFirewallRuleNamePattern = "WSL2 SSH Forward*" # To catch old generic names if they exist

Write-Host "Configuring firewall rule '${firewallRuleName}' for TCP port ${Port}..."
if ($PSCmdlet.ShouldProcess("Firewall Rule '${firewallRuleName}' for TCP Port ${Port}", "Configure")) {
    try {
        # Clean up potentially conflicting older rules by pattern, if they are not the exact new rule name
        Get-NetFirewallRule -DisplayName $oldFirewallRuleNamePattern -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.DisplayName -ne $firewallRuleName) {
                Write-Debug "Removing potentially old/conflicting firewall rule: $($_.DisplayName)"
                Remove-NetFirewallRule -DisplayName $_.DisplayName -ErrorAction SilentlyContinue
            }
        }

        $existingRule = Get-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue
        if ($existingRule) {
            $currentRulePort = ($existingRule | Get-NetFirewallPortFilter).LocalPort
            if ($currentRulePort -contains $Port.ToString()) {
                Write-Debug "Firewall rule '${firewallRuleName}' for port ${Port} already exists and is correctly configured."
            } else {
                Write-Host "Firewall rule '${firewallRuleName}' exists but for different port(s) ($($currentRulePort -join ',')). Updating to port ${Port}..."
                Set-NetFirewallRule -DisplayName $firewallRuleName -LocalPort $Port -Protocol TCP -Action Allow | Out-Null
                if ($LASTEXITCODE -ne 0) { Write-Warning "Failed to update firewall rule '${firewallRuleName}'." }
            }
        } else {
            Write-Debug "Creating firewall rule '${firewallRuleName}' to allow inbound TCP port ${Port}."
            New-NetFirewallRule -DisplayName $firewallRuleName -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to create firewall rule '${firewallRuleName}'."
            } else {
                Write-Host "Firewall rule '${firewallRuleName}' created."
            }
        }
    } catch {
        Write-Error "An error occurred during firewall rule configuration: $($_.Exception.Message)"
    }
}

Write-Host "--------------------------------------------------------------------" -ForegroundColor Green
Write-Host "WSL2 SSH setup script finished." -ForegroundColor Green
if ($restartNeededForFeatures) {
    Write-Warning "REMINDER: A system restart was indicated as needed for some Windows features."
}
Write-Host "You should now be able to connect to WSL2 (${ubuntuDistroName}) via SSH."
Write-Host "Use a command like: ssh <your-wsl-username>@<your-windows-ip-or-hostname> -p ${Port}"
Write-Host "Example for connecting from the same Windows machine: ssh myuser@localhost -p ${Port}"
Write-Host "If systemd was newly configured by this script, a WSL restart ('wsl --shutdown' in PowerShell, then reopen WSL) might be needed."
Write-Host "--------------------------------------------------------------------" -ForegroundColor Green
