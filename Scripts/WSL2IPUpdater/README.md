# WSL2IPUpdater

This subfolder contains scripts to update and log the WSL2 (Windows Subsystem for Linux 2) IP address, ensuring that services relying on the WSL2 IP address remain functional.

## Contents
- [iplog.log](#iploglog)
- [SetupSchedule.ps1](#setupscheduleps1)
- [UpdateWSL2SSHServerIP.ps1](#updatewsl2sshserveripps1)
- [WSL2-Last-IP.txt](#wsl2-last-iptxt)

## iplog.log
A log file that records the history of IP addresses assigned to the WSL2 instance.

## SetupSchedule.ps1
This script sets up a scheduled task to periodically run the `UpdateWSL2SSHServerIP.ps1` script, ensuring the WSL2 IP address is updated and logged regularly.

### Parameters
- `verbose` (optional): Enables verbose output.
- `taskName` (optional): Name of the scheduled task.
- `description` (optional): Description of the scheduled task.

### Usage
To schedule the update script to run daily at 7am:
```powershell
.\SetupSchedule.ps1 -verbose $true
```

## UpdateWSL2SSHServerIP.ps1
This script updates the WSL2 IP address for the SSH server and logs the changes.

### Functions
- `Get-WSL2-IP`: Retrieves the current WSL2 IP address.
- `Add-To-File`: Adds or updates the IP address in a specified file.

### Process
1. Retrieves the current WSL2 IP address.
2. Compares it with the last recorded IP address.
3. Updates the port proxy rule if the IP address has changed.
4. Logs the new IP address.

### Usage
To manually update the WSL2 IP address:
```powershell
.\UpdateWSL2SSHServerIP.ps1
```

## WSL2-Last-IP.txt
Stores the last known IP address of the WSL2 instance to detect changes.

## Contributing
Contributions are welcome! Please fork this repository and submit pull requests. Ensure your code adheres to the existing style and includes relevant comments.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact
For any questions or issues, please contact me at carlsonamax@gmail.com.


This README provides an overview and usage instructions for each file in the `WSL2IPUpdater` subfolder, making it easier for users to understand and utilize the scripts.