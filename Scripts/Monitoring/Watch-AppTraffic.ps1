param(
    [Parameter(Mandatory = $true)]
    [string]$ProcessName
)

# Search for matching processes
Write-Host "Searching for processes matching: $ProcessName" -ForegroundColor Cyan
$matchingProcesses = Get-Process | Where-Object { $_.Name -like "*$ProcessName*" }

if (-not $matchingProcesses) {
    Write-Host "No processes found matching: $ProcessName" -ForegroundColor Red
    exit
}

Write-Host "Found the following matching processes:" -ForegroundColor Green
$matchingProcesses | Select-Object Id, Name | Format-Table -AutoSize

# Get all PIDs
$ProcessIDs = $matchingProcesses.Id

# Start monitoring loop
while ($true) {
    Clear-Host  # Clear the screen for better readability
    foreach ($ProcessID in $ProcessIDs) {
        Write-Host "Monitoring Process PID: $ProcessID ($ProcessName)" -ForegroundColor Yellow

        # Step 1: Active Network Connections
        $connections = Get-NetTCPConnection | Where-Object { $_.OwningProcess -eq $ProcessID }

        if ($connections) {
            Write-Host "Active Network Connections:" -ForegroundColor Cyan
            $connections | Select-Object State, LocalAddress, LocalPort, RemoteAddress, RemotePort | Format-Table -AutoSize
        } else {
            Write-Host "No active network connections." -ForegroundColor Red
        }

        # Step 2: Bandwidth Usage
        $bandwidthData = Get-Counter '\Process(*)\IO Data Bytes/sec'
        $bandwidth = $bandwidthData.CounterSamples | Where-Object { $_.InstanceName -match "$ProcessName" }

        if ($bandwidth) {
            Write-Host "Bandwidth Usage:" -ForegroundColor Cyan
            foreach ($sample in $bandwidth) {
                $rateInBytes = $sample.CookedValue
                $rateInBits = $rateInBytes * 8  # Convert to bits/sec

                if ($rateInBits -ge 1000000) {
                    $rate = [math]::Round($rateInBits / 1000000, 2)
                    Write-Host "$($sample.InstanceName): $rate Mb/s" -ForegroundColor Green
                } else {
                    $rate = [math]::Round($rateInBits / 1000, 2)
                    Write-Host "$($sample.InstanceName): $rate Kb/s" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "No bandwidth data available." -ForegroundColor Red
        }

        Write-Host ""  # Blank line for separation
    }

    # Sleep for 5 seconds before refreshing
    Start-Sleep -Seconds 5
}
