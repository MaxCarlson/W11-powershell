# Script: UpdateAndManageWSL2SSHForwarding.ps1
# Purpose: Dynamically updates Windows port proxy and firewall rules
#          for forwarding a host port to WSL2's SSH server.

# --- Configuration ---
$listeningPort = "2222"
$destinationPort = "22" # WSL2 SSH port
$hostIpToListenOn = "0.0.0.0" # Listen on all Windows IP addresses
$firewallRuleName = "WSL2 SSH Forward (Port $listeningPort)"

# --- Paths (using $PSScriptRoot for robustness) ---
# $PSScriptRoot is the directory where the script itself is located.
$scriptDir = $PSScriptRoot
$lastIpFile = Join-Path -Path $scriptDir -ChildPath "WSL2-Last-IP.txt"
$logFile = Join-Path -Path $scriptDir -ChildPath "WSL2-IPChange.log"

# --- Helper Functions ---

Function Get-WSL2-IP {
    <#
    .SYNOPSIS
        Retrieves the primary IP address of the default WSL2 instance.
    #>
    # Using the hostname -I method as it's generally robust.
    # You can revert to your 'ip addr show eth0' method if preferred:
    # $wsl2IP = wsl ip addr show eth0 | Select-String -Pattern 'inet ' | ForEach-Object { $_.ToString().Split(' ')[5] -replace '/.*$', '' }
    $wslOutput = (wsl -e hostname -I 2>$null).Trim() # 2>$null suppresses stderr if WSL isn't ready
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($wslOutput)) {
        Write-Warning "Failed to execute 'wsl -e hostname -I' or got empty output."
        return $null
    }
    $wslIpArray = $wslOutput.Split(' ')
    return $wslIpArray[0] # Return the first IP address
}

Function Log-Message {
    param (
        [string]$Message,
        [string]$LogFilePath
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Add-Content -Path $LogFilePath -Value $logEntry
    Write-Host $logEntry
}

# --- Main Logic ---

# Step 1: Get the current WSL2 IP Address
$currentWslIp = Get-WSL2-IP
if (-not $currentWslIp) {
    Log-Message -Message "CRITICAL: Could not retrieve WSL2 IP address. Ensure WSL2 is running and accessible. Aborting script." -LogFilePath $logFile
    exit 1
}
Log-Message -Message "Current WSL2 IP Address: $currentWslIp" -LogFilePath $logFile

# Step 2: Ensure Firewall Rule Exists (Idempotent)
Write-Host "Checking/Ensuring firewall rule '$firewallRuleName' for port $listeningPort..."
$existingRule = Get-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue
if (-not $existingRule) {
    try {
        New-NetFirewallRule -DisplayName $firewallRuleName -Direction Inbound -LocalPort $listeningPort -Protocol TCP -Action Allow -ErrorAction Stop
        Log-Message -Message "Firewall rule '$firewallRuleName' created successfully." -LogFilePath $logFile
    } catch {
        Log-Message -Message "ERROR: Failed to create firewall rule '$firewallRuleName'. $_" -LogFilePath $logFile
        # Depending on severity, you might choose to exit here.
    }
} else {
    # Optional: You could verify properties of the existing rule if needed
    Write-Host "Firewall rule '$firewallRuleName' already exists."
}

# Step 3: Check if WSL2 IP has changed and update port proxy if necessary
$oldWslIp = Get-Content -Path $lastIpFile -ErrorAction SilentlyContinue

if ($oldWslIp -ne $currentWslIp -or -not $oldWslIp) { # Also update if old IP file doesn't exist
    Log-Message -Message "WSL2 IP change detected (or first run). Old IP: '$oldWslIp', New IP: '$currentWslIp'. Updating port proxy." -LogFilePath $logFile

    # Remove any old port proxy rule for this listening port (Idempotency for the port itself)
    # This is important if the connectaddress (WSL IP) changes.
    Write-Host "Attempting to remove any existing port proxy rule for $hostIpToListenOn`:$listeningPort..."
    netsh interface portproxy delete v4tov4 listenport=$listeningPort listenaddress=$hostIpToListenOn | Out-Null # Suppress output, including "not found" errors

    # Add the new port proxy rule
    Write-Host "Adding new port proxy rule: $hostIpToListenOn`:$listeningPort -> $currentWslIp`:$destinationPort"
    $proxyAddResult = netsh interface portproxy add v4tov4 listenport=$listeningPort listenaddress=$hostIpToListenOn connectport=$destinationPort connectaddress=$currentWslIp
    # Check netsh exit code (0 for success)
    if ($LASTEXITCODE -eq 0) {
        Log-Message -Message "Port proxy rule updated successfully to forward to $currentWslIp." -LogFilePath $logFile
        # Update the text file with the new IP
        try {
            $currentWslIp | Out-File -FilePath $lastIpFile -Encoding UTF8 -ErrorAction Stop
            Log-Message -Message "Updated '$lastIpFile' with new IP: $currentWslIp." -LogFilePath $logFile
        } catch {
            Log-Message -Message "ERROR: Failed to write new IP to '$lastIpFile'. $_" -LogFilePath $logFile
        }
    } else {
        Log-Message -Message "ERROR: 'netsh interface portproxy add' command failed. Output: $proxyAddResult" -LogFilePath $logFile
    }
} else {
    Log-Message -Message "WSL2 IP address ($currentWslIp) has not changed. No port proxy update needed." -LogFilePath $logFile
}

Write-Host "Script execution finished."
Write-Host "To connect: ssh your_wsl_username@your_windows_ip -p $listeningPort"
