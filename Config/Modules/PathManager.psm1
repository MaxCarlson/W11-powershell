# PathManager.psm1
# ---------------------------------------------------------------------------
# A PowerShell module for safely inspecting, backing up, restoring,
# and modifying PATH environment variables for User or Machine scope.
# Includes functionality to remove duplicates and add new entries.
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    A module to manage User and Machine PATH variables safely.

.DESCRIPTION
    Provides functions to:
      - Get PATH entries (User, Machine, or Both)
      - Backup PATH (to JSON)
      - Restore PATH from a JSON backup
      - Show and remove duplicates
      - Add a new entry to PATH
    Each modifying function prompts for a backup first if the user chooses.

.NOTES
    Author: YourName
    Module Version: 2.1
    Requires: PowerShell 5.1+ or PowerShell 7+
#>

# ---------------------------------------
# Get-PathEntries
# ---------------------------------------
function Get-PathEntries {
<#
.SYNOPSIS
    Retrieves PATH entries for the specified scope.

.DESCRIPTION
    Returns an array of strings (each PATH segment). If Scope='Both',
    returns an object with .User and .Machine arrays.

.PARAMETER Scope
    'User'    - Returns the current user's PATH entries.
    'Machine' - Returns the system-wide PATH entries.
    'Both'    - Returns a PSObject with two properties: .User and .Machine arrays.

.EXAMPLE
    PS C:\> Get-PathEntries -Scope User

    Returns the current user PATH entries as an array.

.EXAMPLE
    PS C:\> Get-PathEntries -Scope Both

    Returns an object containing the user and machine PATH arrays.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('User','Machine','Both')]
        [string]
        $Scope = 'User'
    )

    switch ($Scope) {
        'User' {
            $raw = [Environment]::GetEnvironmentVariable('Path','User')
            if (-not $raw) { return @() }
            return ($raw -split ';' | ForEach-Object{ $_.Trim() } | Where-Object{ $_ })
        }
        'Machine' {
            $raw = [Environment]::GetEnvironmentVariable('Path','Machine')
            if (-not $raw) { return @() }
            return ($raw -split ';' | ForEach-Object{ $_.Trim() } | Where-Object{ $_ })
        }
        'Both' {
            $uRaw = [Environment]::GetEnvironmentVariable('Path','User')
            $mRaw = [Environment]::GetEnvironmentVariable('Path','Machine')

            $uList = if ($uRaw) { $uRaw -split ';' | ForEach-Object{ $_.Trim() } | Where-Object{ $_ } } else { @() }
            $mList = if ($mRaw) { $mRaw -split ';' | ForEach-Object{ $_.Trim() } | Where-Object{ $_ } } else { @() }

            # Return an object with two properties
            return [pscustomobject]@{
                User    = $uList
                Machine = $mList
            }
        }
    }
}

# ---------------------------------------
# Set-PathEntries
# ---------------------------------------
function Set-PathEntries {
<#
.SYNOPSIS
    Overwrites the PATH environment variable with the specified entries.

.DESCRIPTION
    Joins the provided string array with semicolons, then sets the environment
    variable for either 'User' or 'Machine' scope. This is a complete overwrite.

.PARAMETER Entries
    An array of path strings (no deduping or validation here).

.PARAMETER Scope
    'User' or 'Machine'. (Both is not allowed because we must set them separately.)

.EXAMPLE
    PS C:\> $arr = @("C:\MyTools","C:\AnotherPath")
    PS C:\> Set-PathEntries -Entries $arr -Scope User
#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $Entries,

        [Parameter(Mandatory=$true)]
        [ValidateSet('User','Machine')]
        [string]
        $Scope
    )

    $newPath = ($Entries | ForEach-Object { $_.Trim() }) -join ';'
    if ($PSCmdlet.ShouldProcess("$Scope PATH", "Overwrite PATH with $newPath")) {
        [Environment]::SetEnvironmentVariable('Path', $newPath, $Scope)
    }
}

# ---------------------------------------
# Backup-Paths
# ---------------------------------------
function Backup-Paths {
<#
.SYNOPSIS
    Backs up PATH variables (User, Machine, or Both) to a JSON file.

.DESCRIPTION
    Reads the PATH from the requested scope(s) and saves them in JSON format.
    The default backup file is a timestamped file in $HOME, but you can override
    with -BackupPath.

.PARAMETER Scope
    'User', 'Machine', or 'Both'. If Both, includes both in the JSON.

.PARAMETER BackupPath
    The file path to which JSON is saved. If omitted, a default is used.

.EXAMPLE
    PS C:\> Backup-Paths -Scope Both

    Creates a JSON file with the user & machine PATH in your home directory.

.EXAMPLE
    PS C:\> Backup-Paths -Scope User -BackupPath "D:\Backups\MyUserPath.json"
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('User','Machine','Both')]
        [string]
        $Scope = 'User',

        [Parameter(Mandatory=$false)]
        [string]
        $BackupPath
    )

    # Grab raw strings
    $userPath    = [Environment]::GetEnvironmentVariable('Path','User')
    $machinePath = [Environment]::GetEnvironmentVariable('Path','Machine')

    $backupObj = [ordered]@{
        Date         = (Get-Date).ToString("u")
        BackupScopes = $Scope
    }
    if ($Scope -in @('User','Both')) {
        $backupObj.UserPath = $userPath
    }
    if ($Scope -in @('Machine','Both')) {
        $backupObj.MachinePath = $machinePath
    }

    $json = $backupObj | ConvertTo-Json -Depth 5

    if (-not $BackupPath) {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
        $defaultFileName = "PathBackup-$Scope-$timestamp.json"
        $BackupPath = Join-Path $HOME $defaultFileName
    }

    try {
        $json | Out-File -FilePath $BackupPath -Encoding UTF8
        Write-Host "PATH backup saved to: $BackupPath" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to backup PATH to $BackupPath. Error: $_"
    }
}

# ---------------------------------------
# Restore-Paths
# ---------------------------------------
function Restore-Paths {
<#
.SYNOPSIS
    Restores PATH environment variables from a JSON backup.

.DESCRIPTION
    Reads the backup file, which must have been created by Backup-Paths,
    and overwrites the PATH environment variables for User, Machine, or Both.

.PARAMETER Scope
    'User', 'Machine', or 'Both'. Specifies which part(s) of the JSON to restore.

.PARAMETER BackupFile
    The JSON file path containing the backup.

.EXAMPLE
    PS C:\> Restore-Paths -Scope User -BackupFile "C:\PathBackup-User-2025-04-02_12-00-00.json"
#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('User','Machine','Both')]
        [string]
        $Scope,

        [Parameter(Mandatory=$true)]
        [string]
        $BackupFile
    )

    if (-not (Test-Path $BackupFile)) {
        Write-Error "Backup file not found: $BackupFile"
        return
    }

    $rawJson = Get-Content $BackupFile -Raw
    try {
        $backupObj = $rawJson | ConvertFrom-Json
    }
    catch {
        Write-Error "Failed to parse JSON from $BackupFile. Error: $_"
        return
    }

    if ($Scope -in @('User','Both')) {
        if ($backupObj.UserPath) {
            if ($PSCmdlet.ShouldProcess("User PATH", "Restore from $BackupFile")) {
                [Environment]::SetEnvironmentVariable('Path', $backupObj.UserPath, 'User')
                Write-Host "User PATH restored from $BackupFile" -ForegroundColor Green
            }
        } else {
            Write-Warning "No 'UserPath' found in $BackupFile. Skipping User restore."
        }
    }

    if ($Scope -in @('Machine','Both')) {
        if ($backupObj.MachinePath) {
            if ($PSCmdlet.ShouldProcess("Machine PATH", "Restore from $BackupFile")) {
                [Environment]::SetEnvironmentVariable('Path', $backupObj.MachinePath, 'Machine')
                Write-Host "Machine PATH restored from $BackupFile" -ForegroundColor Green
            }
        } else {
            Write-Warning "No 'MachinePath' found in $BackupFile. Skipping Machine restore."
        }
    }
}

# ---------------------------------------
# Show-PathDuplicates
# ---------------------------------------
function Show-PathDuplicates {
<#
.SYNOPSIS
    Displays duplicate PATH entries.

.DESCRIPTION
    Checks all entries in the specified scope(s). If scope='Both', prints
    duplicates for user PATH and machine PATH separately.

.PARAMETER Scope
    'User', 'Machine', or 'Both'.

.EXAMPLE
    PS C:\> Show-PathDuplicates -Scope Both

    Prints duplicates in user PATH, then duplicates in machine PATH.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('User','Machine','Both')]
        [string]
        $Scope = 'User'
    )

    $entries = Get-PathEntries -Scope $Scope

    if ($Scope -eq 'Both') {
        $uDupes = $entries.User | Group-Object | Where-Object { $_.Count -gt 1 } | Sort-Object Count -Descending
        if ($uDupes) {
            Write-Host "Duplicate User PATH entries:" -ForegroundColor Cyan
            $uDupes | ForEach-Object { Write-Host ("{0} x {1}" -f $_.Count, $_.Name) }
        }
        else {
            Write-Host "No duplicates in User PATH." -ForegroundColor Green
        }

        $mDupes = $entries.Machine | Group-Object | Where-Object { $_.Count -gt 1 } | Sort-Object Count -Descending
        if ($mDupes) {
            Write-Host "`nDuplicate Machine PATH entries:" -ForegroundColor Cyan
            $mDupes | ForEach-Object { Write-Host ("{0} x {1}" -f $_.Count, $_.Name) }
        }
        else {
            Write-Host "No duplicates in Machine PATH." -ForegroundColor Green
        }
        return
    }
    else {
        if (-not $entries) {
            Write-Host "No PATH entries found for [$Scope]." -ForegroundColor Yellow
            return
        }
        $grouped = $entries | Group-Object
        $duplicates = $grouped | Where-Object { $_.Count -gt 1 } | Sort-Object Count -Descending

        if ($duplicates) {
            Write-Host "Duplicate PATH entries for $Scope scope:" -ForegroundColor Cyan
            $duplicates | ForEach-Object {
                Write-Host ("{0} x {1}" -f $_.Count, $_.Name)
            }
        }
        else {
            Write-Host "No duplicates in $Scope PATH." -ForegroundColor Green
        }
    }
}

# ---------------------------------------
# Remove-PathDuplicates
# ---------------------------------------
function Remove-PathDuplicates {
<#
.SYNOPSIS
    Removes duplicate entries from the specified PATH scope(s).

.DESCRIPTION
    For each scope specified, deduplicates by preserving the first occurrence.
    Automatically prompts if you wish to back up first.

.PARAMETER Scope
    'User', 'Machine', or 'Both'.

.EXAMPLE
    PS C:\> Remove-PathDuplicates -Scope Both
#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('User','Machine','Both')]
        [string]
        $Scope = 'User'
    )

    $reply = Read-Host "Would you like to back up the [$Scope] PATH(s) before removing duplicates? (y/n)"
    if ($reply -match '^(y|yes)$') {
        Backup-Paths -Scope $Scope
    }

    switch ($Scope) {
        'User' {
            $entries = Get-PathEntries -Scope 'User'
            if (-not $entries) {
                Write-Host "No PATH entries for User. Exiting." -ForegroundColor Yellow
                return
            }
            $unique = New-Object System.Collections.Generic.List[string]
            foreach ($e in $entries) {
                if (-not $unique.Contains($e)) { [void]$unique.Add($e) }
            }
            if ($PSCmdlet.ShouldProcess("User PATH", "Remove duplicates")) {
                Set-PathEntries -Entries $unique -Scope 'User'
                Write-Host "Duplicates removed from User PATH." -ForegroundColor Green
            }
        }

        'Machine' {
            $entries = Get-PathEntries -Scope 'Machine'
            if (-not $entries) {
                Write-Host "No PATH entries for Machine. Exiting." -ForegroundColor Yellow
                return
            }
            $unique = New-Object System.Collections.Generic.List[string]
            foreach ($e in $entries) {
                if (-not $unique.Contains($e)) { [void]$unique.Add($e) }
            }
            if ($PSCmdlet.ShouldProcess("Machine PATH", "Remove duplicates")) {
                Set-PathEntries -Entries $unique -Scope 'Machine'
                Write-Host "Duplicates removed from Machine PATH." -ForegroundColor Green
            }
        }

        'Both' {
            # User
            $uEntries = Get-PathEntries -Scope 'User'
            if ($uEntries) {
                $uUnique = New-Object System.Collections.Generic.List[string]
                foreach ($u in $uEntries) {
                    if (-not $uUnique.Contains($u)) { [void]$uUnique.Add($u) }
                }
                if ($PSCmdlet.ShouldProcess("User PATH", "Remove duplicates")) {
                    Set-PathEntries -Entries $uUnique -Scope 'User'
                    Write-Host "Duplicates removed from User PATH." -ForegroundColor Green
                }
            }

            # Machine
            $mEntries = Get-PathEntries -Scope 'Machine'
            if ($mEntries) {
                $mUnique = New-Object System.Collections.Generic.List[string]
                foreach ($m in $mEntries) {
                    if (-not $mUnique.Contains($m)) { [void]$mUnique.Add($m) }
                }
                if ($PSCmdlet.ShouldProcess("Machine PATH", "Remove duplicates")) {
                    Set-PathEntries -Entries $mUnique -Scope 'Machine'
                    Write-Host "Duplicates removed from Machine PATH." -ForegroundColor Green
                }
            }
        }
    }
}

# ---------------------------------------
# Add-PathEntry
# ---------------------------------------
function Add-PathEntry {
<#
.SYNOPSIS
    Adds a path entry if not already present.

.DESCRIPTION
    Prompts for a backup, checks if the entry is present, and if not,
    appends it to the PATH for User, Machine, or Both. If Both, tries user first, then machine.

.PARAMETER NewEntry
    The path string to add.

.PARAMETER Scope
    'User', 'Machine', or 'Both'.

.EXAMPLE
    PS C:\> Add-PathEntry -NewEntry "C:\MyNewTools" -Scope Both
#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $NewEntry,

        [Parameter(Mandatory=$false)]
        [ValidateSet('User','Machine','Both')]
        [string]
        $Scope = 'User'
    )

    $reply = Read-Host "Would you like to back up the [$Scope] PATH(s) before adding '$NewEntry'? (y/n)"
    if ($reply -match '^(y|yes)$') {
        Backup-Paths -Scope $Scope
    }

    $NewEntry = $NewEntry.Trim()
    if (-not (Test-Path $NewEntry)) {
        Write-Warning "Directory '$NewEntry' does not exist. Proceeding anyway..."
    }

    switch ($Scope) {
        'User' {
            $entries = Get-PathEntries -Scope 'User'
            if ($entries -contains $NewEntry) {
                Write-Host "Path '$NewEntry' is already in User PATH. No action taken." -ForegroundColor Yellow
                return
            }
            $updated = $entries + $NewEntry
            if ($PSCmdlet.ShouldProcess("User PATH", "Add '$NewEntry'")) {
                Set-PathEntries -Entries $updated -Scope 'User'
                Write-Host "Path '$NewEntry' added to User PATH." -ForegroundColor Green
            }
        }

        'Machine' {
            $entries = Get-PathEntries -Scope 'Machine'
            if ($entries -contains $NewEntry) {
                Write-Host "Path '$NewEntry' is already in Machine PATH. No action taken." -ForegroundColor Yellow
                return
            }
            $updated = $entries + $NewEntry
            if ($PSCmdlet.ShouldProcess("Machine PATH", "Add '$NewEntry'")) {
                Set-PathEntries -Entries $updated -Scope 'Machine'
                Write-Host "Path '$NewEntry' added to Machine PATH." -ForegroundColor Green
            }
        }

        'Both' {
            # User scope
            $uEntries = Get-PathEntries -Scope 'User'
            if (-not ($uEntries -contains $NewEntry)) {
                $uUpdated = $uEntries + $NewEntry
                if ($PSCmdlet.ShouldProcess("User PATH", "Add '$NewEntry'")) {
                    Set-PathEntries -Entries $uUpdated -Scope 'User'
                    Write-Host "Path '$NewEntry' added to User PATH." -ForegroundColor Green
                }
            } else {
                Write-Host "Path '$NewEntry' is already in User PATH. Skipping user scope." -ForegroundColor Yellow
            }

            # Machine scope
            $mEntries = Get-PathEntries -Scope 'Machine'
            if (-not ($mEntries -contains $NewEntry)) {
                $mUpdated = $mEntries + $NewEntry
                if ($PSCmdlet.ShouldProcess("Machine PATH", "Add '$NewEntry'")) {
                    Set-PathEntries -Entries $mUpdated -Scope 'Machine'
                    Write-Host "Path '$NewEntry' added to Machine PATH." -ForegroundColor Green
                }
            } else {
                Write-Host "Path '$NewEntry' is already in Machine PATH. Skipping machine scope." -ForegroundColor Yellow
            }
        }
    }
}
