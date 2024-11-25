param(
    [string]$inputFilePath,
    [string]$outputDirectory
)

# Check if yt-dlp is installed
if (-not (Get-Command "yt-dlp" -ErrorAction SilentlyContinue)) {
    Write-Error "yt-dlp is not installed. Please install yt-dlp before running this script."
    exit 1
}

# Check if input file exists
if (-not (Test-Path $inputFilePath)) {
    Write-Error "Input file path '$inputFilePath' does not exist."
    exit 1
}

# Create output directory if it doesn't exist
if (-not (Test-Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory
}

# Read URLs from the input file
$urls = Get-Content $inputFilePath | Where-Object { $_ -ne "" }

foreach ($url in $urls) {
    # Download the highest quality video using yt-dlp
    yt-dlp -f -o "$outputDirectory\%(title)s.%(ext)s" $url
}

Write-Output "Download completed."
