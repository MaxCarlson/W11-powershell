# Run-Program-Version-X

This folder contains scripts for running the latest version of programs whose file paths change due to version numbers being hard-coded into the file paths.

## Scripts

### runLatestVersion.ps1

This PowerShell script is designed to locate and run the latest version of a specified program based on the directory structure.

#### Overview

- **Script Name:** `runLatestVersion.ps1`
- **Description:** Finds and runs the latest version of a program by searching for the most recent version directory.
- **Parameters:**
  - `ProgramBase` (Alias: `b`): The base directory where the program versions are stored.
  - `ExecutableName` (Alias: `e`): The name of the executable to run.

#### Usage

To run the script, use the following command in PowerShell:
```powershell
.\runLatestVersion.ps1 -ProgramBase "C:\Path\To\ProgramBase" -ExecutableName "program.exe"
```

#### Functions

- **Get-LatestVersionPath:** Finds the latest version directory within the `ProgramBase`.
- **Run-Program:** Runs the executable from the latest version directory.

#### Example
```powershell
.\runLatestVersion.ps1 -ProgramBase "C:\Users\mcarls\AppData\Local\Microsoft\WinGet\Packages\Syncthing.Syncthing_Microsoft.Winget.Source_8wekyb3d8bbwe" -ExecutableName "syncthing.exe"
```

### run-syncthing2.cmd

This batch script interfaces with `runLatestVersion.ps1` to run programs whose file paths change due to version numbers in the directory structure.

#### Overview

- **Script Name:** `run-syncthing2.cmd`
- **Description:** Calls `runLatestVersion.ps1` with specific parameters to run the latest version of Syncthing.

#### Usage

To run the script, simply execute the batch file:
```cmd
run-syncthing2.cmd
```

#### Example
This example uses the hard-coded path for Syncthing and runs the executable:
```cmd
@echo off
setlocal

REM Define the path to the PowerShell script
set SCRIPT_PATH=%~dp0runLatestVersion.ps1

REM Define the program name and executable
set PROGRAM_NAME="C:\Users\mcarls\AppData\Local\Microsoft\WinGet\Packages\Syncthing.Syncthing_Microsoft.Winget.Source_8wekyb3d8bbwe"
set EXECUTABLE_NAME=syncthing.exe

REM Run the PowerShell script with the required parameters
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -ProgramBase "%PROGRAM_NAME%" -ExecutableName "%EXECUTABLE_NAME%"

endlocal
```

## Contributing

Contributions are welcome! Please fork this repository and submit pull requests. Ensure your code adheres to the existing style and includes relevant comments.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For any questions or issues, please contact me at carlsonamax@gmail.com.

This README now includes a detailed yet concise description of the scripts, their usage, and example commands. Let me know if you need further customization or additional details.