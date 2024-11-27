param (
    [string]$Path = (Get-Location).Path
)

function Remove-DeadLinks {
    param (
        [string]$Path = (Get-Location).Path
    )

    # Ensure the path exists
    if (-not (Test-Path $Path)) {
        Write-Color -Message "The specified path does not exist: $Path" -Type "Error"
        return
    }

    Write-Color -Message "Scanning for dead symlinks and hard links in: $Path" -Type "Processing"
    $count = 0
    # Recursively get all files and directories
    Get-ChildItem -Path $Path -Recurse -Force | ForEach-Object {
        $item = $_

        # Check if it's a symlink
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            # Test the symlink target
            $targetPath = (Get-Item $item.FullName).Target
            if (-not (Test-Path $targetPath)) {
                Write-Color -Message "Removing dead symlink: $($item.FullName)" -Type "Warning"
                Remove-Item -Path $item.FullName -Force
                $count += 1
            }
        } else {
            # Check if it's a hard link (File only, not folders)
            if (-not (Test-Path $item.FullName)) {
                Write-Color -Message "Removing dead hard link: $($item.FullName)" -Type "Critical"
                Remove-Item -Path $item.FullName -Force
            }
        }
    }

    if ($count -lt 1) {
        Write-Color -Message "No dead links found" -Type "Info"
    }

    Write-Color -Message "Cleanup complete." -Type "Success"
}

# Call the function with the specified or default path
Remove-DeadLinks -Path $Path

