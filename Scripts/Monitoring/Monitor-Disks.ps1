param(
    [string]$Drive = "ALL"
)

# Helper function to format byte rates.
function Format-Speed($bytesPerSec) {
    if ($bytesPerSec -ge 1GB) {
        return "{0:N2} GB/s" -f ($bytesPerSec / 1GB)
    } elseif ($bytesPerSec -ge 1MB) {
        return "{0:N2} MB/s" -f ($bytesPerSec / 1MB)
    } else {
        return "{0:N2} KB/s" -f ($bytesPerSec / 1KB)
    }
}

function Get-DiskProcesses {
    param([string]$diskLetter)
    # Use ${diskLetter} to safely interpolate the variable followed by a colon.
    Get-CimInstance Win32_Process | Where-Object {
        $_.CommandLine -and $_.CommandLine -match [regex]::Escape("${diskLetter}:")
    } | Select-Object ProcessId, Name, CommandLine
}

function Get-DiskStats {
    param([string]$diskLetter)

    $stats = @{}
    # Get fresh samples with a 1-second interval.
    $counters = Get-Counter -Counter "\PhysicalDisk(*)\Disk Read Bytes/sec", `
                                "\PhysicalDisk(*)\Disk Write Bytes/sec", `
                                "\PhysicalDisk(*)\% Disk Time" `
                                -SampleInterval 1 -MaxSamples 1
    foreach ($sample in $counters.CounterSamples) {
        $instance = $sample.InstanceName.Trim()
        # Skip the _Total instance.
        if ($instance -eq "_Total") { continue }
        # If a specific drive is specified, require the instance name to include that drive letter (e.g. "D:"), case-insensitive.
        if ($diskLetter -ne "ALL" -and ($instance -notmatch "(?i)${diskLetter}:")) { continue }

        if (-not $stats.ContainsKey($instance)) {
            $stats[$instance] = [ordered]@{
                "Read"        = 0
                "Write"       = 0
                "% Disk Time" = 0
            }
        }
        if ($sample.Path -match "Disk Read Bytes/sec") {
            $stats[$instance]["Read"] = Format-Speed($sample.CookedValue)
        } elseif ($sample.Path -match "Disk Write Bytes/sec") {
            $stats[$instance]["Write"] = Format-Speed($sample.CookedValue)
        } elseif ($sample.Path -match "% Disk Time") {
            $stats[$instance]["% Disk Time"] = [math]::Round($sample.CookedValue, 2)
        }
    }
    return $stats
}

function Get-DiskUsage {
    # Convert sizes to GB.
    Get-Volume | Select-Object `
        DriveLetter, FileSystem, `
        @{Name="Size(GB)"; Expression={[math]::Round($_.Size / 1GB,2)}}, `
        @{Name="Free(GB)"; Expression={[math]::Round($_.SizeRemaining / 1GB,2)}}, `
        @{Name="Used(%)"; Expression={[math]::Round((($_.Size - $_.SizeRemaining) / $_.Size) * 100, 2)}}
}

function Monitor-Disks {
    while ($true) {
        Clear-Host
        Write-Host "Real-Time Disk Performance Monitoring" -ForegroundColor Cyan
        Write-Host "------------------------------------------------------------"

        # Display disk capacity and usage at the top.
        $diskUsage = Get-DiskUsage
        $diskUsage | Format-Table -AutoSize

        Write-Host "`n⏳ Live Disk Performance:" -ForegroundColor Yellow
        $diskStats = Get-DiskStats -diskLetter $Drive
        if ($diskStats.Keys.Count -gt 0) {
            $diskStats.GetEnumerator() | Sort-Object Name | Format-Table -Property Name, `
                @{Label="Read"; Expression={$_.Value["Read"]}}, `
                @{Label="Write"; Expression={$_.Value["Write"]}}, `
                "% Disk Time" -AutoSize
        }
        else {
            Write-Host "No counter data available for drive ${Drive}."
        }

        # If monitoring a specific drive, display the processes that have that drive letter in their command line.
        if ($Drive -ne "ALL") {
            Write-Host "`n🔍 Processes Accessing Drive ${Drive}:" -ForegroundColor Magenta
            $diskProcesses = Get-DiskProcesses -diskLetter $Drive
            if ($diskProcesses) {
                $diskProcesses | Format-Table -AutoSize
            } else {
                Write-Host "No active processes found for drive ${Drive}."
            }
        }
        Start-Sleep -Seconds 1
    }
}

Monitor-Disks
