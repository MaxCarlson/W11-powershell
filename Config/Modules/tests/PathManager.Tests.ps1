<#
.SYNOPSIS
    Comprehensive Pester tests for PathManager.psm1 with debug prints.

.DESCRIPTION
    - Prints registry-based PATH contents before/after backup, restore, removing duplicates, adding new entries.
    - Confirms that backups match the registry.
    - Ensures that restore sets PATH to the same exact strings from the backup.
    - Demonstrates removing duplicates, adding entries without duplication, etc.

.NOTES
    Requires: Pester 3.x
    Author: YourName
#>

Import-Module Pester -ErrorAction Stop

# Adjust to your environment
Import-Module "$PSScriptRoot\..\PathManager.psm1" -Force

Describe "PathManager Module Tests" {

    BeforeAll {
        # Save real env variables
        $RealUserPath    = [Environment]::GetEnvironmentVariable('Path','User')
        $RealMachinePath = [Environment]::GetEnvironmentVariable('Path','Machine')

        # Use small test data for consistent results
        [Environment]::SetEnvironmentVariable('Path','C:\Test1;C:\Test2','User')
        [Environment]::SetEnvironmentVariable('Path','C:\SysTest1;C:\SysTest2','Machine')
    }

    AfterAll {
        # Restore real env variables
        [Environment]::SetEnvironmentVariable('Path',$RealUserPath,'User')
        [Environment]::SetEnvironmentVariable('Path',$RealMachinePath,'Machine')
    }

    It "Get-PathEntries returns user path" {
        # Print user path from registry before test
        $currentUserPath = [Environment]::GetEnvironmentVariable('Path','User')
        Write-Host "`n[DEBUG] Current USER PATH: $currentUserPath"

        $userEntries = Get-PathEntries -Scope User
        Write-Host "[DEBUG] userEntries array: $($userEntries -join ';')"

        ($userEntries -contains 'C:\Test1') | Should Be $true
        ($userEntries -contains 'C:\Test2') | Should Be $true
    }

    It "Get-PathEntries returns machine path" {
        # Print machine path from registry before test
        $currentMachinePath = [Environment]::GetEnvironmentVariable('Path','Machine')
        Write-Host "`n[DEBUG] Current MACHINE PATH: $currentMachinePath"

        $machineEntries = Get-PathEntries -Scope Machine
        Write-Host "[DEBUG] machineEntries array: $($machineEntries -join ';')"

        ($machineEntries -contains 'C:\SysTest1') | Should Be $true
        ($machineEntries -contains 'C:\SysTest2') | Should Be $true
    }

    It "Backed-up JSON should match the actual registry PATH (Both scope)" {
        $testBackup = Join-Path $env:TEMP "PathBackup-Test.json"
        if (Test-Path $testBackup) { Remove-Item $testBackup }

        # Show what's in the registry right now
        $beforeUser    = [Environment]::GetEnvironmentVariable('Path','User')
        $beforeMachine = [Environment]::GetEnvironmentVariable('Path','Machine')
        Write-Host "`n[DEBUG] USER PATH before backup: $beforeUser"
        Write-Host "[DEBUG] MACHINE PATH before backup: $beforeMachine"

        # Backup user+machine
        Backup-Paths -Scope Both -BackupPath $testBackup

        # Print the JSON we just saved
        Write-Host "[DEBUG] Backup JSON contents (Both scope):"
        Get-Content $testBackup | Write-Host

        # Now parse the JSON
        $backupJson = Get-Content $testBackup -Raw
        $backupObj  = $backupJson | ConvertFrom-Json

        # Compare exactly
        ($backupObj.UserPath -eq $beforeUser)       | Should Be $true
        ($backupObj.MachinePath -eq $beforeMachine) | Should Be $true
    }

    It "Restoring from backup sets path to the same exact string" {
        $testBackup = Join-Path $env:TEMP "PathBackup-Test.json"
        if (-not (Test-Path $testBackup)) {
            # Create it if missing
            Backup-Paths -Scope Both -BackupPath $testBackup
        }

        # Show user+machine PATH before we modify
        $origUser    = [Environment]::GetEnvironmentVariable('Path','User')
        $origMachine = [Environment]::GetEnvironmentVariable('Path','Machine')
        Write-Host "`n[DEBUG] USER PATH before modification: $origUser"
        Write-Host "[DEBUG] MACHINE PATH before modification: $origMachine"

        # Modify
        [Environment]::SetEnvironmentVariable('Path','C:\ModifiedUser','User')
        [Environment]::SetEnvironmentVariable('Path','C:\ModifiedSys','Machine')

        $modifiedUser    = [Environment]::GetEnvironmentVariable('Path','User')
        $modifiedMachine = [Environment]::GetEnvironmentVariable('Path','Machine')
        Write-Host "[DEBUG] USER PATH after modification: $modifiedUser"
        Write-Host "[DEBUG] MACHINE PATH after modification: $modifiedMachine"

        # Restore from backup
        Restore-Paths -Scope Both -BackupFile $testBackup

        # Show user+machine PATH after restore
        $restoredUser    = [Environment]::GetEnvironmentVariable('Path','User')
        $restoredMachine = [Environment]::GetEnvironmentVariable('Path','Machine')
        Write-Host "[DEBUG] USER PATH after restore: $restoredUser"
        Write-Host "[DEBUG] MACHINE PATH after restore: $restoredMachine"

        # Compare with the backup JSON
        $backupJson = Get-Content $testBackup -Raw
        $backupObj  = $backupJson | ConvertFrom-Json

        ($restoredUser -eq $backupObj.UserPath)       | Should Be $true
        ($restoredMachine -eq $backupObj.MachinePath) | Should Be $true
    }

    It "Remove-PathDuplicates removes duplicates in user path" {
        # Force duplicates
        [Environment]::SetEnvironmentVariable('Path','C:\Test1;C:\Test2;C:\Test1','User')
        $beforeRemoving = [Environment]::GetEnvironmentVariable('Path','User')
        Write-Host "`n[DEBUG] USER PATH before removing duplicates: $beforeRemoving"

        Remove-PathDuplicates -Scope User | Out-Null

        $afterRemoving = [Environment]::GetEnvironmentVariable('Path','User')
        Write-Host "[DEBUG] USER PATH after removing duplicates: $afterRemoving"

        $finalUser = Get-PathEntries -Scope User
        ($finalUser | Where-Object { $_ -eq 'C:\Test1' }).Count | Should Be 1
    }

    It "Add-PathEntry doesn't duplicate existing entries and can add new path" {
        Write-Host "`n[DEBUG] USER PATH before add attempts: $([Environment]::GetEnvironmentVariable('Path','User'))"

        # 1) Should not add duplicates
        Add-PathEntry -Scope User -NewEntry 'C:\Test2' | Out-Null
        $pathAfterDupCheck = [Environment]::GetEnvironmentVariable('Path','User')
        Write-Host "[DEBUG] USER PATH after trying to add 'C:\Test2': $pathAfterDupCheck"

        $finalUser = Get-PathEntries -Scope User
        ($finalUser | Where-Object { $_ -eq 'C:\Test2' }).Count | Should Be 1

        # 2) Add a new entry
        Add-PathEntry -Scope User -NewEntry 'C:\NewTools' | Out-Null
        $pathAfterNewEntry = [Environment]::GetEnvironmentVariable('Path','User')
        Write-Host "[DEBUG] USER PATH after adding 'C:\NewTools': $pathAfterNewEntry"

        $finalUser = Get-PathEntries -Scope User
        ($finalUser -contains 'C:\NewTools') | Should Be $true
    }
}
