# Script to remove technology requirements from basic armors that aren't actually tech-based

# Define root path for data
$rootPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data"

# List of specific tech armor name patterns - these ARE tech and should keep requirement
# Any armor NOT matching these patterns will have tech requirements removed
$techArmorPatterns = @(
    "jetpack",
    "quantum",
    "hazmat",
    "power",
    "flux",
    "energized",
    "powered",
    "meka",
    "modular",
    "nano",
    "electric",
    "energy",
    "reactor",
    "circuit",
    "capacitor",
    "battery",
    "industrial"
)

# Stats counters
$processedCount = 0
$modifiedCount = 0
$techArmorFound = 0
$nonTechArmorFound = 0
$modsWithModifiedArmor = @{}

# Process all JSON files in mod data directories
Write-Host "Scanning for armor items with inappropriate technology requirements..." -ForegroundColor Cyan

foreach ($mod in (Get-ChildItem -Path $rootPath -Directory)) {
    $modName = $mod.Name
    $itemsPath = Join-Path -Path $mod.FullName -ChildPath "pmmo\items"
    
    # Skip if items directory doesn't exist
    if (-not (Test-Path $itemsPath)) {
        continue
    }
    
    # Get all JSON files in the items directory
    $itemFiles = Get-ChildItem -Path $itemsPath -Filter "*.json"
    $modArmorCount = 0
    
    foreach ($file in $itemFiles) {
        $fileName = $file.BaseName.ToLower()
        $processedCount++
        
        # Skip if not an armor item
        if (-not ($fileName -match "helmet|chestplate|leggings|boots|armor|cuirass|gauntlet|greaves")) {
            continue
        }
        
        try {
            # Read the JSON content
            $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            
            # Check if the item has technology requirements
            $hasTechRequirement = $false
            
            # Check in WEAR requirement
            if ($jsonContent.PSObject.Properties["requirements"] -and
                $jsonContent.requirements.PSObject.Properties["WEAR"] -and
                $jsonContent.requirements.WEAR.PSObject.Properties["technology"]) {
                $hasTechRequirement = $true
            }
            
            # Also check USE requirement
            if ($jsonContent.PSObject.Properties["requirements"] -and
                $jsonContent.requirements.PSObject.Properties["USE"] -and
                $jsonContent.requirements.USE.PSObject.Properties["technology"]) {
                $hasTechRequirement = $true
            }
            
            # Only process items with tech requirements
            if ($hasTechRequirement) {
                # Check if it matches tech patterns
                $isTechArmor = $false
                foreach ($pattern in $techArmorPatterns) {
                    if ($fileName -match $pattern) {
                        $isTechArmor = $true
                        $techArmorFound++
                        break
                    }
                }
                
                # Remove technology requirement if NOT a tech armor
                if (-not $isTechArmor) {
                    # Remove from WEAR
                    if ($jsonContent.requirements.PSObject.Properties["WEAR"] -and 
                        $jsonContent.requirements.WEAR.PSObject.Properties["technology"]) {
                        $jsonContent.requirements.WEAR.PSObject.Properties.Remove("technology")
                        Write-Host "  Removed technology from WEAR in $modName`:$fileName" -ForegroundColor Yellow
                    }
                    
                    # Remove from USE
                    if ($jsonContent.requirements.PSObject.Properties["USE"] -and 
                        $jsonContent.requirements.USE.PSObject.Properties["technology"]) {
                        $jsonContent.requirements.USE.PSObject.Properties.Remove("technology")
                        Write-Host "  Removed technology from USE in $modName`:$fileName" -ForegroundColor Yellow
                    }
                    
                    # Save the modified JSON
                    $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $file.FullName
                    $modifiedCount++
                    $nonTechArmorFound++
                    $modArmorCount++
                    
                    # Track mods with modifications
                    if (-not $modsWithModifiedArmor.ContainsKey($modName)) {
                        $modsWithModifiedArmor[$modName] = 0
                    }
                    $modsWithModifiedArmor[$modName]++
                }
            }
        }
        catch {
            Write-Host "  Error processing $fileName : $_" -ForegroundColor Red
        }
    }
    
    if ($modArmorCount -gt 0) {
        Write-Host "Modified $modArmorCount armor items in mod $modName" -ForegroundColor Cyan
    }
}

# Display results
Write-Host "`nProcessing complete!" -ForegroundColor Green
Write-Host "Armor items processed: $processedCount" -ForegroundColor White
Write-Host "Armor items modified: $modifiedCount" -ForegroundColor Cyan
Write-Host "  Tech armor identified (kept tech requirements): $techArmorFound" -ForegroundColor Blue
Write-Host "  Non-tech armor identified (tech requirements removed): $nonTechArmorFound" -ForegroundColor Yellow

# Generate a report of types of armor that should have tech requirements
Write-Host "`nKeywords Used to Identify Tech Armor:" -ForegroundColor Magenta
foreach ($pattern in ($techArmorPatterns | Sort-Object)) {
    Write-Host "  - $pattern" -ForegroundColor White
}

# Report on mods that had armor modified
Write-Host "`nMods With Armor Items Modified:" -ForegroundColor Magenta
foreach ($mod in ($modsWithModifiedArmor.Keys | Sort-Object)) {
    $count = $modsWithModifiedArmor[$mod]
    Write-Host "  - $mod : $count item(s)" -ForegroundColor White
}
