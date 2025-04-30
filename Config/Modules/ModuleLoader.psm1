# ModuleLoader.psm1

# ── Always initialize load results list & timer ─────────────────────────────────
$script:ModuleLoadResults = [System.Collections.Generic.List[PSObject]]::new()
$script:ModuleLoadTimer   = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "ModuleLoader Initializing..." -ForegroundColor Cyan

# ── Prevent the loading logic from running more than once ────────────────────────
if ($global:ModuleLoaderLogicHasRun) {
    Write-Host "ModuleLoader logic already run; skipping." -ForegroundColor Yellow
    return
}
$global:ModuleLoaderLogicHasRun = $true
$global:ModuleLoaderFailed     = $false

# ── Custom failure actions for specific modules ─────────────────────────────────
$script:FailureActions = @{
    "ListAliases" = {
        Write-Warning "Custom action: ListAliases failed to load. Check installation/path."
    }
}

# ── Fallback Write-Debug if not available ───────────────────────────────────────
if (-not (Get-Command 'Write-Debug' -ErrorAction SilentlyContinue)) {
    function script:Write-Debug {
        param(
            [string]$Message = "",
            [ValidateSet("Error","Warning","Verbose","Information","Debug")][string]$Channel = "Debug",
            [AllowNull()][object]$Condition = $true,
            [switch]$FileAndLine
        )
        if (-not $global:DebugProfile) { return }
        try { if (-not [bool]$Condition) { return } } catch { return }
        $output = $Message
        if ($FileAndLine) {
            $c = Get-PSCallStack | Select-Object -Skip 1 -First 1
            if ($c.ScriptName) {
                $f = Split-Path $c.ScriptName -Leaf
                $output = "[${f}:${c.ScriptLineNumber}] $Message"
            }
        }
        $colorMap = @{
            Error        = "Red"
            Warning      = "Yellow"
            Verbose      = "Gray"
            Information  = "Cyan"
            Debug        = "Green"
        }
        if ($colorMap.ContainsKey($Channel)) {
            Write-Host $output -ForegroundColor $colorMap[$Channel]
        } else {
            Write-Warning "[Fallback Write-Debug] Invalid channel: $Channel"
        }
    }
    Write-Host "ModuleLoader: Using fallback Write-Debug." -ForegroundColor DarkYellow
}

# ── Function to import a module and record its result ───────────────────────────
function script:Initialize-Module {
    param(
        [string]$ModuleName,
        [string]$ModulePath
    )

    # snapshot before
    $beforeFns = (Get-Command -CommandType Function).Name
    $beforeA   = (Get-Alias).Name

    # prepare result object with new LoadTimeMs field
    $result = [PSCustomObject]@{
        ModuleName = $ModuleName
        Status     = 'Failed'
        Functions  = 0
        Aliases    = 0
        LoadTimeMs = 0.0
        Error      = $null
    }

    # time the import
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        Write-Debug "Importing ${ModuleName}..." -Channel Verbose -Condition $global:DebugProfile
        Import-Module -Name $ModulePath -ErrorAction Stop -Global

        # snapshot after
        $afterFns = (Get-Command -CommandType Function).Name
        $afterA   = (Get-Alias).Name

        $result.Status    = 'Success'
        $result.Functions = (Compare-Object -ReferenceObject $beforeFns -DifferenceObject $afterFns -PassThru).Count
        $result.Aliases   = (Compare-Object -ReferenceObject $beforeA   -DifferenceObject $afterA   -PassThru).Count

        Write-Debug "Imported ${ModuleName}: $($result.Functions) fn, $($result.Aliases) alias" `
            -Channel Information -Condition $global:DebugProfile
    }
    catch {
        $msg = $_.Exception.Message
        Write-Debug "Failed to import ${ModuleName}. Error: $msg" `
            -Channel Error -Condition $global:DebugProfile -FileAndLine
        $result.Error = $msg
        if ($script:FailureActions.ContainsKey($ModuleName)) {
            try { & $script:FailureActions[$ModuleName] } catch { Write-Warning "FailureAction error for ${ModuleName}: $($_.Exception.Message)" }
        }
    }
    finally {
        $timer.Stop()
        $result.LoadTimeMs = [math]::Round($timer.Elapsed.TotalMilliseconds, 2)
        $script:ModuleLoadResults.Add($result)
    }
}

# ── Summary display function ────────────────────────────────────────────────────
function Show-ModuleLoaderSummary {
    if ($script:ModuleLoadTimer.IsRunning) { $script:ModuleLoadTimer.Stop() }

    Write-Host "`nModule Load Summary:"

    if ($script:ModuleLoadResults.Count -eq 0) {
        Write-Host "  No module loading results found." -ForegroundColor Yellow
        return
    }

    $succ = $script:ModuleLoadResults | Where-Object Status -EQ 'Success' | Sort-Object ModuleName
    $fail = $script:ModuleLoadResults | Where-Object Status -EQ 'Failed'  | Sort-Object ModuleName

    if ($succ.Count) {
        Write-Host "`n  Modules Successfully Loaded:" -ForegroundColor Green
        foreach ($m in $succ) {
            Write-Host "   - $($m.ModuleName): $($m.Functions) fn, $($m.Aliases) alias – $($m.LoadTimeMs) ms"
        }
    }
    if ($fail.Count) {
        Write-Host "`n  Modules Failed to Load:" -ForegroundColor Red
        foreach ($m in $fail) {
            $hint = ""
            if ($global:DebugProfile -and $m.Error) {
                $hint = " (Error: $($m.Error.Split([char]10)[0]))"
            }
            Write-Host "   - $($m.ModuleName)$hint"
        }
    }

    $elapsed = [math]::Round($script:ModuleLoadTimer.Elapsed.TotalMilliseconds, 4)
    Write-Host "`nModuleLoader Summary took $elapsed ms"
}

# ── Module discovery & loading ─────────────────────────────────────────────────
$current = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
$path    = $Global:ProfileModulesPath
if (-not (Test-Path $path -PathType Container)) {
    Write-Error "Module directory '$path' not found. Aborting module load."
    $global:ModuleLoaderFailed = $true
}
else {
    $all = Get-ChildItem -Path $path -Filter '*.psm1' -ErrorAction Stop |
           Where-Object BaseName -NotIn @($current, 'DebugUtils')

    if ($Global:OrderedModules -is [array] -and $Global:OrderedModules.Count) {
        $first  = $all | Where-Object { $Global:OrderedModules -contains $_.BaseName }
        $rest   = $all | Where-Object { $Global:OrderedModules -notcontains $_.BaseName }
        $toLoad = $first + ($rest | Sort-Object BaseName)
    }
    else {
        $toLoad = $all | Sort-Object BaseName
    }

    foreach ($mod in $toLoad) {
        Initialize-Module -ModuleName $mod.BaseName -ModulePath $mod.FullName
    }
}

# ── Export the summary function ─────────────────────────────────────────────────
Export-ModuleMember -Function Show-ModuleLoaderSummary
