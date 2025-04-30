# Module-Loader.psm1

# Initialization block to prevent multiple executions and setup script-scoped variables
if (-not $global:ModuleImportedModuleLoader) {
    $global:ModuleImportedModuleLoader = $true
    # Initialize storage for results within the module's script scope
    $script:ModuleLoadResults = [System.Collections.Generic.List[PSObject]]::new()
    $script:ModuleLoadTimer = [System.Diagnostics.Stopwatch]::new()
    Write-Host "ModuleLoader Initializing..." -ForegroundColor Cyan
} else {
    Write-Host "Attempting to import ModuleLoader twice! Skipping re-initialization." -ForegroundColor Yellow
}

# Define custom failure actions for specific modules (adjust keys to match BaseName)
$Script:FailureActions = @{
    "ListAliases" = {
        Write-Warning "Custom action: ListAliases failed to load. Check installation/path."
    }
}

# Fallback Write-Debug function
if (-not (Get-Command 'Write-Debug' -ErrorAction SilentlyContinue)) {
    function script:Write-Debug { param([string]$Message="",[string]$Channel="Debug",[AllowNull()][object]$Condition=$true,[switch]$FileAndLine)
        $isDebugEnabled = $false; if(Test-Path variable:global:DebugProfile){$isDebugEnabled = $global:DebugProfile}; if(-not $isDebugEnabled){return}
        $isConditionMet = $true; if($Condition -ne $null){try {$isConditionMet = [bool]$Condition} catch {Write-Warning "[Fallback Write-Debug] Invalid Condition value: '$Condition'";$isConditionMet = $false}}; if(-not $isConditionMet){return}
        $outputMessage = "[Fallback $Channel] $Message"; if ($FileAndLine) {$outputMessage = "[?:?] [Fallback $Channel] $Message"}
        Write-Host $outputMessage -ForegroundColor Gray }
    Write-Host "ModuleLoader: Using fallback Write-Debug." -ForegroundColor DarkYellow
}

# Function to load a module and record results
function script:Initialize-Module {
    param (
        [string]$ModuleName,
        [string]$ModulePath
    )
    $functionsBefore = (Get-Command -CommandType Function).Name
    $aliasesBefore = (Get-Alias).Name
    $result = [PSCustomObject]@{ ModuleName = $ModuleName; Status = 'Failed'; Functions = 0; Aliases = 0; Error = $null }

    try {
        Write-Debug "Importing Module: $ModuleName..." -Channel Verbose -Condition $global:DebugProfile
        # --- Use -Global, remove -Verbose ---
        Import-Module -Name $ModulePath -ErrorAction Stop -Global

        $functionsAfter = (Get-Command -CommandType Function).Name
        $aliasesAfter = (Get-Alias).Name
        $addedFunctions = (Compare-Object -ReferenceObject $functionsBefore -DifferenceObject $functionsAfter -PassThru).Count
        $addedAliases = (Compare-Object -ReferenceObject $aliasesBefore -DifferenceObject $aliasesAfter -PassThru).Count

        $result.Status = 'Success'
        $result.Functions = $addedFunctions
        $result.Aliases = $addedAliases
        Write-Debug "Successfully imported module: $ModuleName ($($result.Functions) functions, $($result.Aliases) aliases)" -Channel "Debug" -Condition $global:DebugProfile

    } catch {
        $errorMsg = $_.Exception.Message
        Write-Debug "ModuleLoader: Failed to import module: $ModuleName. Error: $errorMsg" -Channel "Error" -Condition $global:DebugProfile -FileAndLine
        $result.Status = 'Failed'
        $result.Error = $errorMsg
        if ($Script:FailureActions.ContainsKey($ModuleName)) {
             Write-Debug "Executing custom failure action for $ModuleName" -Channel Information -Condition $global:DebugProfile
             try { & $Script:FailureActions[$ModuleName] } catch { Write-Warning "Error executing custom failure action for '$ModuleName': $($_.Exception.Message)" }
        }
    } finally {
        # Add result to the list (this assumes the list initialization worked in the first block)
        if ($script:ModuleLoadResults -ne $null) {
             $script:ModuleLoadResults.Add($result)
        } else {
             # If this warning appears, the list initialization failed earlier
             Write-Warning "[Initialize-Module] ModuleLoadResults list was unexpectedly null when trying to store result for $ModuleName."
        }
    }
}


# --- *** MODIFIED Summary Display Function *** ---
function Show-ModuleLoaderSummary {
    if ($script:ModuleLoadTimer -and $script:ModuleLoadTimer.IsRunning) { $script:ModuleLoadTimer.Stop() }

    Write-Host "`nModule Load Summary:" # Start with a newline for spacing

    # Check if results were collected
    # Use the list initialized in the main 'if (-not $global:ModuleImportedModuleLoader)' block
    if ($null -eq $script:ModuleLoadResults -or $script:ModuleLoadResults.Count -eq 0) {
        Write-Host "  No module loading results found or collected." -ForegroundColor Yellow
    } else {
        $successfulModules = $script:ModuleLoadResults | Where-Object { $_.Status -eq 'Success' } | Sort-Object ModuleName
        $failedModules = $script:ModuleLoadResults | Where-Object { $_.Status -eq 'Failed' } | Sort-Object ModuleName

        # --- Display Successes ---
        if ($successfulModules.Count -gt 0) {
            Write-Host # Add a blank line before the section
            Write-Host "  Modules Successfully Loaded:" -ForegroundColor Green
            foreach ($module in $successfulModules) {
                # Output format: "   - ModuleName: X functions, Y aliases"
                Write-Host "   - $($module.ModuleName): $($module.Functions) functions, $($module.Aliases) aliases"
            }
        } else {
             Write-Host # Add a blank line even if none succeeded
             Write-Host "  No modules loaded successfully." -ForegroundColor Yellow
        }

        # --- Display Failures ---
        if ($failedModules.Count -gt 0) {
            Write-Host # Add a blank line before the section
            Write-Host "  Modules Failed to Load:" -ForegroundColor Red
            foreach ($module in $failedModules) {
                 $errorHint = ""
                 # Optionally show error inline only if debug profile is enabled
                 if ($global:DebugProfile -and $module.Error) {
                     # Keep error message concise for summary view
                     $conciseError = ($module.Error -split '[\r\n]+')[0] # Get first line of error
                     $errorHint = " (Error: $conciseError)"
                 }
                 Write-Host "   - $($module.ModuleName)$errorHint"
            }
        }
        # else { Write-Host "`n  No module loading failures." -ForegroundColor Green } # Optional success confirmation
    }

    # --- Display total time ---
    if ($script:ModuleLoadTimer) {
        $elapsedMs = $script:ModuleLoadTimer.Elapsed.TotalMilliseconds
        Write-Host # Add blank line before timing
        Write-Host "ModuleLoader Summary took $($elapsedMs.ToString('F4')) ms"
    } else {
        Write-Warning "ModuleLoadTimer was not available to report duration."
    }
}


# --- Module Loading Execution Logic ---
# This part runs when the module is imported

# Check if the main initialization block ran successfully
if ($global:ModuleImportedModuleLoader -and $script:ModuleLoadTimer) {

    # Prevent re-running the loading logic itself if module is re-imported/dot-sourced
    if (-not $global:ModuleLoaderLogicHasRun) {
        $global:ModuleLoaderLogicHasRun = $true # Set flag after first execution

        $currentModuleName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
        $modulePath = $Global:ProfileModulesPath
        if (-not ($modulePath -and (Test-Path $modulePath -PathType Container))) {
            Write-Error "Global variable `$Global:ProfileModulesPath` not set or points to a non-existent directory. Module loading cannot proceed."
        } else {
            Write-Debug "Module search path: $modulePath" -Channel Information -Condition $global:DebugProfile
            $Script:AllModules = @()
            try { $Script:AllModules = Get-ChildItem -Path $modulePath -Filter *.psm1 -ErrorAction Stop | Where-Object { $_.BaseName -ne $currentModuleName -and $_.BaseName -ne "DebugUtils" } }
            catch { Write-Error "Failed to list modules in '$modulePath': $($_.Exception.Message)" }

            # Check ordered modules list (Use the corrected logic from previous working version)
            $orderedModuleNames = @()
            if ((Test-Path variable:global:OrderedModules) -and ($null -ne $Global:OrderedModules) -and ($Global:OrderedModules -is [array])) { $orderedModuleNames = $Global:OrderedModules }
            if ($orderedModuleNames.Count -gt 0) { Write-Debug "Using ordered modules list: $($orderedModuleNames -join ', ')" -Channel Debug -Condition $global:DebugProfile }
            else { Write-Debug "No valid ordered modules list found." -Channel Debug -Condition $global:DebugProfile }

            $Script:ModulesToLoadFirst = $Script:AllModules | Where-Object { $orderedModuleNames -contains $_.BaseName }
            $Script:RemainingModules = $Script:AllModules | Where-Object { $orderedModuleNames -notcontains $_.BaseName }

            $script:ModuleLoadTimer.Reset(); $script:ModuleLoadTimer.Start()

            # Load ordered modules
            if ($orderedModuleNames.Count -gt 0) {
                 Write-Debug "Loading Ordered Modules..." -Channel Information -Condition $global:DebugProfile
                 foreach ($ModuleName in $orderedModuleNames) {
                     $Module = $ModulesToLoadFirst | Where-Object { $_.BaseName -eq $ModuleName }
                     if ($Module) { Initialize-Module -ModuleName $Module.BaseName -ModulePath $Module.FullName }
                     else { # Handle missing ordered module
                          Write-Debug "Ordered module '$ModuleName' not found in path '$($Global:ProfileModulesPath)'." -Channel "Warning" -Condition $global:DebugProfile
                          if ($script:ModuleLoadResults -ne $null){ $script:ModuleLoadResults.Add([PSCustomObject]@{ ModuleName = $ModuleName; Status = 'Failed'; Functions = 0; Aliases = 0; Error = 'Module file not found in specified path.'}) }
                          else { Write-Warning "[Loading Logic] ModuleLoadResults was null when adding missing ordered module '$ModuleName'." }
                     }
                 }
            }

            # Load remaining modules
            $remainingNames = ($Script:RemainingModules | Sort-Object BaseName).BaseName -join ', '
            if ($remainingNames) {
                 Write-Debug "Loading Remaining Modules: $remainingNames" -Channel Information -Condition $global:DebugProfile
                 foreach ($Module in ($Script:RemainingModules | Sort-Object BaseName)) { Initialize-Module -ModuleName $Module.BaseName -ModulePath $Module.FullName }
            } else { Write-Debug "No remaining modules to load." -Channel Information -Condition $global:DebugProfile }

            $script:ModuleLoadTimer.Stop()
            Write-Debug "Module loading loop finished. Timer stopped." -Channel Verbose -Condition $global:DebugProfile
        }
    } else {
        Write-Debug "ModuleLoader: Logic already run this session, skipping reload." -Channel Information -Condition $global:DebugProfile
    }

} # End of $global:ModuleImportedModuleLoader check

# --- Export the summary function ---
Export-ModuleMember -Function Show-ModuleLoaderSummary

Write-Debug "ModuleLoader.psm1 execution finished. Exported Show-ModuleLoaderSummary." -Channel Verbose -Condition $global:DebugProfile
