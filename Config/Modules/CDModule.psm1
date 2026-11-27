if (-not $global:ModuleImportedCDModule) {
    $global:ModuleImportedCDModule = $true
} else {
    Write-Debug -Message "Attempting to import module twice!" -Channel "Error" -Condition $DebugProfile -FileAndLine
    return
}

# Directory navigation functions using dynamic paths from profile
# These paths are auto-detected in CustomProfile.ps1

# Module-local navigation roots. Keep dependent destinations derived from these
# values so a folder move normally needs one update here.
$script:HomePath = $HOME
$script:SrcRootPath = Join-Path $script:HomePath 'src'
$script:DotfilesPath = Join-Path $script:SrcRootPath 'dotfiles'
$script:DownloadsPath = Join-Path $script:HomePath 'Downloads'
$script:ObsidianVaultPath = Join-Path $script:HomePath 'Documents\Obsidian-Vault'
$script:ScriptsRepoFallbackPath = Join-Path $script:HomePath 'Repos\scripts'
$script:PowerShellRepoFallbackPath = Join-Path $script:HomePath 'Repos\W11-powershell'
$script:DotfilesRepoFallbackPath = Join-Path $script:HomePath 'dotfiles'
$script:CTorrentsPath = 'C:\Torrents'
$script:DTorrentsPath = 'D:\Torrents'
$script:PicturesSavedPath = 'D:\Pictures\Saved'
$script:B_Path = 'B:\'
$script:TmpVidsPath = Join-Path $script:PicturesSavedPath 'tmpvids'
$script:YtaedlConfinementPath = Join-Path $script:TmpVidsPath 'ytaedl_confinement'
$script:PicturesPath = Join-Path $script:PicturesSavedPath 'Pics'
$script:HentaiImagesPath = Join-Path $script:PicturesPath 'hentaiImages'

function Resolve-CdRepoRoot {
    param(
        [string]$GlobalValue,
        [string]$FallbackPath,
        [string]$WarningMessage,
        [switch]$EmitWarnings
    )

    if ($GlobalValue -and (Test-Path -LiteralPath $GlobalValue -PathType Container)) {
        return $GlobalValue
    }
    if ($EmitWarnings -and $WarningMessage) {
        Write-Warning $WarningMessage
    }
    return $FallbackPath
}

function Resolve-CdSrcRepoPath {
    param(
        [Parameter(Mandatory)][string]$RepoName
    )

    if ($global:REPOS_DIR -and (Test-Path -LiteralPath $global:REPOS_DIR -PathType Container)) {
        $candidate = Join-Path $global:REPOS_DIR $RepoName
        if (Test-Path -LiteralPath $candidate -PathType Container) {
            return $candidate
        }
    }
    return (Join-Path $script:SrcRootPath $RepoName)
}

function Resolve-CdMacroPath {
    <#
    .SYNOPSIS
    Resolves a recognized cd* navigation macro name to its target directory path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$EmitWarnings
    )

    switch ($Name.ToLowerInvariant()) {
        'cdd'    { return $script:DotfilesPath }
        'cdb'    { return $script:B_Path }
        'cdbh'   { return (Join-Path $script:B_Path 'Hent') }
        'cddl'   { return $script:DownloadsPath }
        'cdobs'  { return $script:ObsidianVaultPath }
        'cdsrc'  {
            return (Resolve-CdRepoRoot -GlobalValue $global:REPOS_DIR `
                -FallbackPath (Join-Path $script:HomePath 'Repos') `
                -WarningMessage "REPOS_DIR not found. Set `$env:SCRIPTS_REPO or `$env:PWSH_REPO" `
                -EmitWarnings:$EmitWarnings)
        }
        'cdre'   {
            return (Resolve-CdRepoRoot -GlobalValue $global:REPOS_DIR `
                -FallbackPath (Join-Path $script:HomePath 'Repos') `
                -WarningMessage "REPOS_DIR not found. Set `$env:SCRIPTS_REPO or `$env:PWSH_REPO" `
                -EmitWarnings:$EmitWarnings)
        }
        'cds'    {
            return (Resolve-CdRepoRoot -GlobalValue $global:SCRIPTS_REPO `
                -FallbackPath $script:ScriptsRepoFallbackPath `
                -WarningMessage "SCRIPTS_REPO not found. Set `$env:SCRIPTS_REPO" `
                -EmitWarnings:$EmitWarnings)
        }
        'cdsm'   {
            $root = Resolve-CdRepoRoot -GlobalValue $global:SCRIPTS_REPO -FallbackPath $script:ScriptsRepoFallbackPath
            return (Join-Path $root 'modules')
        }
        'cdspy'  {
            $root = Resolve-CdRepoRoot -GlobalValue $global:SCRIPTS_REPO -FallbackPath $script:ScriptsRepoFallbackPath
            return (Join-Path $root 'pyscripts')
        }
        'cdsps'  {
            $root = Resolve-CdRepoRoot -GlobalValue $global:SCRIPTS_REPO -FallbackPath $script:ScriptsRepoFallbackPath
            return (Join-Path $root 'pscripts')
        }
        'cdpwsh' {
            return (Resolve-CdRepoRoot -GlobalValue $global:PWSH_REPO `
                -FallbackPath $script:PowerShellRepoFallbackPath `
                -WarningMessage "PWSH_REPO not found. Set `$env:PWSH_REPO" `
                -EmitWarnings:$EmitWarnings)
        }
        'cdps'   {
            return (Resolve-CdRepoRoot -GlobalValue $global:PWSH_REPO `
                -FallbackPath $script:PowerShellRepoFallbackPath `
                -WarningMessage "PWSH_REPO not found. Set `$env:PWSH_REPO" `
                -EmitWarnings:$EmitWarnings)
        }
        'cdmo'   {
            $root = Resolve-CdRepoRoot -GlobalValue $global:PWSH_REPO -FallbackPath $script:PowerShellRepoFallbackPath
            return (Join-Path $root 'Config\Modules')
        }
        'cddot'  {
            return (Resolve-CdRepoRoot -GlobalValue $global:DOTFILES_REPO `
                -FallbackPath $script:DotfilesRepoFallbackPath `
                -WarningMessage "DOTFILES_REPO not found. Set `$env:DOTFILES_REPO" `
                -EmitWarnings:$EmitWarnings)
        }
        'cdspm'  { return (Resolve-CdSrcRepoPath -RepoName 'shared-python-modules') }
        'cdllm'  { return (Resolve-CdSrcRepoPath -RepoName 'llm-agent-toolkit') }
        'cdtor'  { return $script:CTorrentsPath }
        'cdtord' { return $script:DTorrentsPath }
        'cdpo'   { return $script:PicturesSavedPath }
        'cdpon'  { return $script:TmpVidsPath }
        'cdpony' { return $script:YtaedlConfinementPath }
        'cdpoi'  { return $script:PicturesPath }
        'cdpoh'  { return $script:HentaiImagesPath }
        default  { return $null }
    }
}

function Invoke-CdMacro {
    param([Parameter(Mandatory)][string]$Name)
    $target = Resolve-CdMacroPath -Name $Name -EmitWarnings
    if ($target) {
        Set-Location $target
    }
}

function Format-CdMacroExpansionPath {
    param([Parameter(Mandatory)][string]$Destination)

    $homeNorm = if ($HOME) { $HOME.TrimEnd('\', '/') } else { $null }
    if ($homeNorm -and ($Destination -ieq $homeNorm)) {
        $formatted = '~/'
    } elseif ($homeNorm -and (
        $Destination.StartsWith("$homeNorm\", [System.StringComparison]::OrdinalIgnoreCase) -or
        $Destination.StartsWith("$homeNorm/", [System.StringComparison]::OrdinalIgnoreCase)
    )) {
        $rel = $Destination.Substring($homeNorm.Length).TrimStart('\', '/').Replace('\', '/')
        $formatted = if ($rel) { "~/$rel/" } else { '~/' }
    } else {
        $formatted = $Destination
        if (-not $formatted.EndsWith('\') -and -not $formatted.EndsWith('/')) {
            $formatted += '\'
        }
    }

    if ($formatted -match '[\s''"`$&|;(){}\[\]<>@#]') {
        return "'" + $formatted.Replace("'", "''") + "'"
    }
    return $formatted
}

function Get-CdMacroExpansion {
    <#
    .SYNOPSIS
    Returns an editable path replacement if the cursor is at the end of a
    recognized cd* macro in command or argument position, or $null otherwise.
    #>
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$Line,
        [int]$Cursor
    )

    if ([string]::IsNullOrWhiteSpace($Line) -or $Cursor -le 0 -or $Cursor -gt $Line.Length) {
        return $null
    }

    $tokens = $null
    $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseInput($Line, [ref]$tokens, [ref]$errors)
    if (-not $tokens) { return $null }

    $memberFlag = [System.Management.Automation.Language.TokenFlags]::MemberName
    $allowedKinds = @(
        [System.Management.Automation.Language.TokenKind]::Identifier,
        [System.Management.Automation.Language.TokenKind]::Generic
    )
    $blockedPrevKinds = @(
        [System.Management.Automation.Language.TokenKind]::Dot,
        [System.Management.Automation.Language.TokenKind]::ColonColon
    )

    $targetToken = $null
    $prevToken = $null
    foreach ($tok in $tokens) {
        if ($tok.Kind -eq [System.Management.Automation.Language.TokenKind]::EndOfInput) { continue }
        if ($tok.Extent.EndOffset -eq $Cursor) {
            if (($tok.Kind -in $allowedKinds) -and
                -not ($tok.TokenFlags -band $memberFlag) -and
                (-not $prevToken -or ($prevToken.Kind -notin $blockedPrevKinds))) {
                $targetToken = $tok
            }
            break
        }
        $prevToken = $tok
    }

    if (-not $targetToken) { return $null }

    $destination = Resolve-CdMacroPath -Name $targetToken.Text
    if (-not $destination) { return $null }

    $replacement = Format-CdMacroExpansionPath -Destination $destination
    return [pscustomobject]@{
        Macro       = $targetToken.Text
        Destination = $destination
        StartOffset = $targetToken.Extent.StartOffset
        Length      = ($targetToken.Extent.EndOffset - $targetToken.Extent.StartOffset)
        Replacement = $replacement
    }
}

# Standard Windows directories
function cdd    { Invoke-CdMacro 'cdd' }
function cdb    { Invoke-CdMacro 'cdb' }
function cdbh   { Invoke-CdMacro 'cdbh' }
function cddl   { Invoke-CdMacro 'cddl' }
function cdobs  { Invoke-CdMacro 'cdobs' }

# Repository directories (dynamically detected)
function cdsrc  { Invoke-CdMacro 'cdsrc' }
function cds    { Invoke-CdMacro 'cds' }
function cdsm   { Invoke-CdMacro 'cdsm' }
function cdspy  { Invoke-CdMacro 'cdspy' }
function cdsps  { Invoke-CdMacro 'cdsps' }
function cdre   { Invoke-CdMacro 'cdre' }
function cdpwsh { Invoke-CdMacro 'cdpwsh' }
function cdps   { Invoke-CdMacro 'cdps' }
function cdmo   { Invoke-CdMacro 'cdmo' }
function cddot  { Invoke-CdMacro 'cddot' }
function cdspm  { Invoke-CdMacro 'cdspm' }
function cdllm  { Invoke-CdMacro 'cdllm' }
function cdtor  { Invoke-CdMacro 'cdtor' }
function cdtord { Invoke-CdMacro 'cdtord' }
function cdpo   { Invoke-CdMacro 'cdpo' }
function cdpon  { Invoke-CdMacro 'cdpon' }
function cdpony { Invoke-CdMacro 'cdpony' }
function cdpoi  { Invoke-CdMacro 'cdpoi' }
function cdpoh  { Invoke-CdMacro 'cdpoh' }

# Setting Aliases, lots of UNIX aliases have been converted to powershell here
# Functions for changing directories
$originalSetLocation = Get-Command Set-Location -CommandType Cmdlet

# zoxide version

# Initialize zoxide if installed
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    # Initialize zoxide to create the z command
    if (-not (Get-Command z -ErrorAction SilentlyContinue)) {
        try {
            Invoke-Expression (& zoxide init powershell | Out-String)
        } catch {
            Write-Warning "Failed to initialize zoxide: $_"
        }
    }
} else {
    Write-Warning "zoxide not found. Install it with: winget install ajeetdsouza.zoxide"
}

# Check if z command is available after initialization
if (-not (Get-Command z -ErrorAction SilentlyContinue)) {
    Write-Warning "zoxide (z command) not available. CDModule will work with limited functionality."
    # Don't return - allow module to load with other functions
}
