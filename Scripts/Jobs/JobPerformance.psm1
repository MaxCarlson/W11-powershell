function Get-BackgroundJobPerformance {
    try {
        # Get all running jobs
        $jobs = Get-Job | Where-Object { $_.State -eq "Running" }
        if ($jobs.Count -eq 0) {
            Write-Color -Message "No active jobs to analyze." -Type "Info"
            return
        }

        # Collect performance data
        $jobProcesses = @()
        foreach ($job in $jobs) {
            $jobName = $job.Name
            $jobId = $job.Id
            $processName = "python"  # Adjust this for the process name you expect

            # Get all running processes by name
            $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue |
                         Where-Object { $_.StartTime -ge $job.PSBeginTime }

            if ($processes.Count -eq 0) {
                Write-Color -Message "No processes found for job '${jobName}' (Process name: ${processName})." -Type "Warning"
                continue
            }

            foreach ($proc in $processes) {
                # Attempt to find the performance counter instance for this process
                $instanceName = Get-Counter -ListSet 'Process' | ForEach-Object {
                    $_.CounterInstances
                } | Where-Object { $_ -match "^${processName}#?\d*$" } |
                ForEach-Object {
                    # Verify if this instance matches the process ID
                    $counterSample = Get-Counter "\Process($_)\ID Process" -ErrorAction SilentlyContinue
                    if ($counterSample.CounterSamples[0].CookedValue -eq $proc.Id) {
                        return $_
                    }
                }

                if ($null -ne $instanceName) {
                    # Get Disk I/O for the process
                    $diskUsageCounter = "\Process(${instanceName})\IO Data Bytes/sec"
                    $diskUsageSample = Get-Counter -Counter $diskUsageCounter -ErrorAction SilentlyContinue
                    if ($diskUsageSample.CounterSamples) {
                        $diskUsage = $diskUsageSample.CounterSamples[0].CookedValue
                    } else {
                        $diskUsage = 0
                    }

                    # Add process performance stats
                    $jobProcesses += [pscustomobject]@{
                        JobId           = $jobId
                        JobName         = $jobName
                        ProcessId       = $proc.Id
                        CPUUsage        = $proc.CPU
                        MemoryUsageMB    = [math]::Round($proc.WorkingSet64 / 1MB, 2)
                        DiskUsageKBps    = [math]::Round($diskUsage / 1KB, 2)
                    }
                } else {
                    Write-Color -Message "Instance name for process ID ${proc.Id} not found." -Type "Warning"
                }
            }
        }

        # Display performance data
        if ($jobProcesses.Count -gt 0) {
            Write-Color -Message "Job Performance Overview:" -Type "Info"
            $jobProcesses | Format-Table -AutoSize
        } else {
            Write-Color -Message "No detailed performance data available for jobs." -Type "Info"
        }
    } catch {
        Write-Color -Message "Failed to retrieve performance data: $($_)" -Type "Error"
    }
}
