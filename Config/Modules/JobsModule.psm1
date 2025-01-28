# JobsModule.psm1

$script:MODULE_NAME = "JobsModule"

# Function to start a background job that persists across SSH sessions
function Start-BackgroundJob {
    <#
    .SYNOPSIS
        Starts a background job that persists beyond SSH session termination.

    .DESCRIPTION
        Runs any PowerShell command in a fully detached process, ensuring it persists
        beyond the user's SSH session. Uses Start-Process (Windows) or nohup (Linux/macOS).

    .PARAMETER Command
        The PowerShell command to run in the background.

    .EXAMPLE
        Start-BackgroundJob "yt-dlp -a download.txt"

    .EXAMPLE
        Start-BackgroundJob "Get-Process | Out-File process_log.txt"
    #>

    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    # Generate a unique job name
    $JobName = "Job_$(Get-Random)"

    if ($IsWindows) {
        # Windows: Start a completely detached PowerShell process
        Start-Process -NoNewWindow -FilePath "pwsh" -ArgumentList "-Command $Command" -PassThru | ForEach-Object {
            Write-Output "Job started: PID $($_.Id), Name $JobName"
        }
    } else {
        # Linux/macOS: Use nohup to detach process
        nohup pwsh -Command "$Command" > "/tmp/$JobName.log" 2>&1 &
        Write-Output "Job started: Name $JobName, Log: /tmp/$JobName.log"
    }
}

# Function to list all active persistent jobs
function Get-ActiveJobs {
    <#
    .SYNOPSIS
        Lists all active background jobs.

    .DESCRIPTION
        Retrieves a list of all currently running PowerShell processes started as persistent jobs.

    .EXAMPLE
        Get-ActiveJobs
    #>

    if ($IsWindows) {
        Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -match "pwsh" } | Select-Object ProcessId, CommandLine
    } else {
        ps -ef | grep "[p]wsh"
    }
}

# Function to stop jobs by ID(s) or Name(s)
function Stop-JobByIdOrName {
    <#
    .SYNOPSIS
        Stops one or more jobs by ID or Name.

    .DESCRIPTION
        Stops specific background jobs based on process ID or command name.

    .PARAMETER JobId
        An array of process IDs to stop.

    .PARAMETER JobName
        An array of job Names (commands) to stop.

    .EXAMPLE
        Stop-JobByIdOrName -JobId 12345

    .EXAMPLE
        Stop-JobByIdOrName -JobName "yt-dlp"
    #>

    param (
        [Parameter(Position = 0, Mandatory = $false)]
        [int[]]$JobId,

        [Parameter(Position = 1, Mandatory = $false)]
        [string[]]$JobName
    )

    if ($JobId) {
        foreach ($id in $JobId) {
            Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
            Write-Output "Stopped job with PID: $id"
        }
    }

    if ($JobName) {
        foreach ($name in $JobName) {
            $processes = Get-Process | Where-Object { $_.ProcessName -like "*$name*" }
            if ($processes) {
                $processes | Stop-Process -Force
                Write-Output "Stopped job(s) matching name: $name"
            } else {
                Write-Output "No job found with name: $name"
            }
        }
    }

    if (-not $JobId -and -not $JobName) {
        Write-Error "You must specify at least one JobId or JobName."
    }
}

# Function to stop all running jobs
function Stop-AllJobs {
    <#
    .SYNOPSIS
        Stops all active background jobs.

    .DESCRIPTION
        Stops all currently running PowerShell processes started as persistent jobs.

    .EXAMPLE
        Stop-AllJobs
    #>

    if ($IsWindows) {
        Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -match "pwsh" } | ForEach-Object {
            Stop-Process -Id $_.ProcessId -Force
        }
    } else {
        ps -ef | grep "[p]wsh" | awk '{print $2}' | xargs kill -9
    }
    Write-Output "Stopped all persistent PowerShell jobs."
}

# Function to track and display job output, with optional in-place printing
function Get-JobOutput {
    <#
    .SYNOPSIS
        Tracks and streams the output of a specified job.

    .DESCRIPTION
        Attaches to a running job and continuously displays its output in real-time.

    .PARAMETER JobId
        The process ID of the job to track.

    .PARAMETER InPlace
        If specified, updates output in place instead of printing new lines.

    .EXAMPLE
        Get-JobOutput -JobId 12345

    .EXAMPLE
        Get-JobOutput -JobId 12345 --In-Place
    #>

    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [int]$JobId,

        [switch]$InPlace
    )

    $process = Get-Process -Id $JobId -ErrorAction SilentlyContinue
    if (-not $process) {
        Write-Error "Job not found."
        return
    }

    Write-Output "Tracking job: PID $JobId"

    if ($InPlace) {
        $cursor = [System.Console]::GetCursorPosition()

        while (-not $process.HasExited) {
            $output = Get-Content "/tmp/Job_$JobId.log" -Tail 10
            if ($output) {
                [System.Console]::SetCursorPosition($cursor.Item1, $cursor.Item2)
                Write-Host $output -NoNewline
            }
            Start-Sleep -Seconds 1
        }

        Write-Output "`nJob $JobId has completed."
    } else {
        while (-not $process.HasExited) {
            Get-Content "/tmp/Job_$JobId.log" -Tail 10
            Start-Sleep -Seconds 1
        }

        Write-Output "Job $JobId has completed."
    }
}

# Export module functions
Export-ModuleMember -Function Start-BackgroundJob, Get-ActiveJobs, Get-JobOutput, Stop-JobByIdOrName, Stop-AllJobs
