# Ensure $PWSH_REPO is already set
if (-not $PWSH_REPO) {
    Write-Output "❌ Error: PWSH_REPO is not set. Aborting." 
    exit 1
}

# Define all global variables in the current session BEFORE writing them to the file
$global:PWSH_SCRIPT_DIR = Join-Path $PWSH_REPO "Scripts"
$global:PWSH_BIN_DIR = Join-Path $PWSH_REPO "bin"
$global:PWSH_PROFILE_PATH = Join-Path $PWSH_REPO "Profiles"
$global:PWSH_MODULES_PATH = Join-Path $PWSH_REPO "Config\Modules"

# Now that the variables are defined, write them to the dynamic file
$GlobalVariables = @"
# 🚀 Dynamically Generated Global Variables
# This file is automatically overwritten by CreateAndSetGlobalVariables.ps1

`$global:PWSH_REPO = '$PWSH_REPO'
`$global:PWSH_SCRIPT_DIR = '$PWSH_SCRIPT_DIR'
`$global:PWSH_BIN_DIR = '$PWSH_BIN_DIR'
`$global:PWSH_PROFILE_PATH = '$PWSH_PROFILE_PATH'
`$global:PWSH_MODULES_PATH = '$PWSH_MODULES_PATH'
"@

# Write the dynamic variables file (overwrite existing file)
Set-Content -Path $DynamicVariablesFile -Value $GlobalVariables -Force

# Print confirmation messages
Write-Output "✅ Created/Updated: $DynamicVariablesFile"
Write-Output "🔹 PWSH_REPO set to: $PWSH_REPO"
Write-Output "🔹 PWSH_SCRIPT_DIR set to: $PWSH_SCRIPT_DIR"
Write-Output "🔹 PWSH_BIN_DIR set to: $PWSH_BIN_DIR"
Write-Output "🔹 PWSH_PROFILE_PATH set to: $PWSH_PROFILE_PATH"
Write-Output "🔹 PWSH_MODULES_PATH set to: $PWSH_MODULES_PATH"

