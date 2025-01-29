# 🚀 Windows 11 SSH Setup Script
# Place this inside W11-powershell/Setup and run it as Administrator.

Write-Output "🔹 Starting SSH setup on Windows 11..."

# Ensure OpenSSH is installed
if (!(Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*')) {
    Write-Output "⚠️ OpenSSH is not installed. Installing now..."
    Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'
    Add-WindowsCapability -Online -Name 'OpenSSH.Client~~~~0.0.1.0'
}

# Start and enable OpenSSH Server & SSH Agent
Write-Output "🔹 Enabling OpenSSH Server and SSH Agent..."
Set-Service sshd -StartupType Automatic
Set-Service ssh-agent -StartupType Automatic
Start-Service sshd
Start-Service ssh-agent

# Confirm services are running
Write-Output "🔹 Verifying SSH services..."
Get-Service sshd, ssh-agent

# Ensure firewall allows SSH
Write-Output "🔹 Configuring Windows Firewall for SSH..."
New-NetFirewallRule -Name "SSH" -DisplayName "Allow SSH" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -ErrorAction SilentlyContinue

# Configure SSHD for PowerShell & WSL
$sshdConfigPath = "C:\ProgramData\ssh\sshd_config"

Write-Output "🔹 Configuring SSHD settings..."
$sshdConfig = @"
# SSH Server Configuration (Customized for PowerShell & WSL)
Subsystem sftp sftp-server.exe
Subsystem powershell `"C:\Program Files\PowerShell\7\pwsh.exe`" -sshs
ForceCommand `"C:\Program Files\PowerShell\7\pwsh.exe`" -sshs
Match User wsluser
    ForceCommand C:\Windows\System32\wsl.exe
"@

Set-Content -Path $sshdConfigPath -Value $sshdConfig -Force

# Restart SSH service to apply changes
Write-Output "🔹 Restarting SSH service..."
Restart-Service sshd

# Auto-load SSH keys on login
$sshAgentStartupScript = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\ssh-agent.ps1"
Write-Output "🔹 Ensuring SSH keys are loaded at login..."
$sshAgentScriptContent = @"
Start-Service ssh-agent
ssh-add "$env:USERPROFILE\.ssh\id_ed25519" 2>`$null
"@
Set-Content -Path $sshAgentStartupScript -Value $sshAgentScriptContent -Force

# Set execution policy for scripts
Write-Output "🔹 Setting PowerShell execution policy..."
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Verify SSHD is listening
Write-Output "🔹 Checking if SSHD is listening on port 22..."
netstat -an | Select-String ":22"

Write-Output "✅ SSH setup complete! Restart your computer for full effect."

