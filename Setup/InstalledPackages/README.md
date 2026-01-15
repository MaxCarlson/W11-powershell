# Package Installer (curated)

- UI selector: run `pwsh -File C:\Users\mcarls\src\scripts\modules\cross_platform\package_selector.ps1` (uses `package-catalog.json` + saves to `selected.packages.txt`). Checkboxes, select/deselect all, multi-select supported. Rerun anytime to update selections.
- Lists live here: `Lists/package-catalog.json` (categories/defaults), `Lists/selected.packages.txt` (current choices). The old exported bulk list is preserved as `Lists/master.packages.archive.txt`; installs use the curated files only.
- Installer: `Setup/Install-Packages.ps1` (called from `Setup.ps1`) reads `selected.packages.txt` (or catalog defaults) and skips noisy ARP/MSIX exports automatically. Use `-DryRun` to preview.
- Scripts repo CLI: after `C:\Users\mcarls\src\scripts\bootstrap.ps1`, you get the standard CLI wrappers (e.g., `pwsh-setup` if provided there). Keep this README as the access point from W11-powershell.
- UI stack: current selector is PowerShell/WPF; if you prefer a terminal UI, `scripts/modules/termdash` has components we can swap in later.
