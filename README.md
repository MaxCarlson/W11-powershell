# W11-powershell

This repository contains PowerShell scripts for managing and customizing a Windows 11 environment. It is designed to help streamline tasks and improve efficiency on your main machine.

## Table of Contents
- [Introduction](#introduction)
- [Scripts](#scripts)
  - [AddToPath](#addtopath)
  - [EnviormentVariables](#enviormentvariables)
  - [MoveFiles](#movefiles)
  - [Run-Program-Version-X](#run-program-version-x)
  - [WSL2IPUpdater](#wsl2ipupdater)
- [KDEScripts](#kdescripts)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Introduction
This repository holds various PowerShell scripts aimed at enhancing and automating different tasks within a Windows 11 setup.

## Scripts
Each subfolder under Scripts/ holds it's own windows CMD or PowerShell scripts.

### AddToPath
This folder contains scripts related to modifying the system PATH variable.

### EnviormentVariables
**Location:** [EnviormentVariables](https://github.com/MaxCarlson/W11-powershell/tree/master/Scripts/EnviormentVariables)

This folder contains scripts for managing environment variables.

- **Overview:** Scripts here manage the PATH environment variable on Windows, allowing addition, removal, logging changes, and rolling back modifications. They support both user and system PATH updates.
- **Key Scripts:**
  - `addtopath.ps1`: Adds directories or executables to the PATH, checks for overlaps, logs changes, and supports rollbacks.

### MoveFiles
**Location:** [MoveFiles](https://github.com/MaxCarlson/W11-powershell/tree/master/Scripts/MoveFiles)

This project includes scripts for organizing files by moving them based on their age.

**Key Scripts:**
- **MoveOneDayOldRecursivelyFinal.ps1**: Moves files older than one day from the source to the destination directory.
- **SetupSchedule.ps1**: Sets up a scheduled task to run the file move script at regular intervals.

These scripts automate the management of file movement to keep data organized and ensure old files are relocated appropriately.

### Run-Program-Version-X
**Location:** [Run-Program-Version-X](https://github.com/MaxCarlson/W11-powershell/tree/master/Scripts/Run-Program-Version-X)
  
This folder contains scripts to run the latest version of programs whose file paths change on updates due to version numbers being hard-coded into the path

**Key Scripts:**
- **runLatestVersion.ps1**: Locates and runs the latest version of a specified program based on the directory structure. 
  - **Usage**: `.\runLatestVersion.ps1 -ProgramBase "C:\Path\To\ProgramBase" -ExecutableName "program.exe"`

- **run-syncthing2.cmd**: Batch script that calls `runLatestVersion.ps1` with parameters to run the latest version of Syncthing.
  - **Usage**: Run the batch file directly to execute the latest Syncthing version.

### WSL2IPUpdater
**Location:** [WSL2IPUpdater](https://github.com/MaxCarlson/W11-powershell/tree/master/Scripts/WSL2IPUpdater)

This project includes scripts to manage and log the WSL2 IP address, ensuring the IP remains current for services that rely on it. 

**Key Scripts:**
- **SetupSchedule.ps1**: Sets up a scheduled task to run the IP update script daily.
- **UpdateWSL2SSHServerIP.ps1**: Updates the WSL2 IP address and logs changes if the IP has changed.

**Log Files:**
- **iplog.log**: Records the history of WSL2 IP addresses.
- **WSL2-Last-IP.txt**: Stores the last known WSL2 IP address for comparison.

## KDEScripts
Not documented

## Getting Started
To get started with the scripts in this repository, clone the repository to your local machine using:
```bash
git clone https://github.com/MaxCarlson/W11-powershell.git
```

## Usage
To use any script, navigate to its directory and run it using PowerShell with appropriate parameters as demonstrated in the examples above.

## Contributing
Contributions are welcome! Please fork this repository and submit pull requests. Ensure your code adheres to the existing style and includes relevant comments.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact
For any questions or issues, please contact me at carlsonamax@gmail.com.

This README now includes a summarized section for `EnviormentVariables` and outlines each subfolder within `Scripts`. Let me know if you need further customization or additional details for the other folders.
