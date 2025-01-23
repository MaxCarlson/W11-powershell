function Show-Menu {
    param (
        [string]$Title,
        [array]$Options
    )
    Write-Host "`n$Title"
    Write-Host "=============================="
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "$i. $($Options[$i])"
    }
    Write-Host "=============================="
    Write-Host "Enter your choice (number): "
    return [int](Read-Host)
}

function Explore-Releases {
    param (
        [string]$Repo
    )
    while ($true) {
        try {
            # List releases and parse JSON output
            $releasesJson = gh release list -R $Repo --json tagName,name
            $releases = $releasesJson | ConvertFrom-Json

            if (-not $releases -or $releases.Count -eq 0) {
                Write-Host "No releases found for $Repo!" -ForegroundColor Yellow
                break
            }
        } catch {
            Write-Host "Error fetching releases: $($_.Exception.Message)" -ForegroundColor Red
            break
        }

        # Build menu options
        $releaseMenu = @("Go Back")
        foreach ($release in $releases) {
            $releaseMenu += "$($release.tagName) - $($release.name)"
        }

        # Show menu and get user selection
        $releaseChoice = Show-Menu "Select a Release" $releaseMenu
        if ($releaseChoice -eq 0) { break }

        $selectedRelease = $releases[$releaseChoice - 1]
        if ($null -eq $selectedRelease) {
            Write-Host "Invalid choice, please try again." -ForegroundColor Red
            continue
        }

        try {
            # List assets for the selected release
            $assetsJson = gh release view $selectedRelease.tagName -R $Repo --json assets
            $assets = ($assetsJson | ConvertFrom-Json).assets

            if (-not $assets -or $assets.Count -eq 0) {
                Write-Host "No assets found for release $($selectedRelease.tagName)!" -ForegroundColor Yellow
                continue
            }
        } catch {
            Write-Host "Error fetching assets: $($_.Exception.Message)" -ForegroundColor Red
            continue
        }

        # Build asset menu
        $assetMenu = @("Go Back")
        foreach ($asset in $assets) {
            $assetMenu += $asset.name
        }

        # Show asset menu and get user selection
        $assetChoice = Show-Menu "Select an Asset to Download" $assetMenu
        if ($assetChoice -eq 0) { continue }

        $selectedAsset = $assets[$assetChoice - 1]
        if ($null -eq $selectedAsset) {
            Write-Host "Invalid choice, please try again." -ForegroundColor Red
            continue
        }

        # Download selected asset
        try {
            gh release download $selectedRelease.tagName -R $Repo -p $selectedAsset.name
            Write-Host "Successfully downloaded $($selectedAsset.name) to the current directory." -ForegroundColor Green
        } catch {
            Write-Host "Failed to download $($selectedAsset.name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Explore-Repository {
    param (
        [string]$Repo
    )
    while ($true) {
        $menuOptions = @(
            "Go Back",
            "Releases"
        )
        $choice = Show-Menu "GitHub Repository Explorer ($Repo)" $menuOptions
        switch ($choice) {
            0 { break }
            1 { Explore-Releases -Repo $Repo }
            default {
                Write-Host "Invalid choice, please try again." -ForegroundColor Red
            }
        }
    }
}

function Start-GitHubExplorer {
    while ($true) {
        $repo = Read-Host "Enter the owner/repository name (e.g., user/repo) or 'q' to quit"
        if ($repo -eq 'q') { break }
        if (-not $repo) {
            Write-Host "Repository name cannot be empty!" -ForegroundColor Red
            continue
        }
        Explore-Repository -Repo $repo
    }
}

Export-ModuleMember -Function Start-GitHubExplorer
