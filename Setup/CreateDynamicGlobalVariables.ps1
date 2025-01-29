param (
    [string]$RepoPath
)

# Use the passed-in repo path, or fallback if not provided
$global:PWSH_REPO = if ($RepoPath) { $RepoPath } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

# Define dynamic profile path correctly inside the repo root
$DynamicProfileDir = Join-Path -Path (Split-Path -Path $PWSH_REPO -Parent) -ChildPath "dynamic/start_profile"
$DynamicVariablesFile = Join-Path -Path $DynamicProfileDir -ChildPath "dynamic_global_variables.ps1"

# Ensure the dynamic profile directory exists
if (!(Test-Path $DynamicProfileDir)) {
    Write-Output "🔹 Creating missing directory: $DynamicProfileDir"
    New-Item -ItemType Directory -Path $DynamicProfileDir -Force | Out-Null
}

# Define all global variables
$GlobalVariables = @"
# 🚀 Dynamically Generated Global Variables
# This file is automatically overwritten by CreateAndSetGlobalVariables.ps1

`$global:PWSH_REPO = '$PWSH_REPO'
`$global:PWSH_SCRIPT_DIR = '`$PWSH_REPO\Scripts'
`$global:PWSH_BIN_DIR = '`$PWSH_REPO\bin'
"@

# Write the dynamic variables file (overwrite existing file)
Set-Content -Path $DynamicVariablesFile -Value $GlobalVariables -Force

# Confirmation Output
Write-Output "✅ Created/Updated: $DynamicVariablesFile"
Write-Output "🔹 PWSH_REPO set to: $PWSH_REPO"
Write-Output "🔹 PWSH_SCRIPT_DIR set to: $PWSH_SCRIPT_DIR"
Write-Output "🔹 PWSH_BIN_DIR set to: $PWSH_BIN_DIR"

