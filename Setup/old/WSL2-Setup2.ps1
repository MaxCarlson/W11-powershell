<#
.SYNOPSIS
Configures Windows-side prerequisites for WSL2 and SSH access, including feature installation,
distribution installation, port proxy, and firewall rule.
Supports dry runs via the -WhatIf common parameter.

.DESCRIPTION
This script performs Windows-side setup tasks to prepare for SSH access to a WSL2 distribution. It will:
  - Ensure Windows features for WSL2 (Subsystem for Linux & Virtual Machine Platform) are enabled.
  - Check and set WSL default version to 2 if not already set.
  - Install the specified Linux distribution (default: Ubuntu) if missing.
  - Create a Windows port proxy to forward a chosen Windows host port (default: 2222) into the
    WSL2 distribution's SSH port (default: 22, configurable with -WslSshPort).
  - Create a Windows Firewall rule to allow inbound connections on the Windows host port.

This script DOES NOT install or configure the SSH server (sshd) inside the WSL distribution,
nor does it configure /etc/wsl.conf (e.g., for systemd). Those steps must be performed
separately within the WSL distribution.

Use the -WhatIf common parameter to see what changes would be made without actually executing them.

.PARAMETER Port
The TCP port on the Windows host to listen on for SSH connections.
Default: 2222
Aliases: -p

.PARAMETER WslSshPort
The TCP port number that the SSH server is expected to be listening on *inside* the WSL distribution.
This is the port the Windows port proxy will connect to.
Default: 22
Aliases: -wp, -wslport

.PARAMETER DistroName
The name of the WSL distribution to install (if missing) and target for IP retrieval.
Default: Ubuntu
Aliases: -d

.EXAMPLE
# Run the Windows-side setup with default settings
.\Setup-WSL2-Prereqs.ps1

.EXAMPLE
# Run with a custom Windows host port and specify a different WSL distribution
.\Setup-WSL2-Prereqs.ps1 -Port 2022 -DistroName "Debian"

.EXAMPLE
# Specify that the SSH server inside WSL will be listening on port 2223 for the port proxy
.\Setup-WSL2-Prereqs.ps1 -WslSshPort 2223

.EXAMPLE
# Perform a dry run to see what actions would be taken
.\Setup-WSL2-Prereqs.ps1 -WhatIf

.NOTES
Run this script as an Administrator.
The port proxy relies on the WSL IP at the time of creation. If the WSL IP changes, the proxy may
need to be updated (e.g., by re-running this script or manually updating the netsh rule).
After running this script, you will need to:
1. Install and configure an SSH server (e.g., OpenSSH) inside your WSL distribution.
2. Ensure the SSH server in WSL is configured to listen on the port specified by -WslSshPort.
3. Ensure your WSL user is set up for SSH access (e.g., with public key authentication).
The -WhatIf common parameter allows you to see the operations the script would perform without
actually making any changes to your system.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(HelpMessage = "The TCP port on the Windows host to listen on for SSH connections. Default: 2222")]
    [Alias('p')]
    [int]$Port = 2222,

    [Parameter(HelpMessage = "The TCP port number that the SSH server is expected to be listening on *inside* the WSL distribution. Default: 22")]
    [Alias('wp', 'wslport')]
    [int]$WslSshPort = 22,

    [Parameter(HelpMessage = "The name of the WSL distribution to install and configure. Default: Ubuntu")]
    [Alias('d')]
    [string]$DistroName = "Ubuntu"
)

# Function to assert administrator privileges
function Assert-Administrator {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        Write-Error "Administrator privileges are required. Please re-run this script as an Administrator."
        exit 1 # Exit with a non-zero status code for error
    }
}

# Call the function to check for admin rights
Assert-Administrator

Write-Verbose "Starting Windows-side WSL2 SSH Prerequisite Setup for distribution: ${DistroName} on Windows port: ${Port}, targeting WSL SSH port: ${WslSshPort}"
if ($PSCmdlet.ShouldProcess("System", "Verify Windows prerequisites and configure network for WSL2 SSH access")) {
    # Section 1: Enable WSL Features
    Write-Verbose "Checking required Windows features..."
    $requiredFeatures = @('Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform')
    $featuresToEnable = @()

    foreach ($featureName in $requiredFeatures) {
        try {
            $feature = Get-WindowsOptionalFeature -Online -FeatureName $featureName -ErrorAction Stop
            Write-Debug "Feature '${featureName}' state: ${feature.State}"
            if ($feature.State -eq 'Disabled') {
                $featuresToEnable += $featureName
            }
        }
        catch {
            Write-Error "Failed to query feature '${featureName}'. Error: $($_.Exception.Message)"
        }
    }

    if ($featuresToEnable.Count -gt 0) {
        $featureList = $featuresToEnable -join ', '
        Write-Host "Enabling required Windows features: ${featureList}..."
        if ($PSCmdlet.ShouldProcess("System", "Enable Windows features: ${featureList}")) {
            foreach ($featureName in $featuresToEnable) {
                try {
                    Enable-WindowsOptionalFeature -Online -FeatureName $featureName -NoRestart -All -ErrorAction Stop | Out-Null
                    Write-Host "Feature '${featureName}' enabled. A system restart might be required for these changes to take full effect."
                }
                catch {
                    Write-Error "Failed to enable feature '${featureName}'. Error: $($_.Exception.Message). Manual intervention may be required."
                }
            }
        }
    } else {
        Write-Verbose "Required Windows features are already enabled or state could not be determined as disabled."
    }

    # Section 2: Set WSL Default Version to 2
    Write-Verbose "Checking WSL default version..."
    $wslDefaultVersion = -1 # Initialize with an invalid version
    try {
        $lxssKey = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss" -ErrorAction SilentlyContinue
        # Corrected property check:
        if ($lxssKey -and ($null -ne $lxssKey.DefaultVersion)) {
            $wslDefaultVersion = $lxssKey.DefaultVersion
        } else {
            # Fallback: try parsing wsl --status if registry key is not found or lacks DefaultVersion
            $wslStatusOutput = wsl --status 2>&1 | Out-String
            if ($wslStatusOutput -match "Default version:\s*(\d)") {
                $wslDefaultVersion = [int]$Matches[1]
            } else {
                 Write-Debug "Could not determine WSL default version from 'wsl --status' output."
            }
        }
        Write-Debug "Current WSL default version detected as: ${wslDefaultVersion}"
    }
    catch {
        Write-Warning "Could not reliably determine WSL default version. Attempting to set it to 2. Error: $($_.Exception.Message)"
        $wslDefaultVersion = -1 
    }

    if ($wslDefaultVersion -ne 2) {
        Write-Host "Setting WSL default version to 2..."
        if ($PSCmdlet.ShouldProcess("WSL Configuration", "Set default version to 2")) {
            try {
                # Corrected Write-Debug piping
                $setVersionOutput = wsl --set-default-version 2 2>&1
                if ($setVersionOutput) {
                    $setVersionOutput | ForEach-Object { Write-Debug $_ }
                }
                Write-Verbose "WSL default version set to 2."
            }
            catch {
                Write-Error "Failed to set WSL default version to 2. Error: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Verbose "WSL default version is already 2."
    }

    # Section 3: Install Linux Distribution if Missing
    Write-Verbose "Checking if distribution '${DistroName}' is installed..."
    $installedDistros = wsl.exe -l --quiet
    if (-not ($installedDistros -contains $DistroName)) {
        Write-Host "Distribution '${DistroName}' not found. Attempting to install..."
        if ($PSCmdlet.ShouldProcess($DistroName, "Install WSL distribution")) {
            try {
                $installOutput = wsl --install -d $DistroName 2>&1 # Capture output
                if ($installOutput) {
                    $installOutput | ForEach-Object { Write-Debug $_ }
                }
                Write-Host "Distribution '${DistroName}' installation initiated. This may take some time and might require user interaction for new user setup."
            }
            catch {
                Write-Error "Failed to install distribution '${DistroName}'. Error: $($_.Exception.Message). Please install it manually."
                exit 1 # Exit if distro install fails, as other steps depend on it.
            }
        }
    } else {
        Write-Verbose "Distribution '${DistroName}' is already installed."
    }

    # Section 4: Create Windows Port Proxy
    Write-Verbose "Checking for existing port proxy on Windows port ${Port}..."
    $existingProxyRule = netsh interface portproxy show v4tov4 | Select-String -Pattern "Listen Port:\s+${Port}\s*$" -CaseSensitive
    
    if (-not $existingProxyRule) {
        Write-Host "No existing port proxy found for Windows listen port ${Port}. Adding new proxy."
        if ($PSCmdlet.ShouldProcess("Windows Network Configuration", "Add port proxy: Windows Port ${Port} -> WSL Distro '${DistroName}' Port ${WslSshPort}")) {
            try {
                Write-Debug "Attempting to retrieve IP for '${DistroName}'. Ensure it has been run at least once."
                $wslIp = (wsl -d $DistroName -- hostname -I).Trim() 
                if (-not $wslIp) {
                    Write-Error "Could not retrieve WSL IP address for '${DistroName}'. Ensure the distribution is running, has networking, and has been initialized (run at least once)."
                } elseif ($wslIp -notmatch '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b') {
                    Write-Error "Retrieved WSL IP address '${wslIp}' for '${DistroName}' does not appear valid."
                } else {
                    Write-Verbose "WSL IP for '${DistroName}': ${wslIp}"
                    Write-Debug "Adding port proxy: Windows listenaddress=0.0.0.0 listenport=${Port} -> WSL connectaddress=${wslIp} connectport=${WslSshPort}"
                    # Corrected Write-Debug piping
                    $proxyAddOutput = netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=${Port} connectaddress=${wslIp} connectport=${WslSshPort} 2>&1
                    if ($proxyAddOutput) {
                        $proxyAddOutput | ForEach-Object { Write-Debug $_ }
                    }
                    Write-Verbose "Port proxy added."
                }
            }
            catch {
                Write-Error "Failed to add port proxy. Error: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Verbose "A port proxy rule for Windows listen port ${Port} seems to exist. Skipping creation."
        Write-Debug "Existing proxy details for Listen Port ${Port}:"
        $existingProxyRule | ForEach-Object { Write-Debug $_.Line }
        Write-Warning "If the existing proxy for port ${Port} does not target WSL distro '${DistroName}' on its port ${WslSshPort} at the correct WSL IP, you may need to manually delete the old proxy ('netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=${Port}') and re-run this script."
    }

    # Section 5: Create Firewall Rule
    $firewallRuleName = "WSL2 SSH Forward (${DistroName} Port ${Port})" 
    Write-Verbose "Checking firewall rule '${firewallRuleName}'..."
    $rule = Get-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue

    if (-not $rule) {
        Write-Host "Firewall rule '${firewallRuleName}' not found. Creating..."
        if ($PSCmdlet.ShouldProcess("Windows Firewall", "Create rule '${firewallRuleName}' for inbound TCP port ${Port}")) {
            try {
                New-NetFirewallRule -DisplayName $firewallRuleName `
                    -Direction Inbound `
                    -LocalPort $Port `
                    -Protocol TCP `
                    -Action Allow | Out-Null
                Write-Verbose "Firewall rule '${firewallRuleName}' created."
            }
            catch {
                Write-Error "Failed to create firewall rule '${firewallRuleName}'. Error: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Verbose "Firewall rule '${firewallRuleName}' already exists."
        Write-Debug "Existing rule details: Name: $($rule.DisplayName), Port: $($rule.LocalPort), Protocol: $($rule.Protocol), Action: $($rule.Action), Enabled: $($rule.Enabled)"
    }

    Write-Host "`nWindows-side prerequisite setup evaluation complete."
    if ($PSCmdlet.WhatIfPreference) {
        Write-Host "THIS WAS A DRY RUN (-WhatIf). No actual changes were made to the system."
    } else {
        Write-Host "Windows-side prerequisite setup process attempted."
    }
    Write-Host "`nNext Steps (inside WSL distribution '${DistroName}'):"
    Write-Host "1. Install an SSH server (e.g., 'sudo apt update && sudo apt install openssh-server')."
    Write-Host "2. Configure the SSH server. Ensure it's set to listen on port ${WslSshPort} (usually in /etc/ssh/sshd_config, e.g., 'Port ${WslSshPort}')."
    Write-Host "3. Enable and start the SSH service (e.g., 'sudo systemctl enable ssh', 'sudo systemctl start ssh', or 'sudo service ssh start')."
    Write-Host "4. Set up your WSL user for SSH access (e.g., password authentication or public key authentication in ~/.ssh/authorized_keys)."
    Write-Host "5. If you intend to use systemd features (like 'systemctl enable ssh'), ensure systemd is enabled in /etc/wsl.conf (e.g., by adding '[boot]\nsystemd=true' and restarting WSL via 'wsl --shutdown')."
    Write-Host "`nOnce WSL is configured, connect using: ssh -p ${Port} <your-wsl-user>@<your-windows-ip-or-hostname>"

} else {
    Write-Host "Windows-side WSL2 SSH Prerequisite Setup cancelled by user (due to -WhatIf or declining a ShouldProcess prompt)."
}


