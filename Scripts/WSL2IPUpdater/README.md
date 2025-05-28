# WSL2 IP Updater & SSH Forwarding Manager

This subfolder contains scripts to dynamically manage port forwarding from the Windows host to a WSL2 instance for SSH access. It ensures the forwarding rule uses the current WSL2 IP address and that a corresponding Windows Firewall rule allows incoming traffic.

## Contents

-   **`UpdateWSL2SSHServerIP.ps1`**: The core script that performs the IP detection, port proxy update, and firewall rule management.
-   **`SetupSchedule.ps1`**: A utility script to create/update a Windows Scheduled Task that runs `UpdateWSL2SSHServerIP.ps1` periodically with necessary privileges.
-   **`WSL2-Last-IP.txt`**: Stores the last known IP address of the WSL2 instance to detect changes. Created and managed by `UpdateWSL2SSHServerIP.ps1`.
-   **`iplog.log`** (or `WSL2-IPChange.log` if you adopted the new script's logging): Logs actions, IP changes, and any errors encountered by `UpdateWSL2SSHServerIP.ps1`.

## `UpdateWSL2SSHServerIP.ps1`

This is the main script responsible for:

1.  **Detecting WSL2 IP**: Dynamically retrieves the current IP address of the default WSL2 instance.
2.  **Managing Port Proxy Rule**:
    * If the WSL2 IP has changed (or if it's the first run), it removes any existing `netsh interface portproxy` rule for the configured listening port.
    * It then adds a new port proxy rule to forward traffic from a specified port on the Windows host (e.g., `2222`) to port `22` on the WSL2 instance using its current IP.
3.  **Managing Firewall Rule** (assuming you've integrated the logic from my previous suggestion into your `UpdateWSL2SSHServerIP.ps1`):
    * Ensures a Windows Firewall rule exists to allow inbound TCP traffic on the specified listening port (e.g., `2222`).
    * The firewall rule creation is idempotent (it won't create duplicates).
4.  **Logging**: Records IP changes, actions taken, and any errors. The original script logged to `iplog.log`. If you updated it based on my version, it would be `WSL2-IPChange.log`.
5.  **State Tracking**: Stores the last successfully used WSL2 IP in `WSL2-Last-IP.txt`.

This script is designed to be idempotent and can be run multiple times.

### Configuration within `UpdateWSL2SSHServerIP.ps1`

(Assuming you've updated your `UpdateWSL2SSHServerIP.ps1` with the variables and logic from the `UpdateAndManageWSL2SSHForwarding.ps1` version I provided earlier).
You can modify the following variables at the top of `UpdateWSL2SSHServerIP.ps1`:
* `$listeningPort`: The port Windows will listen on (default: "2222").
* `$destinationPort`: The SSH port on the WSL2 instance (default: "22").
* `$firewallRuleName`: The display name for the Windows Firewall rule.

### Manual Usage

To run the script manually (requires Administrator privileges):
```powershell
.\UpdateWSL2SSHServerIP.ps1
