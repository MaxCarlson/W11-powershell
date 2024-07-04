Here is the updated README with a summarized section for `EnviormentVariables`:

```markdown
# W11-powershell

This repository contains PowerShell scripts for managing and customizing a Windows 11 environment. It is designed to help streamline tasks and improve efficiency on your main machine.

## Table of Contents
- [Introduction](#introduction)
- [Folder Structure](#folder-structure)
  - [AddToPath](#addtopath)
  - [EnviormentVariables](#enviormentvariables)
  - [MoveFiles](#movefiles)
  - [Run-Program-Version-X](#run-program-version-x)
  - [WSL2IPUpdater](#wsl2ipupdater)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Introduction
This repository holds various PowerShell scripts aimed at enhancing and automating different tasks within a Windows 11 setup.

## Folder Structure
The repository is organized into the following main folders:

### AddToPath
This folder contains scripts related to modifying the system PATH variable.

### EnviormentVariables
This folder contains scripts for managing environment variables.

- **Location:** [EnviormentVariables](https://github.com/MaxCarlson/W11-powershell/tree/master/Scripts/EnviormentVariables)
- **Overview:** Scripts here manage the PATH environment variable on Windows, allowing addition, removal, logging changes, and rolling back modifications. They support both user and system PATH updates.
- **Key Scripts:**
  - `addtopath.ps1`: Adds directories or executables to the PATH, checks for overlaps, logs changes, and supports rollbacks.

### MoveFiles
This folder contains scripts for automating file movement tasks.

### Run-Program-Version-X
This folder contains scripts and bat files for running specific program versions.

### WSL2IPUpdater
This folder contains scripts for updating and managing WSL2 IP configurations.

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
```

This README now includes a summarized section for `EnviormentVariables` and outlines each subfolder within `Scripts`. Let me know if you need further customization or additional details for the other folders.
