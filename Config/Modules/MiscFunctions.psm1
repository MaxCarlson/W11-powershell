# Miscellaneous functions
#
#
# 
#
#


function Update-AllPackages {
    param (
        [switch]$ForceAdminRestart
    )

    # Check if running as administrator
    function Test-Admin {
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    # Restart as admin if needed
    if (-not (Test-Admin)) {
        Write-Host "Restarting PowerShell as administrator..."
        if ($ForceAdminRestart) {
            Start-Process -FilePath "pwsh.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
            exit
        } else {
            Write-Host "Skipping admin-required updates. Running non-admin updates only."
        }
    }

    # Run package updates
    Write-Host "Updating winget packages..." -ForegroundColor Cyan
    winget upgrade --all --silent --accept-source-agreements --accept-package-agreements

    Write-Host "Updating Chocolatey packages..." -ForegroundColor Cyan
    choco upgrade all -y

    Write-Host "Updating Scoop packages..." -ForegroundColor Cyan
    scoop update

    Write-Host "Updating Conda packages..." -ForegroundColor Cyan
    conda update --all --yes

    Write-Host "Updating pip packages..." -ForegroundColor Cyan
    pip list --outdated --format=freeze | ForEach-Object { ($_ -split '=')[0] } | ForEach-Object { pip install --upgrade $_ }

    Write-Host "All package updates completed." -ForegroundColor Green
}
# Aliases for Update-AllPackages
Set-Alias ua Update-AllPackages
Set-Alias myupdate Update-AllPackages

function GitMan {
    param ($Subcommand)
    git help -m $Subcommand | groff -T ascii -man | more
}

Set-Alias gitman GitMan

# Winget setup for small devices
function swinget {
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    winget @Arguments | Format-Table -Wrap -AutoSize
}


# Sudo Simulation
function _ { Start-Process powershell -Verb runAs -ArgumentList ($args -join ' ') }

# ag searches for aliases whose commands match the pattern
Remove-Item Alias:ag -ErrorAction SilentlyContinue
Remove-Item Function:ag -ErrorAction SilentlyContinue

function aliasGrepFunction {
    param(
        [string]$Pattern
    )
    Get-Alias | Where-Object { $_.Definition -match $Pattern -or $_.Name -match $Pattern } | Format-Table -Property Name, Definition
}

Set-Alias -Name ag -Value aliasGrepFunction 

# grep implementation for powershell
function grepFunction {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$InputObject
    )
    process {
        $InputObject | Select-String -Pattern $Pattern
    }
}

Set-Alias -Name grep -Value grepFunction
