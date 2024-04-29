# Function to get the WSL2 IP Address
Function Get-WSL2-IP {
    $wsl2IP = wsl ip addr show eth0 | Select-String -Pattern 'inet ' | % { $_.ToString().Split(' ')[5] -replace '/.*$', '' }
    return $wsl2IP
}

Function Add-To-File {
    param (
        [string]$newIP,
        [string]$filePath,
        [bool]$multiLine
    )
    if (Test-Path -Path $filePath) {
        if ($multiLine) {
            # The file exists, add a new line
            Add-Content -Path $filePath -Value $newIP
        }
        else {
            # Overwrite the file with the new IP
            $newIP | Out-File -FilePath $filePath
        }
    }
    else {
        # The file does not exist, create the file and add the first line
        $newIP | Out-File -FilePath $filePath
    }
}


# Define the file path
$filePath = (Get-Location).Path + "\WSL2-Last-IP.txt"
$logPath = (Get-Location).Path + "\iplog.log"

# Read the old WSL2 IP from a text file
$oldIP = Get-Content -Path $filePath -ErrorAction SilentlyContinue

# Get the new WSL2 IP Address
$newIP = Get-WSL2-IP

# Check if the IP has changed
if ($oldIP -ne $newIP) {
    # Remove the old rule
    netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=0.0.0.0

    # Add the new rule
    netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=22 connectaddress=$newIP

    # Update the text file with the new IP
    $newIP | Out-File $filePath

    #Add-To-File $newIP $filePath $false
    #Add-IP-File $newIP $logpath $true
    Add-To-File -newIP $newIP -filePath $filePath -multiLine $false
    Add-To-File -newIP $newIP -filePath $logPath -multiLine $true



    # Optional: Print the new IP to verify
    Write-Host "WSL2 IP has changed. New IP is $newIP"
}
