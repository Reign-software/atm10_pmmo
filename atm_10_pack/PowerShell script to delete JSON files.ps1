# PowerShell script to delete JSON files with specific whole words in filenames
param(
    [Parameter(Mandatory=$false)]
    [string]$Directory = "."  # Default to current directory if not specified
)

# Words to search for as whole words
$wordsToMatch = @("pillar", "lamp", "lantern", "bricks", "stairs", "slab", "wall", "roof", "door", "window", "fence", "gate", "path", "road", "torch", "sign", "trapdoor", "ladder", "bed", "chair", "armor_stand")

# Create a regex pattern to match whole words
$pattern = '\b(' + ($wordsToMatch -join '|') + ')\b'

# Get all JSON files recursively
$jsonFiles = Get-ChildItem -Path $Directory -Filter "*.json" -Recurse

# Counter for deleted files
$deletedCount = 0

foreach ($file in $jsonFiles) {
    # Convert filename to just the name portion without extension for testing
    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    
    # Replace underscores with spaces to help with word boundary matching
    $testName = $fileNameWithoutExtension -replace "_", " "
    
    # Check if any of the words appear as whole words
    if ($testName -match $pattern) {
        Write-Host "Deleting: $($file.FullName)" -ForegroundColor Red
        Remove-Item -Path $file.FullName -Force
        $deletedCount++
    }
}

Write-Host "Process complete. $deletedCount file(s) deleted." -ForegroundColor Green