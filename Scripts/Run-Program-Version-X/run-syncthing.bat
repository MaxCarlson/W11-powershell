@echo off
setlocal
set "SyncthingBase=C:\Users\mcarls\AppData\Local\Microsoft\WinGet\Packages\Syncthing.Syncthing_Microsoft.Winget.Source_8wekyb3d8bbwe"
for /D %%d in ("%SyncthingBase%\syncthing-windows-amd64-v*") do (
    set "LatestVersion=%%d"
)
start "" "%LatestVersion%\syncthing.exe"
endlocal
