<#
.SYNOPSIS
    Automates the git commit workflow with configurable options.
.DESCRIPTION
    - Runs `git status`
    - Adds all changes (or a pattern if `-Add <pattern>` is provided)
    - Runs `git status` again
    - Asks for confirmation unless `--Force` is used
    - Prompts for a commit message (defaults to date/time/user if empty)
    - Runs `git pull` and `git push`
.PARAMETER Add
    A file pattern to add instead of adding everything.
.PARAMETER Force
    Skips the confirmation prompt.
.EXAMPLE
    ./AutoGit.ps1
.EXAMPLE
    ./AutoGit.ps1 -Add "*.ps1"
.EXAMPLE
    ./AutoGit.ps1 --Force
#>

param(
    [string]$Add = ".",
    [switch]$Force
)

# Function to generate a default commit message (date/time/user)
function Get-DefaultCommitMessage {
    $user = [System.Environment]::UserName
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    return "$timestamp - $user"
}

# Run git status
Write-Debug -Message "Checking Git Status" -Channel "Information"
git status

# Run git add
Write-Debug -Message "Adding Files: $Add" -Channel "Information"
git add $Add

# Run git status again
Write-Debug -Message "Checking Git Status Again" -Channel "Information"
git status

# Confirmation step unless --Force is used
if (-not $Force) {
    $confirmation = Read-Host "Continue? (y/n)"
    if ($confirmation -ne "y") {
        Write-Debug -Message "Aborting Git Commit Process" -Channel "Error"
        exit
    }
}

# Prompt for commit message
Write-Debug -Message "Prompting for Commit Message" -Channel "Information"
$commitMessage = Read-Host "Commit Message"

if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    $commitMessage = Get-DefaultCommitMessage
    Write-Debug -Message "Using default commit message: '$commitMessage'" -Channel "Warning"
}

# Run git commit
Write-Debug -Message "Committing Changes" -Channel "Success"
git commit -m "$commitMessage"

# Run git pull
Write-Debug -Message "Pulling Latest Changes" -Channel "Information"
git pull

# Run git push
Write-Debug -Message "Pushing Changes to Remote" -Channel "Success"
git push
