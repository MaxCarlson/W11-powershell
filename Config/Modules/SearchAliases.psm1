if (-not $global:ModuleImportedSearchAliases) {
    $global:ModuleImportedSearchAliases = $true
} else {
    Write-Debug -Message "Attempting to import module twice!" -Channel "Error" -Condition $DebugProfile -FileAndLine
    return
}

# `fd` Functions
function fdn { fd --type f @Args }                      # Search for regular files
function fdd { fd --type d @Args }                      # Search for directories
function fdx { fd --hidden --no-ignore @Args }          # Include hidden files and ignore .gitignore
function fde { fd --extension exe @Args }               # Search for executables
function fdpy { fd --extension py @Args }               # Search for Python files
function fdmd { fd --extension md @Args }               # Search for Markdown files
function fdjson { fd --extension json @Args }           # Search for JSON files
function fdlog { fd --extension log @Args }             # Search for log files
function fdr { fd --regex @Args }                       # Search with regex
function fdgit { fd --hidden --exclude ".git" @Args }   # Exclude .git directories
function fdc { fd --changed-within @Args }              # Files changed within a specific time frame
function fdtree { fd --tree @Args }                     # Display results in a tree format

# `rg` Functions
function rgn { rg --files @Args }                       # List all files
function rgh { rg --hidden @Args }                      # Search hidden files
function rgx { rg --no-ignore @Args }                   # Search ignoring .gitignore rules
function rgl { rg --line-number @Args }                 # Search with line numbers
function rgc { rg --count @Args }                       # Show match counts
function rgw { rg --word-regexp @Args }                 # Match whole words only
function rgs { rg --smart-case @Args }                  # Smart case search
function rgv { rg --invert-match @Args }                # Invert match (exclude matches)
function rgjson { rg --glob '*.json' @Args }            # Search JSON files
function rgpy { rg --glob '*.py' @Args }                # Search Python files
function rglog { rg --glob '*.log' @Args }              # Search log files
function rgmd { rg --glob '*.md' @Args }                # Search Markdown files
function rgp { rg --context 3 @Args }                   # Show 3 lines of context
function rgp5 { rg --context 5 @Args }                  # Show 5 lines of context
function rgcsharp { rg --glob '*.cs' @Args }            # Search C# files
function rge { rg --regexp @Args }                      # Regex-based search


function agf {
    param([string]$SearchTerm)
    Get-Command -CommandType Function | ForEach-Object {
        $name = $_.Name
        $definition = $_.Definition
        $shortDef = if ($definition.Length -gt 50) { $definition.Substring(0, 50) + "..." } else { $definition }
        "${name}: ${shortDef}"
    } | Select-String -Pattern $SearchTerm
}

$FunctionHelp = @{
    fdn = "Search for regular files. Arguments are passed to fd directly."
    fdd = "Search for directories. Arguments are passed to fd directly."
    fdx = "Search hidden files, ignoring .gitignore rules."
    fde = "Search for executables (.exe files)."
    fdpy = "Search for Python files (.py)."
    fdmd = "Search for Markdown files (.md)."
    fdjson = "Search for JSON files (.json)."
    fdlog = "Search for log files (.log)."
    fdr = "Search using a custom regex pattern."
    fdgit = "Search excluding .git directories."
    fdc = "Search files changed within a specific time frame."
    fdtree = "Display search results in a tree format."

    rgn = "List all files in the current directory."
    rgh = "Search hidden files."
    rgx = "Search ignoring .gitignore rules."
    rgl = "Search with line numbers."
    rgc = "Show match counts for each file."
    rgw = "Match whole words only."
    rgs = "Smart case-sensitive search."
    rgv = "Invert match (exclude matches)."
    rgjson = "Search JSON files (.json)."
    rgpy = "Search Python files (.py)."
    rglog = "Search log files (.log)."
    rgmd = "Search Markdown files (.md)."
    rgp = "Show 3 lines of context for matches."
    rgp5 = "Show 5 lines of context for matches."
    rgcsharp = "Search C# files (.cs)."
    rge = "Search using a regex pattern."
}

function agfh {
    param([string]$SearchTerm)
    $FunctionHelp.GetEnumerator() | Where-Object {
        $_.Key -match $SearchTerm -or $_.Value -match $SearchTerm
    } | ForEach-Object {
        "$($_.Key): $($_.Value)"
    }
}

