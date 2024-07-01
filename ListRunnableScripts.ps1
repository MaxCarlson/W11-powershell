# ListRunnableScripts.ps1
param (
    [string]$rootDir = "C:\Projects\W11-powershell\"
)

# Function to recursively get all scripts
function Get-RunnableScripts {
    param (
        [string]$path
    )
    Get-ChildItem -Path $path -Recurse -Include *.ps1, *.bat | ForEach-Object {
        $_.FullName
    }
}

# Get all runnable scripts from the root directory
$scripts = Get-RunnableScripts -path $rootDir

# Output the list of scripts
$scripts
