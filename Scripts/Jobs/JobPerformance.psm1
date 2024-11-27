# Performance Analysis for Background Jobs

# Gets performance metrics of background jobs
function Get-BackgroundJobPerformance {
    try {
        $jobs = Get-Job | Where-Object { $_.State -eq "Running" }
        if ($jobs.Count -eq 0) {
            Write-Color -Message "No active jobs to analyze." -Type "Info"
            return
        }

        $jobProcesses = $jobs | ForEach-Object {
            $jobName = $_.Name
            $jobId = $_.Id
            $processId = $_.ChildJobs[0].Id
            if ($processId -ne $null) {
                $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
                if ($process) {
                    [pscustomobject]@{
                        JobId          = $jobId
                        JobName        = $jobName
                        ProcessId      = $process.Id
                        CPUUsage       = $process.CPU
                        MemoryUsageMB  = Convert-BytesToMB $process.WorkingSet64
                    }
                }
            }
        }

        if ($jobProcesses) {
            Write-Color -Message "Job Performance Overview:" -Type "Info"
            $jobProcesses | Format-Table -AutoSize
        } else {
            Write-Color -Message "No detailed performance data available for jobs." -Type "Info"
        }
    } catch {
        Write-Color -Message "Failed to retrieve performance data: $_" -Type "Error"
    }
}

# Converts bytes to MB
function Convert-BytesToMB {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Bytes
    )
    return [math]::Round($Bytes / 1MB, 2)
}
