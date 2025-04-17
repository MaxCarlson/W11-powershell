<#
.SYNOPSIS
    PSProfiler: Comprehensive PowerShell profiling module with stopwatches, timers, and named code-block profiling.
.DESCRIPTION
    This module offers high-resolution timing tools for PowerShell scripts:
      - Discrete stopwatches (start, stop, reset, elapsed)
      - Countdown timers (duration, remaining, expiration)
      - Named code-block profiling with automatic file and line capture
      - Aggregated profiling reports and optional time-limit enforcement
    Designed for easy integration into scripts for benchmarking and performance analysis.
.NOTES
    Module Name: PSProfiler
    Author: ChatGPT
    Version: 1.0.0
#>

function New-PSProfilerStopwatch {
    <#
    .SYNOPSIS
        Creates and starts a high-resolution stopwatch.
    .DESCRIPTION
        Returns a System.Diagnostics.Stopwatch instance already started.
    .OUTPUTS
        System.Diagnostics.Stopwatch
    .EXAMPLE
        # Start a new stopwatch
        $sw = New-PSProfilerStopwatch
    #>
    [CmdletBinding()]
    param()
    process {
        return [System.Diagnostics.Stopwatch]::StartNew()
    }
}

function Start-PSProfilerStopwatch {
    <#
    .SYNOPSIS
        Starts or resumes an existing stopwatch.
    .DESCRIPTION
        Begins timing on the provided System.Diagnostics.Stopwatch. Useful after a Stop or Reset.
    .PARAMETER Stopwatch
        The stopwatch object to start or resume.
    .EXAMPLE
        $sw = New-PSProfilerStopwatch
        Stop-PSProfilerStopwatch -Stopwatch $sw
        Start-PSProfilerStopwatch -Stopwatch $sw
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Diagnostics.Stopwatch]$Stopwatch
    )
    process {
        $Stopwatch.Start()
    }
}

function Stop-PSProfilerStopwatch {
    <#
    .SYNOPSIS
        Stops a running stopwatch.
    .DESCRIPTION
        Halts timing on the given System.Diagnostics.Stopwatch.
    .PARAMETER Stopwatch
        The stopwatch object to stop.
    .EXAMPLE
        $sw = New-PSProfilerStopwatch
        # ... code ...
        Stop-PSProfilerStopwatch -Stopwatch $sw
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Diagnostics.Stopwatch]$Stopwatch
    )
    process {
        $Stopwatch.Stop()
    }
}

function Reset-PSProfilerStopwatch {
    <#
    .SYNOPSIS
        Resets a stopwatch to zero elapsed time.
    .DESCRIPTION
        Clears the elapsed time of the provided System.Diagnostics.Stopwatch without starting it.
    .PARAMETER Stopwatch
        The stopwatch object to reset.
    .EXAMPLE
        $sw = New-PSProfilerStopwatch
        # ... code ...
        Reset-PSProfilerStopwatch -Stopwatch $sw
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Diagnostics.Stopwatch]$Stopwatch
    )
    process {
        $Stopwatch.Reset()
    }
}

function Get-PSProfilerElapsedTime {
    <#
    .SYNOPSIS
        Retrieves the elapsed time from a stopwatch.
    .DESCRIPTION
        Returns a System.TimeSpan representing the total elapsed duration of the stopwatch.
    .PARAMETER Stopwatch
        The stopwatch object to query.
    .OUTPUTS
        System.TimeSpan
    .EXAMPLE
        $sw = New-PSProfilerStopwatch
        Start-Sleep -Seconds 1
        Stop-PSProfilerStopwatch -Stopwatch $sw
        $elapsed = Get-PSProfilerElapsedTime -Stopwatch $sw
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Diagnostics.Stopwatch]$Stopwatch
    )
    process {
        return $Stopwatch.Elapsed
    }
}

function New-PSProfilerTimer {
    <#
    .SYNOPSIS
        Creates a countdown timer for a specified duration.
    .DESCRIPTION
        Returns a PSCustomObject containing a TimeSpan Duration and a started Stopwatch.
    .PARAMETER Seconds
        The number of seconds for the countdown duration.
    .OUTPUTS
        PSCustomObject with properties Duration (TimeSpan) and Stopwatch.
    .EXAMPLE
        $timer = New-PSProfilerTimer -Seconds 30
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [double]$Seconds
    )
    process {
        [PSCustomObject]@{
            Duration  = [TimeSpan]::FromSeconds($Seconds)
            Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        }
    }
}

function Get-PSProfilerTimerRemaining {
    <#
    .SYNOPSIS
        Gets remaining time on a countdown timer.
    .DESCRIPTION
        Calculates Duration minus elapsed time on the timer object.
    .PARAMETER Timer
        The PSCustomObject returned by New-PSProfilerTimer.
    .OUTPUTS
        System.TimeSpan
    .EXAMPLE
        $remaining = Get-PSProfilerTimerRemaining -Timer $timer
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Timer
    )
    process {
        return $Timer.Duration - $Timer.Stopwatch.Elapsed
    }
}

function Get-PSProfilerTimerExpired {
    <#
    .SYNOPSIS
        Checks if a countdown timer has expired.
    .DESCRIPTION
        Returns True if elapsed time >= Duration.
    .PARAMETER Timer
        The PSCustomObject returned by New-PSProfilerTimer.
    .OUTPUTS
        Boolean
    .EXAMPLE
        if (Get-PSProfilerTimerExpired -Timer $timer) { Write-Host 'Time up!' }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Timer
    )
    process {
        return $Timer.Stopwatch.Elapsed -ge $Timer.Duration
    }
}

function Measure-PSProfiler {
    <#
    .SYNOPSIS
        Measures execution time of a script block.
    .DESCRIPTION
        Executes the script block and returns a TimeSpan of elapsed time.
    .PARAMETER ScriptBlock
        The code block to execute and measure.
    .OUTPUTS
        System.TimeSpan
    .EXAMPLE
        $time = Measure-PSProfiler { Get-ChildItem }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ScriptBlock]$ScriptBlock
    )
    process {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & $ScriptBlock
        $sw.Stop()
        return $sw.Elapsed
    }
}

function New-PSProfiler {
    <#
    .SYNOPSIS
        Initializes a global profiler session.
    .DESCRIPTION
        Creates a global $PSProfiler object to collect named block timings.
        Optionally accepts a TimeLimitSeconds to auto-report after that duration.
    .PARAMETER TimeLimitSeconds
        Optional. Seconds after which to auto-report the profiler.
    .OUTPUTS
        PSCustomObject
    .EXAMPLE
        $p = New-PSProfiler -TimeLimitSeconds 60
    #>
    [CmdletBinding()]
    param(
        [double]$TimeLimitSeconds
    )
    begin {
        $tl = $null
        if ($PSBoundParameters.ContainsKey('TimeLimitSeconds')) { $tl = [TimeSpan]::FromSeconds($TimeLimitSeconds) }
        $global:PSProfiler = [PSCustomObject]@{
            StartTime = Get-Date
            TimeLimit = $tl
            Blocks    = New-Object System.Collections.Generic.List[PSObject]
        }
        return $global:PSProfiler
    }
}

function Invoke-PSProfilerBlock {
    <#
    .SYNOPSIS
        Profiles a named code block.
    .DESCRIPTION
        Executes the script block, records start/end line and file context,
        captures elapsed time, and adds to $PSProfiler.Blocks.
    .PARAMETER Name
        A label for this code block.
    .PARAMETER ScriptBlock
        The code block to execute and profile.
    .EXAMPLE
        Invoke-PSProfilerBlock -Name 'LoadData' -ScriptBlock { Import-Csv data.csv }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ScriptBlock]$ScriptBlock
    )
    begin {
        if (-not $global:PSProfiler) { throw 'Profiler not initialized. Call New-PSProfiler first.' }
        $invInfo = $PSCmdlet.MyInvocation
        $sw      = [System.Diagnostics.Stopwatch]::StartNew()
    }
    process {
        & $ScriptBlock
    }
    end {
        $sw.Stop()
        $block = [PSCustomObject]@{
            Name      = $Name
            File      = $invInfo.ScriptName
            StartLine = $invInfo.ScriptLineNumber
            EndLine   = $invInfo.ScriptLineNumber + ($invInfo.Line.Length)
            Duration  = $sw.Elapsed
        }
        $global:PSProfiler.Blocks.Add($block)
    }
}

function Get-PSProfilerReport {
    <#
    .SYNOPSIS
        Outputs an aggregated report of all profiled blocks.
    .DESCRIPTION
        Displays each block's name, duration, file, and line range,
        followed by total elapsed time and optional time-limit info.
    .EXAMPLE
        Get-PSProfilerReport
    #>
    [CmdletBinding()]
    param()
    process {
        $p = $global:PSProfiler
        Write-Host "Profiler Start: $($p.StartTime)"
        if ($p.TimeLimit) { Write-Host "Time Limit: $($p.TimeLimit)" }
        Write-Host ''
        Write-Host 'Block Profile Report:'
        foreach ($b in $p.Blocks) {
            Write-Host ('{0,-20} {1} {2}:{3}-{4}' -f $b.Name, $b.Duration, (Split-Path $b.File -Leaf), $b.StartLine, $b.EndLine)
        }
        $total = (Get-Date) - $p.StartTime
        Write-Host ''; Write-Host "Total Elapsed: $total"
    }
}

function Wait-PSProfilerTimeLimit {
    <#
    .SYNOPSIS
        Waits until the profiler's time limit and then reports.
    .DESCRIPTION
        Sleeps in 100ms intervals until the specified TimeLimitSeconds has passed,
        then calls Get-PSProfilerReport.
    .EXAMPLE
        $p = New-PSProfiler -TimeLimitSeconds 10
        Wait-PSProfilerTimeLimit
    #>
    [CmdletBinding()]
    param()
    process {
        $p = $global:PSProfiler
        if (-not $p.TimeLimit) { throw 'No TimeLimit set. Use New-PSProfiler -TimeLimitSeconds.' }
        $deadline = $p.StartTime + $p.TimeLimit
        while ((Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 100 }
        Get-PSProfilerReport
    }
}

function Get-Stopwatch {
    [CmdletBinding()]
    param(
        [Boolean]$InPlace = $true
    )
    # Inital declaration on null stopwatch 
    # only commented because I learned how declaration of null types works in pwsh
    [System.Diagnostics.Stopwatch]$sw

    if ($InPlace) {
        $sw=[System.Diagnostics.Stopwatch]::StartNew();while($true){Write-Host "`r$($sw.Elapsed)" -NoNewline; Start-Sleep -Milliseconds 100}
    } else {
        $sw=[System.Diagnostics.Stopwatch]::StartNew();while($true){Write-Host $sw.Elapsed; Start-Sleep -Milliseconds 100}
    }
    return $sw
}

Export-ModuleMember -Function '*-PSProfiler*', '*-PSProfilerStopwatch*', '*-PSProfilerTimer*', 'Measure-PSProfiler', Get-Stopwatch


