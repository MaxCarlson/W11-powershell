param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$exePath,

    [string]$scriptPath = "C:\Users\YourUsername\Miniconda3\Scripts",

    [string]$binPath = "C:\Users\YourUsername\Miniconda3\Library\bin"
)

# Add to user PATHH
$oldPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
$newPath = "$oldPath;$exePath;$scriptPath;$binPath"
[System.Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')
