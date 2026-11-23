<#
.SYNOPSIS
    Installs, verifies, or rolls back a durable PowerShell bootstrap profile
    that dot-sources W11-powershell\Profiles\CustomProfile.ps1.

.DESCRIPTION
    Replaces fragile hard-link profile setups with a small permanent bootstrap
    script at the installed PowerShell profile path(s). Dry-run by default;
    pass -Apply to perform filesystem changes.

.EXAMPLE
    .\Profiles\Install-ProfileBootstrap.ps1
    # Dry-run preview of installing the bootstrap profile.

.EXAMPLE
    .\Profiles\Install-ProfileBootstrap.ps1 -Action Verify
    # Verifies whether the installed profile matches the durable bootstrap.

.EXAMPLE
    .\Profiles\Install-ProfileBootstrap.ps1 -Action Install -Apply
    # Backs up any differing installed profile and writes the bootstrap.

.EXAMPLE
    .\Profiles\Install-ProfileBootstrap.ps1 -Action Rollback -Apply
    # Restores the most recent timestamped backup from Profiles\ProfileBackup.
#>

[CmdletBinding()]
param(
    [ValidateSet('Install', 'Verify', 'Rollback')]
    [string]$Action = 'Install',

    [string[]]$ProfilePaths,

    [switch]$IncludeWindowsPowerShell,

    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent),

    [string]$BackupDir = (Join-Path $PSScriptRoot 'ProfileBackup'),

    [string]$BackupPath,

    [switch]$Apply,

    [switch]$PassThru
)

Set-StrictMode -Version Latest

$script:BootstrapMarker = '# W11-POWERSHELL DURABLE BOOTSTRAP PROFILE v1'

function Get-TargetProfilePaths {
    if ($ProfilePaths -and $ProfilePaths.Count -gt 0) {
        return @($ProfilePaths)
    }

    $paths = [System.Collections.Generic.List[string]]::new()
    $paths.Add((Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'))
    if ($IncludeWindowsPowerShell) {
        $paths.Add((Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'))
    }
    return $paths.ToArray()
}

function Get-BootstrapProfileContent {
    $lines = @(
        $script:BootstrapMarker
        '# Resolves the active W11-powershell checkout and dot-sources Profiles\CustomProfile.ps1.'
        '$script:__w11Candidates = [System.Collections.Generic.List[string]]::new()'
        'foreach ($__candidate in @('
        '    $env:PWSH_REPO,'
        "    [Environment]::GetEnvironmentVariable('PWSH_REPO', 'User'),"
        "    [Environment]::GetEnvironmentVariable('PWSH_REPO', 'Machine'),"
        "    (Join-Path `$HOME 'src\W11-powershell'),"
        "    (Join-Path `$HOME 'Repos\W11-powershell'),"
        "    'C:\Projects\W11-powershell'"
        ')) {'
        '    if (-not [string]::IsNullOrWhiteSpace($__candidate) -and -not $script:__w11Candidates.Contains($__candidate)) {'
        '        $script:__w11Candidates.Add($__candidate)'
        '    }'
        '}'
        ''
        '$script:__w11CustomProfile = $null'
        'foreach ($__repoRoot in $script:__w11Candidates) {'
        "    `$__probe = Join-Path `$__repoRoot 'Profiles\CustomProfile.ps1'"
        '    if (Test-Path -LiteralPath $__probe -PathType Leaf) {'
        '        $script:__w11CustomProfile = $__probe'
        '        break'
        '    }'
        '}'
        ''
        'if (-not $script:__w11CustomProfile) {'
        '    $__searched = $script:__w11Candidates -join ", "'
        '    Write-Error "W11-powershell CustomProfile.ps1 not found. Checked: $__searched. Set `$env:PWSH_REPO or clone W11-powershell."'
        '    return'
        '}'
        ''
        'if ($PSCommandPath -and ([System.IO.Path]::GetFullPath($script:__w11CustomProfile) -ieq [System.IO.Path]::GetFullPath($PSCommandPath))) {'
        '    Write-Error "Refusing recursive profile load: $script:__w11CustomProfile points to itself."'
        '    return'
        '}'
        ''
        '. $script:__w11CustomProfile'
    )
    return ($lines -join "`r`n") + "`r`n"
}

function New-TimestampedBackupPath {
    param(
        [Parameter(Mandatory)][string]$TargetPath,
        [Parameter(Mandatory)][string]$Directory
    )

    $leaf = Split-Path -Path $TargetPath -Leaf
    $stamp = (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')
    return (Join-Path $Directory "$stamp-$leaf")
}

function Find-LatestBackup {
    param(
        [Parameter(Mandatory)][string]$TargetPath,
        [Parameter(Mandatory)][string]$Directory
    )

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        return $null
    }
    $leaf = Split-Path -Path $TargetPath -Leaf
    return (Get-ChildItem -LiteralPath $Directory -Filter "*-$leaf" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1)
}

$expectedContent = Get-BootstrapProfileContent
$expectedNorm = $expectedContent.Replace("`r`n", "`n").TrimEnd()
$utf8BomEncoding = New-Object System.Text.UTF8Encoding($true)
$targets = Get-TargetProfilePaths
$results = [System.Collections.Generic.List[pscustomobject]]::new()
$verifyFailed = $false

foreach ($targetPath in $targets) {
    $exists = Test-Path -LiteralPath $targetPath -PathType Leaf
    $currentNorm = if ($exists) {
        (Get-Content -LiteralPath $targetPath -Raw -Encoding UTF8).Replace("`r`n", "`n").TrimEnd()
    } else {
        $null
    }
    $isBootstrap = $exists -and ($currentNorm -eq $expectedNorm)

    if ($Action -eq 'Verify') {
        $repoCustom = Join-Path $RepoRoot 'Profiles\CustomProfile.ps1'
        $repoExists = Test-Path -LiteralPath $repoCustom -PathType Leaf
        $status = if (-not $exists) {
            'Missing'
        } elseif ($isBootstrap -and $repoExists) {
            'ValidBootstrap'
        } elseif ($isBootstrap) {
            'BootstrapMissingRepoProfile'
        } else {
            'StaleOrCustom'
        }
        if ($status -ne 'ValidBootstrap') {
            $verifyFailed = $true
        }
        Write-Host ("[{0}] {1}" -f $status, $targetPath)
        $results.Add([pscustomobject]@{
            Action      = 'Verify'
            ProfilePath = $targetPath
            Status      = $status
            Applied     = $false
            BackupPath  = $null
        })
        continue
    }

    if ($Action -eq 'Install') {
        if ($isBootstrap) {
            Write-Host "[OK] Already up-to-date bootstrap: $targetPath" -ForegroundColor Green
            $results.Add([pscustomobject]@{
                Action      = 'Install'
                ProfilePath = $targetPath
                Status      = 'AlreadyInstalled'
                Applied     = $false
                BackupPath  = $null
            })
            continue
        }

        $plannedBackup = if ($exists) { New-TimestampedBackupPath -TargetPath $targetPath -Directory $BackupDir } else { $null }
        if (-not $Apply) {
            Write-Host "[DRY-RUN] Would install durable bootstrap at: $targetPath" -ForegroundColor Yellow
            if ($plannedBackup) {
                Write-Host "[DRY-RUN] Would back up existing profile to: $plannedBackup" -ForegroundColor Yellow
            }
            $results.Add([pscustomobject]@{
                Action      = 'Install'
                ProfilePath = $targetPath
                Status      = 'DryRun'
                Applied     = $false
                BackupPath  = $plannedBackup
            })
            continue
        }

        $parentDir = Split-Path -Path $targetPath -Parent
        if (-not (Test-Path -LiteralPath $parentDir -PathType Container)) {
            $null = New-Item -Path $parentDir -ItemType Directory -Force
        }
        if ($exists) {
            if (-not (Test-Path -LiteralPath $BackupDir -PathType Container)) {
                $null = New-Item -Path $BackupDir -ItemType Directory -Force
            }
            Copy-Item -LiteralPath $targetPath -Destination $plannedBackup -Force
            Write-Host "[BACKUP] Saved existing profile to: $plannedBackup" -ForegroundColor Cyan
        }

        [System.IO.File]::WriteAllText($targetPath, $expectedContent, $utf8BomEncoding)
        Write-Host "[INSTALLED] Durable bootstrap written to: $targetPath" -ForegroundColor Green
        $results.Add([pscustomobject]@{
            Action      = 'Install'
            ProfilePath = $targetPath
            Status      = 'Installed'
            Applied     = $true
            BackupPath  = $plannedBackup
        })
        continue
    }

    if ($Action -eq 'Rollback') {
        $sourceBackup = if ($BackupPath) {
            if (Test-Path -LiteralPath $BackupPath -PathType Leaf) { Get-Item -LiteralPath $BackupPath } else { $null }
        } else {
            Find-LatestBackup -TargetPath $targetPath -Directory $BackupDir
        }

        if (-not $sourceBackup) {
            Write-Error "No backup found to restore for: $targetPath"
            $verifyFailed = $true
            $results.Add([pscustomobject]@{
                Action      = 'Rollback'
                ProfilePath = $targetPath
                Status      = 'NoBackupFound'
                Applied     = $false
                BackupPath  = $null
            })
            continue
        }

        if (-not $Apply) {
            Write-Host "[DRY-RUN] Would restore '$($sourceBackup.FullName)' -> '$targetPath'" -ForegroundColor Yellow
            $results.Add([pscustomobject]@{
                Action      = 'Rollback'
                ProfilePath = $targetPath
                Status      = 'DryRun'
                Applied     = $false
                BackupPath  = $sourceBackup.FullName
            })
            continue
        }

        $parentDir = Split-Path -Path $targetPath -Parent
        if (-not (Test-Path -LiteralPath $parentDir -PathType Container)) {
            $null = New-Item -Path $parentDir -ItemType Directory -Force
        }
        Copy-Item -LiteralPath $sourceBackup.FullName -Destination $targetPath -Force
        Write-Host "[ROLLED BACK] Restored '$($sourceBackup.FullName)' -> '$targetPath'" -ForegroundColor Green
        $results.Add([pscustomobject]@{
            Action      = 'Rollback'
            ProfilePath = $targetPath
            Status      = 'RolledBack'
            Applied     = $true
            BackupPath  = $sourceBackup.FullName
        })
    }
}

if ($PassThru) {
    $results.ToArray()
}

if ($verifyFailed) {
    exit 1
}
