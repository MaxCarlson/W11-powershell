# Core Job Lifecycle Management

# Starts a new background job and redirects output to a log file


function Start-BackgroundJob {
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [string]$JobName = "UnnamedJob"
    )

    try {
        # Start the background job without log file redirection
        $job = Start-Job -ScriptBlock {
            $ExecutionContext.InvokeCommand.ExpandString($using:ScriptBlock)
        } -Name $JobName

        # Print out the Job ID immediately after starting the job
        Write-Color -Message "Job '${JobName}' started with ID $($job.Id)" -Type "Success"

        # Return the job object to allow further interaction with it
        return $job
    } catch {
        Write-Color -Message "Failed to start job: $($_)" -Type "Error"
    }
}

# Retrieves all active background jobs
function Get-ActiveBackgroundJobs {
    try {
        # Get all jobs with a state of 'Running'
        $jobs = Get-Job | Where-Object { $_.State -eq "Running" }
        
        if ($jobs.Count -eq 0) {
            Write-Color -Message "No active jobs found." -Type "Info"
        } else {
            Write-Color -Message "Active jobs:" -Type "Info"
            
            # Loop through and display jobs in a cleaner format
            $jobs | ForEach-Object {
                Write-Color -Message "ID: $($_.Id), Name: $($_.Name), State: $($_.State)" -Type "Debug"
            }
        }
        return $jobs
    } catch {
        Write-Color -Message "Failed to retrieve active jobs: $($_)" -Type "Error"
    }
}

# Retrieves output of a job in real-time
function Get-RealTimeJobOutput {
    param (
        [Parameter(Mandatory = $true)] 
        [int]$JobId
    )

    try {
        # Retrieve the job object by ID
        $job = Get-Job -Id $JobId
        if ($job) {
            Write-Color -Message "Streaming output from Job ID ${JobId}:" -Type "Info"

            # Continuously stream output from the job as it runs
            while ($job.State -eq "Running") {
                $output = Receive-Job -Job $job -Wait -Keep
                if ($output) {
                    Write-Color -Message "$output" -Type "Info"
                }
                Start-Sleep -Seconds 1  # Adjust the sleep time as needed
            }

            # After the job finishes, print any remaining output
            $output = Receive-Job -Job $job -Wait -AutoRemoveJob
            if ($output) {
                Write-Color -Message "$output" -Type "Info"
            }
        } else {
            Write-Color -Message "Job with ID ${JobId} not found." -Type "Error"
        }
    } catch {
        Write-Color -Message "Failed to retrieve job output for Job ID ${JobId}: $($_)" -Type "Error"
    }
}


# Stops all running jobs, excluding 'PowerShell.OnIdle'
function Stop-AllBackgroundJobs {
    try {
        $jobs = Get-Job | Where-Object { $_.State -eq "Running" -and $_.Name -ne "PowerShell.OnIdle" }
        
        if ($jobs.Count -eq 0) {
            Write-Color -Message "No jobs to stop." -Type "Info"
            return
        }
        
        # Stop all other jobs except PowerShell.OnIdle
        $jobs | Stop-Job -Force
        Write-Color -Message "Stopped all running jobs (excluding 'PowerShell.OnIdle')." -Type "Success"
    } catch {
        Write-Color -Message "Failed to stop all jobs: $($_)" -Type "Error"
    }
}


# Stops a specific job by ID, excluding 'PowerShell.OnIdle'
function Stop-BackgroundJobById {
    param (
        [Parameter(Mandatory = $true)]
        [int]$JobId
    )

    try {
        # Get the job by ID
        $job = Get-Job -Id $JobId

        if ($job.Name -eq "PowerShell.OnIdle") {
            Write-Color -Message "Cannot stop 'PowerShell.OnIdle' job." -Type "Error"
            return
        }

        Stop-Job -Id $JobId -Force
        Write-Color -Message "Job with ID ${JobId} has been stopped." -Type "Success"
    } catch {
        Write-Color -Message "Failed to stop job with ID ${JobId}: $($_)" -Type "Error"
    }
}
