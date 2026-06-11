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
$global:AliasOverrides         = [System.Collections.Generic.List[PSObject]]::new()

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

    # prepare result object with new LoadTimeMs field
    $result = [PSCustomObject]@{
        ModuleName = $ModuleName
        Status     = 'Failed'
        LoadMode   = 'Eager'
        Functions  = 0
        Aliases    = 0
        LoadTimeMs = 0.0
        Error      = $null
    }

    # time the import
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        Write-Debug "Importing ${ModuleName}..." -Channel Verbose -Condition $global:DebugProfile
        $moduleInfo = Import-Module -Name $ModulePath -ErrorAction Stop -Global -PassThru

        $result.Status    = 'Success'
        $result.Functions = @($moduleInfo.ExportedFunctions.Keys).Count
        $result.Aliases   = @($moduleInfo.ExportedAliases.Keys).Count

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

function script:Get-ModuleFunctionNamesFromAst {
    param([Parameter(Mandatory)][string]$ModulePath)

    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ModulePath, [ref]$tokens, [ref]$errors)
    if ($errors -and $errors.Count -gt 0) {
        throw "Cannot parse module for lazy loading: $($errors[0].Message)"
    }

    $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -notlike '*:*'
    }, $true) |
        ForEach-Object { $_.Name } |
        Sort-Object -Unique
}

function script:Register-LazyModule {
    param(
        [Parameter(Mandatory)][string]$ModuleName,
        [Parameter(Mandatory)][string]$ModulePath
    )

    $result = [PSCustomObject]@{
        ModuleName = $ModuleName
        Status     = 'Lazy'
        LoadMode   = 'Lazy'
        Functions  = 0
        Aliases    = 0
        LoadTimeMs = 0.0
        Error      = $null
    }

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        if (-not $global:LazyModuleRegistry) {
            $global:LazyModuleRegistry = @{}
        }

        $functionNames = @()
        if ($Global:LazyModuleFunctions -is [hashtable] -and $Global:LazyModuleFunctions.ContainsKey($ModuleName)) {
            $functionNames = @($Global:LazyModuleFunctions[$ModuleName])
        }
        else {
            $functionNames = @(Get-ModuleFunctionNamesFromAst -ModulePath $ModulePath)
        }
        $registryEntry = [pscustomobject]@{
            ModuleName     = $ModuleName
            ModulePath     = $ModulePath
            FunctionNames  = @($functionNames)
        }
        foreach ($functionName in $functionNames) {
            $global:LazyModuleRegistry[$functionName] = $registryEntry
            $escapedFunctionName = $functionName.Replace("'", "''")
            $wrapper = [scriptblock]::Create(@"
`$entry = `$global:LazyModuleRegistry['$escapedFunctionName']
foreach (`$name in `$entry.FunctionNames) {
    Remove-Item -Path "function:`$name" -Force -ErrorAction SilentlyContinue
}
Import-Module -Name `$entry.ModulePath -ErrorAction Stop -Global
`$command = Get-Command -Name '$escapedFunctionName' -CommandType Function -ErrorAction Stop
& `$command @args
"@)

            Set-Item -LiteralPath "Function:\global:$functionName" -Value $wrapper -Force
        }

        $result.Functions = $functionNames.Count
    }
    catch {
        $result.Status = 'Failed'
        $result.Error = $_.Exception.Message
        $global:ModuleLoaderFailed = $true
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

    $succ = $script:ModuleLoadResults | Where-Object { $_.Status -in @('Success','Lazy') } | Sort-Object ModuleName
    $fail = $script:ModuleLoadResults | Where-Object Status -EQ 'Failed'  | Sort-Object ModuleName

    if ($succ.Count) {
        Write-Host "`n  Modules Loaded or Registered:" -ForegroundColor Green
        foreach ($m in $succ) {
            Write-Host "   - $($m.ModuleName) [$($m.LoadMode)]: $($m.Functions) fn, $($m.Aliases) alias - $($m.LoadTimeMs) ms"
            if ($global:AliasOverrides -and $global:AliasOverrides.Count) {
                $moduleOverrides = $global:AliasOverrides | Where-Object ModuleName -EQ $m.ModuleName
                if ($moduleOverrides.Count) {
                    Write-Host "`t- Default Commands overridden:" -ForegroundColor Cyan
                    foreach ($alias in $moduleOverrides) {
                        $type = $alias.CommandType
                        $details = "$type '$($alias.Name)' - $($alias.Definition)"
                        Write-Host "`t`t- $details" -ForegroundColor DarkCyan
                    }
                    Write-Host ""
                }
            }
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
           Where-Object BaseName -NotIn @($current, 'DebugUtils', 'AutoExportModule')

    if ($Global:OrderedModules -is [array] -and $Global:OrderedModules.Count) {
        $first  = $all | Where-Object { $Global:OrderedModules -contains $_.BaseName }
        $rest   = $all | Where-Object { $Global:OrderedModules -notcontains $_.BaseName }
        $toLoad = $first + ($rest | Sort-Object BaseName)
    }
    else {
        $toLoad = $all | Sort-Object BaseName
    }

    foreach ($mod in $toLoad) {
        if ($Global:LazyModules -is [array] -and $Global:LazyModules -contains $mod.BaseName) {
            Register-LazyModule -ModuleName $mod.BaseName -ModulePath $mod.FullName
        }
        else {
            Initialize-Module -ModuleName $mod.BaseName -ModulePath $mod.FullName
        }
    }
    $script:ModuleLoadTimer.Stop()
}

# ── Export the summary function ─────────────────────────────────────────────────
Export-ModuleMember -Function Show-ModuleLoaderSummary
