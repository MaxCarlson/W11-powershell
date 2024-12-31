function Get-ModulesHelp {
    param (
        [string]$ModulesPath,
        [string]$SubIndex
    )

    # Step 1: Retrieve the list of modules
    $moduleFiles = Get-ChildItem -Path $ModulesPath -Filter "*.psm1" | Sort-Object Name

    if (-not $SubIndex) {
        # If no module is selected, list all available modules
        Write-Host "Available Modules:" -ForegroundColor Cyan
        $index = 1
        foreach ($module in $moduleFiles) {
            Write-Host "$index. $($module.BaseName)"
            $index++
        }
        return
    }

    # Step 2: Validate SubIndex and select the specified module
    $subIndexInt = [int]$SubIndex
    if ($subIndexInt -gt 0 -and $subIndexInt -le $moduleFiles.Count) {
        $selectedModule = $moduleFiles[$subIndexInt - 1]
        Write-Host "Help for Module: $($selectedModule.BaseName)" -ForegroundColor Cyan

        # Import the module to ensure its functions are accessible
        Import-Module $selectedModule.FullName -Force | Out-Null

        # Retrieve all functions from the module
        $commands = Get-Command -Module $selectedModule.BaseName -CommandType Function
        if ($commands.Count -eq 0) {
            Write-Host "No functions found in this module." -ForegroundColor Yellow
            return
        }

        # Step 3: Loop through each function in the module and display detailed help
        foreach ($command in $commands) {
            Write-Host "`nFunction: $($command.Name)" -ForegroundColor Green
            Write-Host "Help:" -ForegroundColor Cyan

            # Get full help for the function, capturing output as a string
            $helpOutput = Get-Help $command.Name -Full | Out-String

            # Output the entire help information
            Write-Host $helpOutput
            Write-Host "`n" #Spacer
        }

    } else {
        Write-Host "Invalid module number. Please choose a valid entry from the list." -ForegroundColor Red
    }
}

function Get-ScriptsHelp {
    param (
        [string]$ScriptsPath,
        [string]$SubIndex,
        [string]$Filter
    )

    $filter = if ($Filter) { "*.$Filter" } else { "*" }
    $scriptFiles = Get-ChildItem -Path $ScriptsPath -Filter $filter | Sort-Object Name
    if (-not $SubIndex) {
        Write-Host "Available Scripts ($filter):" -ForegroundColor Cyan
        $index = 1
        foreach ($script in $scriptFiles) {
            Write-Host "$index. $($script.Name)"
            $index++
        }
    } else {
        $subIndexInt = [int]$SubIndex
        if ($subIndexInt -le $scriptFiles.Count -and $subIndexInt -ge 1) {
            $selectedScript = $scriptFiles[$subIndexInt - 1]
            Write-Host "Help for Script: $($selectedScript.Name)" -ForegroundColor Cyan
            Write-Host (Get-Help $selectedScript.FullName | Out-String)
        } else {
            Write-Host "Invalid script number. Please choose a valid entry from the list." -ForegroundColor Red
        }
    }
}

function Get-ExecutablesHelp {
    param (
        [string]$SubIndex
    )

    $pathExecutables = $env:Path -split ";" | ForEach-Object {
        if (Test-Path $_) {
            Get-ChildItem -Path $_ -Filter "*.exe"
        }
    } | Sort-Object Name

    if (-not $SubIndex) {
        Write-Host "Executables in PATH:" -ForegroundColor Cyan
        $index = 1
        foreach ($exe in $pathExecutables) {
            Write-Host "$index. $($exe.Name)"
            $index++
        }
    } else {
        $subIndexInt = [int]$SubIndex
        if ($subIndexInt -le $pathExecutables.Count -and $subIndexInt -ge 1) {
            $selectedExe = $pathExecutables[$subIndexInt - 1]
            Write-Host "Details for Executable: $($selectedExe.Name)" -ForegroundColor Cyan
            Write-Host "Path: $($selectedExe.FullName)" -ForegroundColor Yellow
        } else {
            Write-Host "Invalid executable number. Please choose a valid entry from the list." -ForegroundColor Red
        }
    }
}

<#
.SYNOPSIS
Provides help information for user-defined modules, scripts, and executables.

.DESCRIPTION
Lists categorized help information for modules, scripts, and executables. Users can navigate categories and entries by number to access detailed information.

.PARAMETER Category
The category to retrieve help for (e.g., "Modules", "Scripts", "Executables"). Categories are also numbered for convenience.

.PARAMETER Name
(Optional) The specific name of the module, script, or executable to get help for.

.PARAMETER Filter
(Optional) For scripts, filters by file extension (e.g., ".ps1" or ".py").

.EXAMPLE
Get-UserHelp
Lists all available categories.

.EXAMPLE
Get-UserHelp 1
Lists all entries in the "Modules" category.

.EXAMPLE
Get-UserHelp 1 3
Displays detailed help for the third module in the "Modules" category.

.EXAMPLE
Get-UserHelp 2 -Filter ps1
Lists all PowerShell scripts.
#>
function Get-UserHelp {
    param (
        [string]$Category,
        [string]$SubIndex,
        [string]$Filter
    )

    # Define the categories and their numbers
    $categories = @{
        "1" = "Modules"
        "2" = "Scripts"
        "3" = "Executables"
    }

    # Base directories for modules and scripts
    $modulesPath = "C:\Users\mcarls\Repos\W11-powershell\Scripts\Modules"
    $scriptsPath = "C:\Path\To\Scripts"

    # If no category is provided, list all available categories
    if (-not $Category) {
        Write-Host "Available Categories:" -ForegroundColor Cyan
        foreach ($key in $categories.Keys | Sort-Object) {
            Write-Host "$key. $($categories[$key])"
        }
        return
    }

    # Allow category to be specified by number
    if ($categories.ContainsKey($Category)) {
        $Category = $categories[$Category]
    } else {
        Write-Host "Invalid category. Use the following:" -ForegroundColor Red
        foreach ($key in $categories.Keys | Sort-Object) {
            Write-Host "$key. $($categories[$key])"
        }
        return
    }

    switch ($Category.ToLower()) {
        "modules" {
            Get-ModulesHelp -ModulesPath $modulesPath -SubIndex $SubIndex
        }
        "scripts" {
            Get-ScriptsHelp -ScriptsPath $scriptsPath -SubIndex $SubIndex -Filter $Filter
        }
        "executables" {
            Get-ExecutablesHelp -SubIndex $SubIndex
        }
        default {
            Write-Host "Invalid category. Use the following:" -ForegroundColor Red
            foreach ($key in $categories.Keys | Sort-Object) {
                Write-Host "$key. $($categories[$key])"
            }
        }
    }
}

Export-ModuleMember -Function Get-UserHelp, Get-ModulesHelp, Get-ScriptsHelp, Get-ExecutablesHelp
