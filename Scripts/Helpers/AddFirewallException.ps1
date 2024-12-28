param (
    [Parameter(Mandatory = $true, HelpMessage = "Specify a unique name for the firewall rule.")]
    [string]$RuleName,

    [Parameter(Mandatory = $true, HelpMessage = "Specify the action (Allow or Block).")]
    [ValidateSet("Allow", "Block")]
    [string]$Action,

    [Parameter(Mandatory = $false, HelpMessage = "Specify the direction (Inbound or Outbound). Default is Inbound.")]
    [ValidateSet("Inbound", "Outbound")]
    [string]$Direction = "Inbound",

    [Parameter(Mandatory = $false, HelpMessage = "Specify the protocol (TCP, UDP, or Any). Default is Any.")]
    [ValidateSet("TCP", "UDP", "Any")]
    [string]$Protocol = "Any",

    [Parameter(Mandatory = $false, HelpMessage = "Specify the port number. Leave empty if no port is needed.")]
    [int]$Port,

    [Parameter(Mandatory = $false, HelpMessage = "Specify the full path to the program. Leave empty if not needed.")]
    [string]$ProgramPath,

    [Parameter(Mandatory = $false, HelpMessage = "Specify the network profile (Domain, Private, Public, or Any). Default is Any.")]
    [ValidateSet("Domain", "Private", "Public", "Any")]
    [string]$Profile = "Any"
)

# Validate inputs
if (-not $Port -and -not $ProgramPath) {
    Write-Color -Message "Error: You must specify either a port or a program path." -Type "Error"
    return
}

# Build the New-NetFirewallRule command
try {
    $firewallParams = @{
        DisplayName = $RuleName
        Direction   = $Direction
        Action      = $Action
        Profile     = $Profile
    }

    if ($Protocol -ne "Any") { $firewallParams.Protocol = $Protocol }
    if ($Port) { $firewallParams.LocalPort = $Port }
    if ($ProgramPath) { $firewallParams.Program = $ProgramPath }

    # Add the firewall rule
    New-NetFirewallRule @firewallParams

    # Success message
    Write-Color -Message "Firewall rule '$RuleName' created successfully!" -Type "Success"
} catch {
    # Error message
    Write-Color -Message "Error creating firewall rule: $_" -Type "Error"
}
