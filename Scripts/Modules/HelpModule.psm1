# Get-UserHelp.psm1
<#
.SYNOPSIS
Provides help information for user-defined modules and scripts.

.DESCRIPTION
Displays categorized help information for modules, scripts, and executables in the environment.

.PARAMETER Category
The category of help to retrieve (e.g., Modules, Scripts).

.PARAMETER Name
(Optional) The specific name of the module or script to get help for.

.EXAMPLE
Get-UserHelp -Category Modules
#>
function Get-UserHelp {
    param (
        [string]$Category = "Modules",
        [string]$Name,
        [string]$Filter
    )

    # Base directories for modules and scripts
    $modulesPath = "C:\Users\mcarls\Repos\W11-powershell\Scripts\Modules"
    $scriptsPath = "C:\Path\To\Scripts"

    switch ($Category.ToLower()) {
        "modules" {
            if ($Name) {
                # Display detailed help for a specific module
                $modulePath = Join-Path -Path $modulesPath -ChildPath "$Name.psm1"
                if (-not (Test-Path $modulePath)) {
                    Write-Host "Module '$Name' not found." -ForegroundColor Red
                    return
                }
                Write-Host "Help for Module: $Name" -ForegroundColor Cyan
                Import-Module $modulePath -Force | Out-Null
                Get-Command -Module $Name | ForEach-Object {
                    Write-Host "Function: $($_.Name)" -ForegroundColor Green
                    Write-Host "Help:"
                    Get-Help $_.Name | Select-Object -ExpandProperty Synopsis
                    Write-Host ""
                }
            } else {
                # List all user-defined modules
                Write-Host "Available Modules:" -ForegroundColor Cyan
                Get-ChildItem -Path $modulesPath -Filter "*.psm1" | ForEach-Object {
                    $moduleName = $_.BaseName
                    Write-Host "- $moduleName"
                }
            }
        }
        "scripts" {
            # Filter scripts by extension if provided
            $filter = if ($Filter) { "*.$Filter" } else { "*" }
            Write-Host "Available Scripts ($filter):" -ForegroundColor Cyan
            Get-ChildItem -Path $scriptsPath -Filter $filter | ForEach-Object {
                Write-Host "- $($_.Name)"
            }
        }
        "executables" {
            # List executables in the PATH
            Write-Host "Executables in PATH:" -ForegroundColor Cyan
            $env:Path -split ";" | ForEach-Object {
                if (Test-Path $_) {
                    Get-ChildItem -Path $_ -Filter "*.exe" | ForEach-Object {
                        Write-Host "- $($_.Name)"
                    }
                }
            }
        }
        default {
            Write-Host "Invalid category. Available categories: Modules, Scripts, Executables." -ForegroundColor Red
        }
    }
}

Export-ModuleMember -Function Get-UserHelp
