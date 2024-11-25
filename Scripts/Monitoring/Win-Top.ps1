# Top.ps1 - A script to emulate `top` functionality in PowerShell
param(
    [int]$Interval = 2, # Refresh interval in seconds
    [int]$MaxProcesses = 10 # Number of processes to display
)

# Function to format memory size
function Format-Memory {
    param([long]$Bytes)
    switch ($Bytes) {
        {$_ -ge 1TB} { return "{0:N2} TB" -f ($Bytes / 1TB) }
        {$_ -ge 1GB} { return "{0:N2} GB" -f ($Bytes / 1GB) }
        {$_ -ge 1MB} { return "{0:N2} MB" -f ($Bytes / 1MB) }
        {$_ -ge 1KB} { return "{0:N2} KB" -f ($Bytes / 1KB) }
        default { return "{0} B" -f $Bytes }
    }
}

# Main loop
while ($true) {
    Clear-Host

    # Fetch process details
    $processes = Get-Process | ForEach-Object {
        [PSCustomObject]@{
            Name       = $_.Name
            ID         = $_.Id
            CPU        = $_.CPU
            Memory     = Format-Memory -Bytes $_.WorkingSet64
            Handles    = $_.Handles
            Threads    = $_.Threads.Count
            StartTime  = if ($_.StartTime) { $_.StartTime.ToString("yyyy-MM-dd HH:mm:ss") } else { "N/A" }
        }
    } | Sort-Object CPU -Descending | Select-Object -First $MaxProcesses

    # Display the output
    Write-Host "Process Monitor (`top`-like) - Refresh Interval: $Interval seconds" -ForegroundColor Green
    Write-Host "==========================================================="
    Write-Host "Name             ID    CPU   Memory     Handles Threads StartTime"
    Write-Host "-----------------------------------------------------------"

    foreach ($proc in $processes) {
        "{0,-15} {1,5} {2,6:N2} {3,-10} {4,7} {5,8} {6}" -f `
            $proc.Name, $proc.ID, $proc.CPU, $proc.Memory, $proc.Handles, $proc.Threads, $proc.StartTime
    }

    # Pause for the interval
    Start-Sleep -Seconds $Interval
}
