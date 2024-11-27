# Core Job Lifecycle Management

# Starts a new background job
function Start-BackgroundJob {
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [string]$JobName = "UnnamedJob"
    )

    try {
        $job = Start-Job -ScriptBlock $ScriptBlock -Name $JobName
        Write-Color -Message "Job '$JobName' started with ID $($job.Id)." -Type "Success"
        return $job
    } catch {
        Write-Color -Message "Failed to start job: $_" -Type "Error"
    }
}

# Retrieves all active background jobs
function Get-ActiveBackgroundJobs {
    try {
        $jobs = Get-Job | Where-Object { $_.State -eq "Running" }
        if ($jobs.Count -eq 0) {
            Write-Color -Message "No active jobs found." -Type "Info"
        } else {
            Write-Color -Message "Active jobs:" -Type "Info"
            $jobs | ForEach-Object {
                Write-Color -Message "ID: $($_.Id), Name: $($_.Name), State: $($_.State)" -Type "Debug"
            }
        }
        return $jobs
    } catch {
        Write-Color -Message "Failed to retrieve active jobs: $_" -Type "Error"
    }
}

# Stops all running jobs
function Stop-AllBackgroundJobs {
    try {
        $jobs = Get-Job | Where-Object { $_.State -eq "Running" }
        if ($jobs.Count -eq 0) {
            Write-Color -Message "No jobs to stop." -Type "Info"
            return
        }
        $jobs | Stop-Job -Force
        Write-Color -Message "Stopped all running jobs." -Type "Success"
    } catch {
        Write-Color -Message "Failed to stop all jobs: $_" -Type "Error"
    }
}

# Stops a specific job by ID
function Stop-BackgroundJobById {
    param (
        [Parameter(Mandatory = $true)]
        [int]$JobId
    )

    try {
        Stop-Job -Id $JobId -Force
        Write-Color -Message "Job with ID $JobId has been stopped." -Type "Success"
    } catch {
        Write-Color -Message "Failed to stop job with ID $JobId: $_" -Type "Error"
    }
}
