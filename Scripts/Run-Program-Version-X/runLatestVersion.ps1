# run-program-latest-version.ps1

param (
    [Parameter(Mandatory = $true, Position = 0)]
    [Alias("b")]
    [string]$ProgramBase,

    [Parameter(Mandatory = $true, Position = 1)]
    [Alias("e")]
    [string]$ExecutableName
)

function Get-LatestVersionPath {
    param (
        [string]$ProgramBase
    )

    if (-Not (Test-Path -Path $ProgramBase)) {
        Write-Error "Program base path not found: $ProgramBase"
        exit 1
    }

    $versionDirectories = Get-ChildItem -Path $ProgramBase -Directory | Sort-Object Name -Descending
    if ($versionDirectories.Count -eq 0) {
        Write-Error "No version directories found in: $ProgramBase"
        exit 1
    }

    return $versionDirectories[0].FullName
}

function Run-Program {
    param (
        [string]$ProgramPath,
        [string]$ExecutableName
    )

    $executablePath = Join-Path -Path $ProgramPath -ChildPath $ExecutableName
    if (-Not (Test-Path -Path $executablePath)) {
        Write-Error "Executable not found: $executablePath"
        exit 1
    }

    & $executablePath
}

# Main script execution
$latestVersionPath = Get-LatestVersionPath -ProgramBase $ProgramBase
Run-Program -ProgramPath $latestVersionPath -ExecutableName $ExecutableName
