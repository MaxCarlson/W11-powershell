# Profile for Current User Current Host located at $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
# To use this profile rename it to Microsoft.PowerShell_profile.ps1 and move it to the above directory
# cp ProfileCUCH.ps1 $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1

# Initialize Oh-My-Posh with the desired theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression

# PowerToys CommandNotFound module (Optional: comment out if causing issues)
# Import-Module -Name Microsoft.WinGet.CommandNotFound

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58

# Initialize fnm (Fast Node Manager) environment variables
fnm env | ForEach-Object { Invoke-Expression $_ }


# Setting Aliases, lots of UNIX aliases have been converted to powershell here
# Directory Navigation
Set-Alias -Name '-' -Value 'cd -'
Function ... { cd ../.. }
Function .... { cd ../../.. }
Function ..... { cd ../../../.. }
Function ...... { cd ../../../../.. }

# Quick Directory Navigation
Function 1 { cd -1 }
Function 2 { cd -2 }
Function 3 { cd -3 }
Function 4 { cd -4 }
Function 5 { cd -5 }
Function 6 { cd -6 }
Function 7 { cd -7 }
Function 8 { cd -8 }
Function 9 { cd -9 }

# Sudo Simulation
Function _ { Start-Process powershell -Verb runAs -ArgumentList ($args -join ' ') }

# Aliases for commands that do not conflict
Set-Alias -Name ag -Value "Get-Alias | Select-String"
Set-Alias -Name egrep -Value "Select-String"
Set-Alias -Name fgrep -Value "Select-String"

# Git Aliases with new prefixes
Set-Alias -Name g -Value git
Set-Alias -Name ga -Value "git add"
Set-Alias -Name gaa -Value "git add --all"
Set-Alias -Name gam -Value "git am"
Set-Alias -Name gama -Value "git am --abort"
Set-Alias -Name gamc -Value "git am --continue"
Set-Alias -Name gams -Value "git am --skip"
Set-Alias -Name gamscp -Value "git am --show-current-patch"
Set-Alias -Name gap -Value "git apply"
Set-Alias -Name gapa -Value "git add --patch"
Set-Alias -Name gapt -Value "git apply --3way"
Set-Alias -Name gau -Value "git add --update"
Set-Alias -Name gav -Value "git add --verbose"
Set-Alias -Name gb -Value "git branch"
Set-Alias -Name gbD -Value "git branch --delete --force"
Set-Alias -Name gba -Value "git branch --all"
Set-Alias -Name gbd -Value "git branch --delete"
Set-Alias -Name gbg -Value "git branch -vv | Select-String ': gone\]'"
Set-Alias -Name gbgD -Value "git branch -vv | Select-String ': gone\]' | ForEach-Object { git branch -D $_.Matches[0] }"
Set-Alias -Name gbgd -Value "git branch -vv | Select-String ': gone\]' | ForEach-Object { git branch -d $_.Matches[0] }"
Set-Alias -Name gbl -Value "git blame -w"
Set-Alias -Name gcmt -Value "git commit --verbose"
Set-Alias -Name 'gcmt!' -Value "git commit --verbose --amend"
Set-Alias -Name gchB -Value "git checkout -B"
Set-Alias -Name gcmtA -Value "git commit --verbose --all"
Set-Alias -Name 'gcmtA!' -Value "git commit --verbose --all --amend"
Set-Alias -Name gcmA -Value "git commit --all --message"
Set-Alias -Name 'gcmtna!' -Value "git commit --verbose --all --no-edit --amend"
Set-Alias -Name 'gcmtcn!' -Value "git commit --verbose --all --date=now --no-edit --amend"
Set-Alias -Name 'gcmtcs!' -Value "git commit --verbose --all --signoff --no-edit --amend"
Set-Alias -Name gcmsoA -Value "git commit --all --signoff"
Set-Alias -Name gcmsoM -Value "git commit --all --signoff --message"
Set-Alias -Name gchb -Value "git checkout -b"
Set-Alias -Name gchD -Value "git checkout $(git_develop_branch)"
Set-Alias -Name gcfg -Value "git config --list"
Set-Alias -Name gclR -Value "git clone --recurse-submodules"
Set-Alias -Name gcln -Value "git clean --interactive -d"
Set-Alias -Name gchm -Value "git checkout $(git_main_branch)"
Set-Alias -Name gcmtmsg -Value "git commit --message"
Set-Alias -Name gtco -Value "git checkout"
Set-Alias -Name gchkR -Value "git checkout --recurse-submodules"
Set-Alias -Name gtlog -Value "git shortlog --summary --numbered"
Set-Alias -Name gchp -Value "git cherry-pick"
Set-Alias -Name gchpa -Value "git cherry-pick --abort"
Set-Alias -Name gchpc -Value "git cherry-pick --continue"
Set-Alias -Name gcmsg -Value "git commit --gpg-sign"
Set-Alias -Name gcmsoMsg -Value "git commit --signoff --message"
Set-Alias -Name gcmtcsigS -Value "git commit --gpg-sign --signoff"
Set-Alias -Name gcmtcssM -Value "git commit --gpg-sign --signoff --message"

# Additional Git Aliases
Set-Alias -Name gd -Value "git diff"
Set-Alias -Name gdca -Value "git diff --cached"
Set-Alias -Name gdct -Value "git describe --tags $(git rev-list --tags --max-count=1)"
Set-Alias -Name gdcw -Value "git diff --cached --word-diff"
Set-Alias -Name gds -Value "git diff --staged"
Set-Alias -Name gdt -Value "git diff-tree --no-commit-id --name-only -r"
Set-Alias -Name gdup -Value "git diff @{upstream}"
Set-Alias -Name gdw -Value "git diff --word-diff"
Set-Alias -Name gf -Value "git fetch"
Set-Alias -Name gfa -Value "git fetch --all --prune --jobs=10"
Set-Alias -Name gfg -Value "git ls-files | Select-String"
Set-Alias -Name gfo -Value "git fetch origin"
Set-Alias -Name gg -Value "git gui citool"
Set-Alias -Name gga -Value "git gui citool --amend"
Set-Alias -Name gitPull -Value "git pull"                      # Changed from 'gl'
Set-Alias -Name glg -Value "git log --stat"
Set-Alias -Name glgg -Value "git log --graph"
Set-Alias -Name glgga -Value "git log --graph --decorate --all"
Set-Alias -Name glgm -Value "git log --graph --max-count=10"
Set-Alias -Name glgp -Value "git log --stat --patch"
Set-Alias -Name glo -Value "git log --oneline --decorate"
Set-Alias -Name glod -Value "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'"

"gcmt", "gcmt!", "gchB", "gcmtA", "gcmtA!", "gcmA", "gcmtna!", "gcmtcn!", "gcmtcs!", "gcmsoA", "gcmsoM", "gchb", "gchD", "gcfg", "gclR", "gcln", "gchm", "gcmtmsg", "gtco", "gchkR", "gtlog", "gchp", "gchpa", "gchpc", "gcmsg", "gcmsoMsg", "gcmtcsigS", "gcmtcssM