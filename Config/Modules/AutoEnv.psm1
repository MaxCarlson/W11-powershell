# AutoEnv.psm1 - Automatically activate Conda/Micromamba environments when cd'ing into directories

$global:AutoEnvMappings = @{}

function Register-AutoEnv {
    param (
        [string]$Env,
        [string[]]$Paths
    )

    if (-not $Env -or -not $Paths) {
        Write-Host "Usage: Register-AutoEnv -Env <env_name> -Paths <directory1>,<directory2> ..." -ForegroundColor Yellow
        return
    }

    foreach ($Path in $Paths) {
        $FullPath = (Resolve-Path -ErrorAction SilentlyContinue $Path)?.Path
        if ($FullPath) {
            $global:AutoEnvMappings[$FullPath] = $Env
        } else {
            Write-Host "Invalid path: $Path" -ForegroundColor Red
        }
    }

    Write-Host "Registered environment '$Env' for paths: $($Paths -join ', ')" -ForegroundColor Green
}

function Unregister-AutoEnv {
    param ([string]$Path)

    $FullPath = (Resolve-Path -ErrorAction SilentlyContinue $Path)?.Path
    if ($FullPath -and $global:AutoEnvMappings.ContainsKey($FullPath)) {
        $global:AutoEnvMappings.Remove($FullPath)
        Write-Host "Unregistered auto-env for '$FullPath'" -ForegroundColor Red
    } else {
        Write-Host "No auto-env found for '$Path'" -ForegroundColor Yellow
    }
}

function AutoActivate-CondaEnv {
    $CurrentPath = (Get-Location).Path

    if ($global:AutoEnvMappings.ContainsKey($CurrentPath)) {
        $Env = $global:AutoEnvMappings[$CurrentPath]

        # Prevent reactivating if already in the environment
        if (-not (Test-Path env:CONDA_DEFAULT_ENV) -or $env:CONDA_DEFAULT_ENV -ne $Env) {
            micromamba activate $Env
        }
    }
}

function Set-Location {
    param([string]$Path)
    Microsoft.PowerShell.Management\Set-Location $Path
    AutoActivate-CondaEnv
}

Export-ModuleMember -Function Register-AutoEnv, Unregister-AutoEnv

