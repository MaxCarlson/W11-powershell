<#
.SYNOPSIS
Retrieves a list of log files in a specified directory.

.DESCRIPTION
Lists all files in the specified directory that match common log file patterns.

.PARAMETER LogDirectory
The directory to search for log files.

.EXAMPLE
Get-LogFileList -LogDirectory "C:\Logs"
#>
function Get-LogFileList {
    @(
        @{ Name = "IPBan"; Path = "C:\Program Files\IPBan\logfile.txt" }
        @{ Name = "OpenSSH"; Path = "C:\ProgramData\ssh\logs\sshd.log" }
        @{ Name = "System"; Path = "C:\Windows\System32\LogFiles" }
    ) | ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            Path = $_.Path
        }
    }
}

<#
.SYNOPSIS
Monitors a log file for changes.

.DESCRIPTION
Displays new lines added to the log file in real-time.

.PARAMETER LogFile
The path to the log file to monitor.

.EXAMPLE
Watch-LogFile -LogFile "C:\Logs\app.log"
#>
function Watch-LogFile {
    param (
        [Parameter(Mandatory)]
        [string]$LogFilePath,

        [Parameter()]
        [string]$Keyword,

        [int]$PollInterval = 5
    )

    if (-not (Test-Path -Path $LogFilePath)) {
        Write-Error "The log file '${LogFilePath}' does not exist."
        return
    }

    Write-Host "Watching log file: '${LogFilePath}'" -ForegroundColor Green
    if ($Keyword) {
        Write-Host "Filtering for keyword: '${Keyword}'" -ForegroundColor Yellow
    }

    $fileStream = New-Object IO.FileStream -ArgumentList $LogFilePath, 'Open', 'Read', 'ReadWrite'
    $reader = New-Object IO.StreamReader -ArgumentList $fileStream

    try {
        $reader.BaseStream.Seek(0, [System.IO.SeekOrigin]::End) > $null

        while ($true) {
            Start-Sleep -Seconds $PollInterval
            while (-not $reader.EndOfStream) {
                $line = $reader.ReadLine()
                if (-not $Keyword -or $line -match $Keyword) {
                    Write-Host "Log entry: '${line}'" -ForegroundColor Cyan
                }
            }
        }
    } finally {
        $reader.Close()
        $fileStream.Close()
    }
}

<#
.SYNOPSIS
Monitors a predefined common log file.

.DESCRIPTION
Watches a commonly used log file for updates and displays them in real-time.

.PARAMETER LogType
The type of common log to monitor (e.g., Application, System).

.EXAMPLE
Watch-CommonLog -LogType "Application"
#>
function Watch-CommonLog {
    param (
        [Parameter(Mandatory)]
        [string]$LogName,

        [Parameter()]
        [string]$Keyword,

        [int]$PollInterval = 5
    )

    $log = Get-LogFileList | Where-Object { $_.Name -eq $LogName }
    if (-not $log) {
        Write-Error "Log file '${LogName}' not found in common logs."
        return
    }

    Watch-LogFile -LogFilePath $log.Path -Keyword $Keyword -PollInterval $PollInterval
}

Export-ModuleMember -Function Get-LogFileList, Watch-LogFile, Watch-CommonLog

