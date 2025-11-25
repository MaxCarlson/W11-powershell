# Setup Fix & Package Curation Plan

- [ ] Harden package installer
  - [x] Filter out invalid/legacy entries (ARP/MSIX export noise, bad hashes, junk like JDownloader) before invoking any manager
  - [x] Add a curated source file + categories scaffold for essential/optional installs (base path: `Setup/InstalledPackages`)
  - [x] Provide an interactive selector UI (checkboxes, select/deselect all, shift/ctrl multi-select) to choose categories/packages and save selection
  - [x] Ensure Install-Packages respects the curated list and selected categories; keep idempotent behavior
- [x] Fix parsing/logging bugs
  - [x] Quote/wrap interpolated variables with `:` in: `Setup/Update-EnvironmentPaths.ps1`, `Setup/Ensure-WSLBasics.ps1`
  - [x] Guard against missing ScheduledTasks cmdlets (import module) in scheduled-task setup scripts
- [ ] Cleanup/curate package lists
  - [ ] Remove/relocate noisy exports (`ARP\*`, `MSIX\*`, game IDs) from `master.packages.txt` into a quarantined file for reference
  - [ ] Add clear comments and category sections for the kept packages
- [ ] Verification
  - [ ] Dry-run path for Install-Packages using curated list only
  - [ ] Spot-check UI (selection persisted, default essential checked)
  - [ ] Rerun Setup.ps1 to confirm no parser errors and no rogue installs
