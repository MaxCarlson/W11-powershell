# JobsModule.psm1

$script:MODULE_NAME = "JobsModule"
$script:PersistentJobs = @{}

function script:Get-JobLogPath {
    param([Parameter(Mandatory)][string]$JobName)
    Join-Path ([System.IO.Path]::GetTempPath()) "$JobName.log"
}

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

    $JobName = "Job_$(Get-Random)"
    $LogPath = Get-JobLogPath -JobName $JobName

    if ($IsWindows) {
        $process = Start-Process -WindowStyle Hidden -FilePath "pwsh" -ArgumentList @(
            '-NoLogo',
            '-NoProfile',
            '-Command',
            "& { $Command } *> '$LogPath'"
        ) -PassThru
        $script:PersistentJobs[$process.Id] = [pscustomobject]@{
            Id      = $process.Id
            Name    = $JobName
            Command = $Command
            LogPath = $LogPath
        }
        Write-Output "Job started: PID $($process.Id), Name $JobName, Log: $LogPath"
    } else {
        $process = Start-Process -FilePath "nohup" -ArgumentList @('pwsh', '-NoLogo', '-NoProfile', '-Command', $Command) -RedirectStandardOutput $LogPath -RedirectStandardError $LogPath -PassThru
        $script:PersistentJobs[$process.Id] = [pscustomobject]@{
            Id      = $process.Id
            Name    = $JobName
            Command = $Command
            LogPath = $LogPath
        }
        Write-Output "Job started: PID $($process.Id), Name $JobName, Log: $LogPath"
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

    foreach ($job in $script:PersistentJobs.Values) {
        $process = Get-Process -Id $job.Id -ErrorAction SilentlyContinue
        if ($process) {
            $job
        }
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
            if (-not $script:PersistentJobs.ContainsKey($id)) {
                Write-Output "PID $id is not tracked by JobsModule. Skipping."
                continue
            }
            Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
            $script:PersistentJobs.Remove($id)
            Write-Output "Stopped job with PID: $id"
        }
    }

    if ($JobName) {
        foreach ($name in $JobName) {
            $matches = @($script:PersistentJobs.Values | Where-Object { $_.Name -like "*$name*" -or $_.Command -like "*$name*" })
            if ($matches) {
                foreach ($job in $matches) {
                    Stop-Process -Id $job.Id -Force -ErrorAction SilentlyContinue
                    $script:PersistentJobs.Remove($job.Id)
                }
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

    foreach ($job in @($script:PersistentJobs.Values)) {
        Stop-Process -Id $job.Id -Force -ErrorAction SilentlyContinue
        $script:PersistentJobs.Remove($job.Id)
    }
    Write-Output "Stopped all JobsModule-tracked persistent jobs."
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

    $tracked = $script:PersistentJobs[$JobId]
    if (-not $tracked) {
        Write-Error "Job $JobId is not tracked by JobsModule."
        return
    }

    Write-Output "Tracking job: PID $JobId"

    if ($InPlace) {
        $cursor = [System.Console]::GetCursorPosition()

        while (-not $process.HasExited) {
            $output = Get-Content $tracked.LogPath -Tail 10 -ErrorAction SilentlyContinue
            if ($output) {
                [System.Console]::SetCursorPosition($cursor.Item1, $cursor.Item2)
                Write-Host $output -NoNewline
            }
            Start-Sleep -Seconds 1
        }

        Write-Output "`nJob $JobId has completed."
    } else {
        while (-not $process.HasExited) {
            Get-Content $tracked.LogPath -Tail 10 -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        }

        Write-Output "Job $JobId has completed."
    }
}

# Export module functions
Export-ModuleMember -Function Start-BackgroundJob, Get-ActiveJobs, Get-JobOutput, Stop-JobByIdOrName, Stop-AllJobs
