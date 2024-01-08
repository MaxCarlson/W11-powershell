param (
    [bool]$verbose = $true,
    [string]$source,
    [string]$destination
)

function VerbosePrint {
    param (
        [string]$message
    )
    if ($verbose) {
        Write-Host $message
    }
}
# Function to escape square brackets in a path
function Convert-SquareBrackets {
    param (
        [string]$Path
    )

    $escapedPath = $Path -replace '\[', '`[' -replace '\]', '`]'
    return $escapedPath
}

$ageLimit = (Get-Date).AddDays(-1)

if (-Not (Test-Path $destination)) {
    VerbosePrint "Destination folder does not exist. Creating $destination..."
    New-Item -ItemType Directory -Path $destination
}

VerbosePrint "Starting the script to move files from $source to $destination..."

Get-ChildItem -Path $source -Recurse 
	| Where-Object {$_.LastWriteTime -le $ageLimit -and $_.Name -notlike '.*'} 
	| ForEach-Object {
    $target = $destination + $_.FullName.Substring($source.length)
    $targetDir = [System.IO.Path]::GetDirectoryName($target)
	
    VerbosePrint "Source File: $source"
    VerbosePrint "Target: $target"
	
    if (-Not (Test-Path $targetDir)) {
	VerbosePrint "Creating directory $targetDir..."
        New-Item -ItemType Directory -Force -Path $targetDir
    }

    $escapedTarget = Convert-SquareBrackets -Path $target
    if (Test-Path $escapedTarget) {
        $sourceFileSize = (Get-Item $_.FullName).Length
        $destinationFileSize = (Get-Item $target).Length
        if ($sourceFileSize -gt $destinationFileSize) {
            VerbosePrint "Source file '$source' : size $sourceFileSize is larger '$target' : size $destinationFileSize than destination file."
	    VerbosePrint "Overwriting $target..."
            Move-Item -LiteralPath $_.FullName -Destination $target -Force
        } else {
            VerbosePrint "Destination file is larger or equal in size. Deleting source $_.FullName ..."
            Remove-Item -LiteralPath $_.FullName -Force
        }
    } else {
        VerbosePrint "Moving item to $target..."
        Move-Item -LiteralPath $_.FullName -Destination $target
    }
    #VerbosePrint "Test early exit"
    #exit

}
VerbosePrint "Script completed."
