$BackupPath = "$HOME\Desktop\IntelWifiBackup"
mkdir $BackupPath -Force
Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.InfName -like "netwtw*" } | ForEach-Object {
    Copy-Item -Path $_.DriverProviderName -Destination $BackupPath -ErrorAction SilentlyContinue
}

