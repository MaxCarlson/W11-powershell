<#
.SYNOPSIS
    Automates the git commit workflow with configurable options.
.DESCRIPTION
    - Runs `git status`
    - Adds all changes (or a pattern if `-Add <pattern>` is provided)
    - Displays added files
    - Allows skipping the commit (`s` option)
    - Prompts for a commit message only if files are staged
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
$gitStatus = git status --short

if ([string]::IsNullOrWhiteSpace($gitStatus)) {
    Write-Debug -Message "No changes detected. Running git pull..." -Channel "Success"
    git pull
    exit
}

Write-Debug -Message "Current Changes:" -Channel "Information"
Write-Debug -Message "`n$gitStatus`n" -Channel "Information"

# Run git add
Write-Debug -Message "Adding Files: $Add" -Channel "Information"
git add $Add

# Show staged changes
Write-Debug -Message "Checking Staged Files" -Channel "Information"
$stagedFiles = git diff --cached --name-status

if ([string]::IsNullOrWhiteSpace($stagedFiles)) {
    Write-Debug -Message "No files were staged. Skipping commit." -Channel "Warning"
    Write-Debug -Message "Proceeding to git pull." -Channel "Information"
    git pull
    exit
}

Write-Debug -Message "Staged Files:`n$stagedFiles`n" -Channel "Information"

# Confirmation step unless --Force is used
if (-not $Force) {
    $confirmation = Read-Host "Continue? (y/n/s) (s = Skip commit, but continue with git pull)"
    if ($confirmation -eq "n") {
        Write-Debug -Message "Aborting Git Process" -Channel "Error"
        exit
    } elseif ($confirmation -eq "s") {
        Write-Debug -Message "Skipping commit, proceeding to git pull." -Channel "Information"
        git pull
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

# Check if there are new commits before pushing
$newCommits = git log --branches --not --remotes --oneline
if ([string]::IsNullOrWhiteSpace($newCommits)) {
    Write-Debug -Message "No new commits to push. Process complete." -Channel "Success"
} else {
    Write-Debug -Message "Pushing Changes to Remote" -Channel "Success"
    git push
}
