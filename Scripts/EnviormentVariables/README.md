# AddToPath

## Overview

`addtopath.ps1` is a PowerShell script designed to manage the PATH environment variable on Windows. It allows you to add new paths, check for overlapping executables, log changes, and rollback modifications to the PATH variable. This script supports both user and system PATH updates.

## Features

- Add directories or executables to the PATH environment variable.
- Automatically check for overlapping executables in the PATH.
- Log changes to the PATH environment variable for easy rollback.
- Rollback the last PATH modification.
- Supports both user and system PATH updates.
- Option to force the operation without user confirmation.
- Easy-to-use flags for common operations.

## Prerequisites

- Windows PowerShell 5.1 or later.
- Administrative privileges (required for modifying the system PATH).

## Installation

1. Clone the repository or download the script files.
2. Ensure the script and its dependencies are in the correct directory structure:

    ```
    EnviromentVariables/
    ├── lib/
    │   └── functions.ps1
    └── addtopath.ps1
    ```

3. (Optional) Add the `EnviromentVariables` directory to the PATH environment variable for easy execution from any location.

## Usage

### Add a Path to the PATH Variable

To add a path to the PATH environment variable, run the script with the `-e` or `--path` parameter:

```powershell
.\addtopath.ps1 -e "C:\path\to\your\executable"
```

### Add a Path to the User PATH Variable

To add a path to the user PATH environment variable, use the `-u` switch:

```powershell
.\addtopath.ps1 -e "C:\path\to\your\executable" -u
```

### Rollback the Last PATH Modification

To rollback the last PATH modification, use the `-r` switch:

```powershell
.\addtopath.ps1 -r
```

### Force the Operation without User Confirmation

To force the operation without user confirmation, use the `-f` switch:

```powershell
.\addtopath.ps1 -e "C:\path\to\your\executable" -f
```

### Display Help

To display the help message, use the `-h` or `--help` switch:

```powershell
.\addtopath.ps1 -h
```

## Example

Add `C:\tools` to the system PATH variable:

```powershell
.\addtopath.ps1 -e "C:\tools"
```

Add `C:\tools` to the user PATH variable:

```powershell
.\addtopath.ps1 -e "C:\tools" -u
```

Rollback the last PATH modification for the user:

```powershell
.\addtopath.ps1 -r -u
```

Force add `C:\tools` to the system PATH variable without user confirmation:

```powershell
.\addtopath.ps1 -e "C:\tools" -f
```

## Error Handling

The script includes basic error handling to ensure robustness. If an error occurs, appropriate messages will be displayed, and the script will terminate gracefully.

## Contributing

Contributions are welcome! If you have suggestions or improvements, please submit a pull request or open an issue on the repository.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Contact

For any questions or issues, please contact me at carlsonamax@gmail.com.

Feel free to customize the contact section and any other parts to better fit your specific project details and preferences.
