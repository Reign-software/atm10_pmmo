# Define the root directory to process
$rootDir = "d:\src\atm10_pmmo\atm_10_pack\src\main\resources\data"

# Define patterns for gathering tool filenames
$gatheringToolPatterns = @(
    "pickaxe", "axe", "shovel", "paxel", "excavator", "hammer", "drill", "saw", "hoe", "sickle"
)

# Stats counters
$filesProcessed = 0
$filesModified = 0
$veinDataRemoved = 0

Write-Host "Starting to process item JSON files..." -ForegroundColor Cyan

# Find all mod directories
$modDirs = Get-ChildItem -Path $rootDir -Directory

foreach ($modDir in $modDirs) {
    # Look for the items directory within each mod
    $itemsPath = Join-Path -Path $modDir.FullName -ChildPath "pmmo\items"
    
    if (Test-Path $itemsPath) {
        Write-Host "Processing mod: $($modDir.Name)" -ForegroundColor Yellow
        
        # Find all JSON files in the items directory
        $itemFiles = Get-ChildItem -Path $itemsPath -Filter "*.json" -File
        
        foreach ($file in $itemFiles) {
            $filesProcessed++
            $isGatheringTool = $false
            
            # Check if the filename contains any gathering tool patterns
            foreach ($pattern in $gatheringToolPatterns) {
                if ($file.BaseName -like "*$pattern*") {
                    $isGatheringTool = $true
                    break
                }
            }
            
            # Process the file if it's not a gathering tool
            if (-not $isGatheringTool) {
                try {
                    # Read and parse the JSON file
                    $json = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                    
                    # Check if it has vein_data
                    if ($json.PSObject.Properties.Name -contains "vein_data") {
                        # Remove the vein_data property
                        $json.PSObject.Properties.Remove("vein_data")
                        $veinDataRemoved++
                        $filesModified++
                        
                        # Convert back to JSON with proper formatting and save
                        $jsonContent = $json | ConvertTo-Json -Depth 20 -Compress:$false
                        $jsonContent | Set-Content -Path $file.FullName -Encoding UTF8
                        
                        Write-Host "  Removed vein_data from: $($file.Name)" -ForegroundColor Green
                    }
                }
                catch {
                    Write-Host "  Error processing $($file.FullName): $_" -ForegroundColor Red
                }
            }
            else {
                Write-Verbose "Skipping gathering tool: $($file.Name)"
            }
        }
    }
}

Write-Host "`nVein Data Removal Operation Complete!" -ForegroundColor Cyan
Write-Host "Files processed: $filesProcessed" -ForegroundColor White
Write-Host "Files modified: $filesModified" -ForegroundColor Green
Write-Host "Vein data entries removed: $veinDataRemoved" -ForegroundColor Yellow