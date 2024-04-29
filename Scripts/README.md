# Install

## Git

### WinGet
Get [WinGet](https://www.microsoft.com/p/app-installer/9nblggh4nns1#activetab=pivot:overviewtab) from the Windows Store. 
Other name is App Installer

### GitHub CLI and Login
```powershell
winget install Git.Git --source winget
winget install GitHub.cli --source winget
gh auth login
```

### Open Powershell and run

```
Set-Location ~
mkdir sources
Set-Location sources
gh repo clone W11-powershell
```




Run Setup.ps1 with powershell