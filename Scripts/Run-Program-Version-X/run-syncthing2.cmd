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
