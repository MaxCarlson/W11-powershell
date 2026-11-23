Import-Module Pester -ErrorAction Stop

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$nativeGlobPath = Join-Path $repoRoot 'Config\Modules\NativeGlob.psm1'
$listAliasesPath = Join-Path $repoRoot 'Config\Modules\ListAliases.psm1'
$cdModulePath = Join-Path $repoRoot 'Config\Modules\CDModule.psm1'
$psReadLineModulePath = Join-Path $repoRoot 'Config\Modules\PSReadLine.psm1'

Describe 'ListAliases and NativeGlob Directory Argument Handling' {
    BeforeAll {
        Import-Module $nativeGlobPath -Force
        Import-Module $listAliasesPath -Force

        $script:TestRoot = Join-Path $env:TEMP ("w11pwsh_eza_test_" + [guid]::NewGuid().ToString('N'))
        $null = New-Item -Path $script:TestRoot -ItemType Directory -Force
        $null = New-Item -Path (Join-Path $script:TestRoot 'dir1') -ItemType Directory -Force
        $null = New-Item -Path (Join-Path $script:TestRoot 'dir1\nested') -ItemType Directory -Force
        $null = New-Item -Path (Join-Path $script:TestRoot 'dir2') -ItemType Directory -Force
        $null = New-Item -Path (Join-Path $script:TestRoot 'directory with spaces') -ItemType Directory -Force
        $null = New-Item -Path (Join-Path $script:TestRoot 'dir with [brackets]') -ItemType Directory -Force

        Set-Content -LiteralPath (Join-Path $script:TestRoot 'alpha.py') -Value '# py'
        Set-Content -LiteralPath (Join-Path $script:TestRoot 'dir1\inside1.txt') -Value 'one'
        Set-Content -LiteralPath (Join-Path $script:TestRoot 'dir1\nested\deep.txt') -Value 'deep'
        Set-Content -LiteralPath (Join-Path $script:TestRoot 'dir2\inside2.txt') -Value 'two'
        Set-Content -LiteralPath (Join-Path $script:TestRoot 'directory with spaces\spaced.txt') -Value 'sp'
        Set-Content -LiteralPath (Join-Path $script:TestRoot 'dir with [brackets]\bracketed.txt') -Value 'br'

        Push-Location $script:TestRoot
    }

    AfterAll {
        Pop-Location -ErrorAction SilentlyContinue
        if ($script:TestRoot -and (Test-Path -LiteralPath $script:TestRoot)) {
            Remove-Item -LiteralPath $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'lists current directory with ll and ll .' {
        $out1 = (ll) | Out-String
        $LASTEXITCODE | Should Be 0
        $out1 | Should Match 'alpha\.py'

        $out2 = (ll .) | Out-String
        $LASTEXITCODE | Should Be 0
        $out2 | Should Match 'alpha\.py'
    }

    It 'lists dir1/ and .\dir1 without blank output' {
        $outSlash = (ll dir1/) | Out-String
        $LASTEXITCODE | Should Be 0
        $outSlash | Should Match 'inside1\.txt'

        $outBackslash = (ll .\dir1) | Out-String
        $LASTEXITCODE | Should Be 0
        $outBackslash | Should Match 'inside1\.txt'
    }

    It 'lists absolute paths, spaces, and bracketed directory names' {
        $absDir = Join-Path $script:TestRoot 'dir2'
        $outAbs = (ll $absDir) | Out-String
        $LASTEXITCODE | Should Be 0
        $outAbs | Should Match 'inside2\.txt'

        $outSpace = (ll 'directory with spaces') | Out-String
        $LASTEXITCODE | Should Be 0
        $outSpace | Should Match 'spaced\.txt'

        $outBracket = (ll 'dir with [brackets]') | Out-String
        $LASTEXITCODE | Should Be 0
        $outBracket | Should Match 'bracketed\.txt'
    }

    It 'expands globs, supports flags with paths, multiple directories, and --help' {
        $outGlob = (ll *.py) | Out-String
        $LASTEXITCODE | Should Be 0
        $outGlob | Should Match 'alpha\.py'

        $outMulti = (ll --reverse dir1/ dir2/) | Out-String
        $LASTEXITCODE | Should Be 0
        $outMulti | Should Match 'inside1\.txt'
        $outMulti | Should Match 'inside2\.txt'

        $outHelp = (ll --help) | Out-String
        $LASTEXITCODE | Should Be 0
        $outHelp | Should Match 'Usage:'
    }

    It 'works for l1, l2, l3, and lt2 with directory arguments' {
        foreach ($fn in @('l1', 'l2', 'l3', 'lt2')) {
            $out = (& $fn 'dir1/') | Out-String
            $LASTEXITCODE | Should Be 0
            $out | Should Match 'inside1\.txt'
        }
    }

    It 'fails visibly and does not list CWD for nonexistent paths or unmatched globs' {
        $all1 = @(ll nonexistent-directory 2>&1)
        $LASTEXITCODE | Should Not Be 0
        $err1 = @($all1 | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })
        $out1 = ($all1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }) | Out-String
        $err1.Count | Should BeGreaterThan 0
        $out1 | Should Not Match 'alpha\.py'

        $all2 = @(ll *.no_such_ext_xyz 2>&1)
        $LASTEXITCODE | Should Not Be 0
        $err2 = @($all2 | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })
        $out2 = ($all2 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }) | Out-String
        $err2.Count | Should BeGreaterThan 0
        $out2 | Should Not Match 'alpha\.py'
    }

    It 'uses WinGet fallback eza executable for both no-arg and arg paths when eza is absent from PATH' {
        $origPath = $env:PATH
        try {
            $env:PATH = "$env:SystemRoot\System32"
            Import-Module $listAliasesPath -Force
            $out = (ll dir1/) | Out-String
            $LASTEXITCODE | Should Be 0
            $out | Should Match 'inside1\.txt'
        } finally {
            $env:PATH = $origPath
            Import-Module $listAliasesPath -Force
        }
    }
}

Describe 'CDModule Location Macros and Tab Expansion' {
    BeforeAll {
        $global:ModuleImportedCDModule = $false
        $global:PWSH_REPO = $repoRoot
        $global:SCRIPTS_REPO = Join-Path $HOME 'src\scripts'
        $global:DOTFILES_REPO = Join-Path $HOME 'src\dotfiles'
        $global:REPOS_DIR = Join-Path $HOME 'src'
        Import-Module $cdModulePath -Force
    }

    It 'resolves cdsh and cdlmt to existing repositories under ~/src' {
        $sh = Resolve-CdMacroPath -Name 'cdsh'
        $sh | Should Be (Join-Path $HOME 'src\shared-python-modules')
        (Test-Path -LiteralPath $sh -PathType Container) | Should Be $true

        $lmt = Resolve-CdMacroPath -Name 'cdlmt'
        $lmt | Should Be (Join-Path $HOME 'src\llm-agent-toolkit')
        (Test-Path -LiteralPath $lmt -PathType Container) | Should Be $true
    }

    It 'resolves all expected cd* location macros' {
        $expected = @{
            cdd    = Join-Path $HOME 'src\dotfiles'
            cdb    = 'B:\'
            cdbh   = 'B:\Hent'
            cddl   = Join-Path $HOME 'Downloads'
            cdobs  = Join-Path $HOME 'Documents\Obsidian-Vault'
            cdsrc  = Join-Path $HOME 'src'
            cdre   = Join-Path $HOME 'src'
            cds    = Join-Path $HOME 'src\scripts'
            cdsm   = Join-Path $HOME 'src\scripts\modules'
            cdspy  = Join-Path $HOME 'src\scripts\pyscripts'
            cdsps  = Join-Path $HOME 'src\scripts\pscripts'
            cdpwsh = $repoRoot
            cdps   = $repoRoot
            cdmo   = Join-Path $repoRoot 'Config\Modules'
            cddot  = Join-Path $HOME 'src\dotfiles'
            cdsh   = Join-Path $HOME 'src\shared-python-modules'
            cdlmt  = Join-Path $HOME 'src\llm-agent-toolkit'
            cdtor  = 'C:\Torrents'
            cdtord = 'D:\Torrents'
            cdpo   = 'D:\Pictures\Saved'
            cdpon  = 'D:\Pictures\Saved\tmpvids'
            cdpony = 'D:\Pictures\Saved\tmpvids\ytaedl_confinement'
            cdpoi  = 'D:\Pictures\Saved\Pics'
            cdpoh  = 'D:\Pictures\Saved\Pics\hentaiImages'
        }

        foreach ($name in $expected.Keys) {
            Resolve-CdMacroPath -Name $name | Should Be $expected[$name]
        }
    }

    It 'expands recognized macros in command and argument positions to portable paths without cd prefix' {
        $exp1 = Get-CdMacroExpansion -Line 'cds' -Cursor 3
        $exp1 | Should Not BeNullOrEmpty
        $exp1.StartOffset | Should Be 0
        $exp1.Length | Should Be 3
        $exp1.Replacement | Should Be '~/src/scripts/'

        $exp2 = Get-CdMacroExpansion -Line '  cdsh' -Cursor 6
        $exp2 | Should Not BeNullOrEmpty
        $exp2.StartOffset | Should Be 2
        $exp2.Length | Should Be 4
        $exp2.Replacement | Should Be '~/src/shared-python-modules/'

        $exp3 = Get-CdMacroExpansion -Line 'cdlmt' -Cursor 5
        $exp3 | Should Not BeNullOrEmpty
        $exp3.Replacement | Should Be '~/src/llm-agent-toolkit/'

        $exp4 = Get-CdMacroExpansion -Line 'cd cds' -Cursor 6
        $exp4 | Should Not BeNullOrEmpty
        $exp4.StartOffset | Should Be 3
        $exp4.Length | Should Be 3
        $exp4.Replacement | Should Be '~/src/scripts/'

        $exp5 = Get-CdMacroExpansion -Line 'll cds' -Cursor 6
        $exp5 | Should Not BeNullOrEmpty
        $exp5.StartOffset | Should Be 3
        $exp5.Length | Should Be 3
        $exp5.Replacement | Should Be '~/src/scripts/'

        $exp6 = Get-CdMacroExpansion -Line 'git status; cdlmt' -Cursor 17
        $exp6 | Should Not BeNullOrEmpty
        $exp6.StartOffset | Should Be 12
        $exp6.Length | Should Be 5
        $exp6.Replacement | Should Be '~/src/llm-agent-toolkit/'

        $exp7 = Get-CdMacroExpansion -Line 'cdtor' -Cursor 5
        $exp7 | Should Not BeNullOrEmpty
        $exp7.Replacement | Should Be 'C:\Torrents\'

        (Get-CdMacroExpansion -Line 'echo "cds' -Cursor 9) | Should BeNullOrEmpty
        (Get-CdMacroExpansion -Line "echo 'cds" -Cursor 9) | Should BeNullOrEmpty
        (Get-CdMacroExpansion -Line 'echo $cds' -Cursor 9) | Should BeNullOrEmpty
        (Get-CdMacroExpansion -Line '$a.cds' -Cursor 6) | Should BeNullOrEmpty
        (Get-CdMacroExpansion -Line 'echo -cds' -Cursor 9) | Should BeNullOrEmpty
        (Get-CdMacroExpansion -Line 'cds ' -Cursor 4) | Should BeNullOrEmpty
        (Get-CdMacroExpansion -Line 'unknown' -Cursor 7) | Should BeNullOrEmpty
    }

    It 'escapes single quotes and spaces in expanded paths' {
        $origScripts = $global:SCRIPTS_REPO
        $tempQuoteDir = Join-Path $env:TEMP "O'Brien's dir"
        $null = New-Item -Path $tempQuoteDir -ItemType Directory -Force
        try {
            $global:SCRIPTS_REPO = $tempQuoteDir
            $exp = Get-CdMacroExpansion -Line 'll cds' -Cursor 6
            $exp | Should Not BeNullOrEmpty
            $exp.Replacement | Should Be "'~/AppData/Local/Temp/O''Brien''s dir/'"
        } finally {
            $global:SCRIPTS_REPO = $origScripts
            Remove-Item -LiteralPath $tempQuoteDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'navigates directly when cdsh and cdlmt are invoked' {
        Push-Location $repoRoot
        try {
            cdsh
            (Get-Location).Path | Should Be (Join-Path $HOME 'src\shared-python-modules')

            cdlmt
            (Get-Location).Path | Should Be (Join-Path $HOME 'src\llm-agent-toolkit')
        } finally {
            Pop-Location
        }
    }
}

Describe 'PSReadLine Tab Keybinding Integration' {
    It 'registers Tab handler without breaking repeated imports' {
        if (-not (Get-Module -ListAvailable PSReadLine)) {
            Set-ItResult -Skipped -Because 'PSReadLine module is not installed'
            return
        }

        Import-Module PSReadLine -ErrorAction SilentlyContinue
        Import-Module $psReadLineModulePath -Force
        Import-Module $psReadLineModulePath

        $tabHandler = Get-PSReadLineKeyHandler -Key Tab -ErrorAction SilentlyContinue | Select-Object -First 1
        $tabHandler | Should Not BeNullOrEmpty
        $tabHandler.Description | Should Match 'Expand cd\* location macros'
    }
}
