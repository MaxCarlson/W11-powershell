param(
    [string[]]$LibraryNames  # Array of library names passed as command-line arguments
)

# Define your Plex server details
$plexServer = "http://127.0.0.1:32400"
$plexToken = "_7d3dx-sJNmA9Bfg1cr7"  # Replace this with your actual Plex token

# Function to fetch all library sections from the Plex server
function Get-LibrarySections {
    $url = "$plexServer/library/sections?X-Plex-Token=$plexToken"
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get
        return $response.MediaContainer.Directory
    } catch {
        Write-Host "Failed to fetch library sections: $_"
        return $null
    }
}

# Function to update a library section by ID and name
function Update-LibrarySection {
    param (
        [string]$SectionId,
        [string]$SectionTitle  # Added parameter to pass library title
    )

    $scanUrl = "$plexServer/library/sections/$SectionId/refresh?X-Plex-Token=$plexToken"
    try {
        Invoke-RestMethod -Uri $scanUrl -Method Get
        Write-Host "Library section updated: $SectionTitle"  # Updated to print library title
    } catch {
        Write-Host "Failed to update library section ${SectionTitle}: $_"
    }
}

# Function to update specified library sections or all if none are specified
function Update-SpecifiedLibrarySections {
    $sections = Get-LibrarySections
    if ($sections) {
        if ($LibraryNames.Length -gt 0) {
            $filteredSections = $sections | Where-Object { $LibraryNames -contains $_.title }
            foreach ($section in $filteredSections) {
                Update-LibrarySection -SectionId $section.key -SectionTitle $section.title
            }
        } else {
            foreach ($section in $sections) {
                Update-LibrarySection -SectionId $section.key -SectionTitle $section.title
            }
        }
    } else {
        Write-Host "Could not retrieve sections or invalid token."
    }
}

# Main execution block
Update-SpecifiedLibrarySections
