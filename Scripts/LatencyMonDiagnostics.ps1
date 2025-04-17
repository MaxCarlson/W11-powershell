param (
    [int]$Minutes = 60,
    [string]$LogPath = "$HOME\Desktop\LatencyLogs"
)

# ========== Resolve & Create Log Directory ==========
$LogPath = (Resolve-Path -Path $LogPath -ErrorAction SilentlyContinue) ?? $LogPath
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

# ========== Prepare Timestamped Subfolder ==========
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$sessionPath = Join-Path $LogPath "Session_$timestamp"
New-Item -ItemType Directory -Force -Path $sessionPath | Out-Null

# ========== Paths ==========
$latencyMonPath = "C:\Program Files\LatencyMon\LatMon.exe"
$hwinfoPath = "C:\Program Files\HWiNFO64\HWiNFO64.EXE"

# ========== Start LatencyMon ==========
$latencyLog = Join-Path $sessionPath "latency.csv"
$latencyArgs = "-logfile `"$latencyLog`" -interval 1000 -duration 0"
Start-Process -FilePath $latencyMonPath -ArgumentList $latencyArgs -WindowStyle Minimized

# ========== Start HWiNFO64 ==========
$hwinfoArgs = "/sensors /log /minimize"
Start-Process -FilePath $hwinfoPath -ArgumentList $hwinfoArgs -WindowStyle Minimized

Write-Host "✅ Logging started. Logs in: $sessionPath"

# ========== Wait and Rotate Loop ==========
Start-Sleep -Seconds ($Minutes * 60)

# Stop looped instances (user must allow this to work automatically if needed)
# For now, script just exits — Task Scheduler should relaunch it again
Write-Host "♻️ $Minutes minutes passed. You can now rotate or restart diagnostics."

# Optional: Clean up older sessions here (e.g. keep only latest N)
# Or handle via scheduled task that runs this script every 60 mins

