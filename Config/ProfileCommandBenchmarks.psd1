@{
    SchemaVersion = 1
    Commands = @(
        # Navigation changes location only inside the disposable benchmark shell.
        @{ Name = 'cdd';   Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdd';   MeasurePrompt = $true; Notes = 'Dotfiles repository' }
        @{ Name = 'cddl';  Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cddl';  MeasurePrompt = $true; Notes = 'Downloads directory' }
        @{ Name = 'cdobs'; Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdobs'; MeasurePrompt = $true; Notes = 'Obsidian vault' }
        @{ Name = 'cdsrc'; Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdsrc'; MeasurePrompt = $true; Notes = 'Repository root' }
        @{ Name = 'cds';   Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cds';   MeasurePrompt = $true; Notes = 'Scripts repository' }
        @{ Name = 'cdsm';  Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdsm';  MeasurePrompt = $true; Notes = 'Scripts modules directory' }
        @{ Name = 'cdspy'; Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdspy'; MeasurePrompt = $true; Notes = 'Scripts Python directory' }
        @{ Name = 'cdsps'; Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdsps'; MeasurePrompt = $true; Notes = 'Scripts PowerShell directory' }
        @{ Name = 'cdre';  Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdre';  MeasurePrompt = $true; Notes = 'Repository root alias' }
        @{ Name = 'cdpwsh'; Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdpwsh'; MeasurePrompt = $true; Notes = 'W11-powershell repository' }
        @{ Name = 'cdps';  Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdps';  MeasurePrompt = $true; Notes = 'W11-powershell alias' }
        @{ Name = 'cdmo';  Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdmo';  MeasurePrompt = $true; Notes = 'PowerShell modules directory' }
        @{ Name = 'cddot'; Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cddot'; MeasurePrompt = $true; Notes = 'Dotfiles repository alias' }
        @{ Name = 'cdtor'; Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdtor'; MeasurePrompt = $true; Notes = 'C drive torrents' }
        @{ Name = 'cdtord'; Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdtord'; MeasurePrompt = $true; Notes = 'D drive torrents' }
        @{ Name = 'cdpo';  Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdpo';  MeasurePrompt = $true; Notes = 'D drive pictures' }
        @{ Name = 'cdpon'; Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdpon'; MeasurePrompt = $true; Notes = 'D drive tmpvids' }
        @{ Name = 'cdpony'; Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdpony'; MeasurePrompt = $true; Notes = 'Ytaedl confinement directory' }
        @{ Name = 'cdpoi'; Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdpoi'; MeasurePrompt = $true; Notes = 'D drive pictures subdirectory' }
        @{ Name = 'cdpoh'; Module = 'CDModule'; Safety = 'Navigation'; Invocation = 'cdpoh'; MeasurePrompt = $true; Notes = 'D drive hentai images' }

        # Read-only commands. Output is discarded so the result measures work, not terminal rendering.
        @{ Name = 'ls'; Module = 'ListAliases'; Safety = 'ReadOnly'; Invocation = 'ls'; MeasurePrompt = $false; Notes = 'Eza detailed listing' }
        @{ Name = 'll'; Module = 'ListAliases'; Safety = 'ReadOnly'; Invocation = 'll'; MeasurePrompt = $false; Notes = 'Eza long listing' }
        @{ Name = 'Get-EnvironmentVariables'; Module = 'EnvironmentVariables'; Safety = 'ReadOnly'; Invocation = 'Get-EnvironmentVariables -Process'; MeasurePrompt = $false; Notes = 'Process environment' }
        @{ Name = 'Get-PathEntries'; Module = 'PathManager'; Safety = 'ReadOnly'; Invocation = 'Get-PathEntries -Scope User'; MeasurePrompt = $false; Notes = 'User PATH entries' }
        @{ Name = 'Show-PathDuplicates'; Module = 'PathManager'; Safety = 'ReadOnly'; Invocation = 'Show-PathDuplicates -Scope User'; MeasurePrompt = $false; Notes = 'User PATH duplicate scan' }
        @{ Name = 'Get-ActiveJobs'; Module = 'JobsModule'; Safety = 'ReadOnly'; Invocation = 'Get-ActiveJobs'; MeasurePrompt = $false; Notes = 'Persistent job inventory' }
        @{ Name = 'Test-ProgramInstallation'; Module = 'Installer'; Safety = 'ReadOnly'; Invocation = 'Test-ProgramInstallation -CommandName pwsh'; MeasurePrompt = $false; Notes = 'Command discovery for pwsh' }
        @{ Name = 'Test-Tmux'; Module = 'TmuxModule'; Safety = 'ReadOnly'; Invocation = 'Test-Tmux'; MeasurePrompt = $false; Notes = 'Tmux command availability' }
        @{ Name = 'Get-ClipboardContents'; Module = 'ClipboardModule'; Safety = 'ReadOnly'; Invocation = 'Get-ClipboardContents'; MeasurePrompt = $false; FailurePattern = '(?im)^\s*SyntaxError:'; Notes = 'Clipboard reader' }
        @{ Name = 'Get-UserDefinedAliases'; Module = 'UserDefinedModule'; Safety = 'ReadOnly'; Invocation = 'Get-UserDefinedAliases -Limit 20'; MeasurePrompt = $false; Notes = 'Custom alias inventory' }
    )
}
