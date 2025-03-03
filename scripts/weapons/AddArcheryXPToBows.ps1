# Script to add archery XP to bows and crossbows based on their tier

# Define root path for data
$rootPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data"

# Define patterns to identify bows and crossbows
$bowPatterns = @(
    "bow", "crossbow", "longbow", "shortbow", "flatbow", "recurve"
)

# Define tier mappings with their XP values
$tierMappings = @{
    # Basic/wooden tier
    "simple" = 500
    "training" = 500
    "wooden" = 500
    "basic" = 500

    # Stone/Iron tier
    "iron" = 1000
    "stone" = 1000
    "copper" = 1000
    "tin" = 1000
    "bronze" = 1500
    "steel" = 1500

    # Gold tier
    "gold" = 2000
    "golden" = 2000
    "silver" = 2000
    "electrum" = 2500
    "brass" = 2500

    # Diamond tier
    "diamond" = 5000
    "emerald" = 5000
    "sapphire" = 5000
    "ruby" = 5000
    "obsidian" = 6000
    "osmium" = 6000

    # Netherite tier
    "netherite" = 10000
    "nether" = 8000
    "reinforced" = 8000
    "enderium" = 12000
    "signalum" = 12000
    "lumium" = 12000
    "refined" = 10000

    # Special materials tier
    "allthemodium" = 15000
    "vibranium" = 20000
    "unobtainium" = 25000
    
    # Top tier
    "draconic" = 30000
    "chaotic" = 30000
    "wyvern" = 20000
    "dragon" = 25000
    "infinity" = 30000
    "ultimate" = 30000
    "creative" = 30000
    "awakened" = 30000
}

# Stats counters
$processedCount = 0
$modifiedCount = 0
$createdCount = 0
$modStats = @{}
$tierStats = @{}

# Process all JSON files in mod data directories
Write-Host "Scanning for bow and crossbow items to add archery XP..." -ForegroundColor Cyan

foreach ($mod in (Get-ChildItem -Path $rootPath -Directory)) {
    $modName = $mod.Name
    $itemsPath = Join-Path -Path $mod.FullName -ChildPath "pmmo\items"
    
    # Skip if items directory doesn't exist
    if (-not (Test-Path $itemsPath)) {
        continue
    }
    
    # Get all JSON files in the items directory
    $itemFiles = Get-ChildItem -Path $itemsPath -Filter "*.json"
    $modBowCount = 0
    
    foreach ($file in $itemFiles) {
        $fileName = $file.BaseName.ToLower()
        $processedCount++
        
        # Check if the item is a bow or crossbow
        $isBow = $false
        foreach ($pattern in $bowPatterns) {
            if ($fileName -match $pattern) {
                $isBow = $true
                break
            }
        }
        
        # Skip if not a bow or crossbow
        if (-not $isBow) {
            continue
        }
        
        # Determine the tier and XP value
        $xpValue = 500  # Default base value
        
        # Check for tier keywords in the filename
        foreach ($material in $tierMappings.Keys) {
            if ($fileName -match $material) {
                $xpValue = $tierMappings[$material]
                break
            }
        }
        
        try {
            # Read the JSON content
            $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $modified = $false
            
            # Ensure xp_values exists
            if (-not $jsonContent.PSObject.Properties["xp_values"]) {
                $jsonContent | Add-Member -NotePropertyName "xp_values" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            # Ensure CRAFT exists under xp_values
            if (-not $jsonContent.xp_values.PSObject.Properties["CRAFT"]) {
                $jsonContent.xp_values | Add-Member -NotePropertyName "CRAFT" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            # Add or update archery XP
            if (-not $jsonContent.xp_values.CRAFT.PSObject.Properties["archery"] -or 
                $jsonContent.xp_values.CRAFT.archery -ne $xpValue) {
                $jsonContent.xp_values.CRAFT | Add-Member -NotePropertyName "archery" -NotePropertyValue $xpValue -Force
                $modified = $true
                
                # Also add archery requirement for USE if none exists
                if ($jsonContent.PSObject.Properties["requirements"] -and 
                    $jsonContent.requirements.PSObject.Properties["USE"]) {
                    if (-not $jsonContent.requirements.USE.PSObject.Properties["archery"]) {
                        $archeryReq = [Math]::Max(50, [Math]::Min(500, [Math]::Floor($xpValue / 100) * 10))
                        $jsonContent.requirements.USE | Add-Member -NotePropertyName "archery" -NotePropertyValue $archeryReq -Force
                        $modified = $true
                    }
                }
            }
            
            # Add some archery XP for DEAL_DAMAGE if it's a weapon
            if ($jsonContent.xp_values.PSObject.Properties["DEAL_DAMAGE"]) {
                if (-not $jsonContent.xp_values.DEAL_DAMAGE.PSObject.Properties["archery"]) {
                    $jsonContent.xp_values.DEAL_DAMAGE | Add-Member -NotePropertyName "archery" -NotePropertyValue ([Math]::Floor($xpValue / 100)) -Force
                    $modified = $true
                }
            } else {
                $jsonContent.xp_values | Add-Member -NotePropertyName "DEAL_DAMAGE" -NotePropertyValue @{ "archery" = [Math]::Floor($xpValue / 100) } -Force
                $modified = $true
            }
            
            # Save changes if modified
            if ($modified) {
                $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $file.FullName
                Write-Host "  Updated $modName`:$fileName (XP: $xpValue)" -ForegroundColor Green
                $modifiedCount++
                $modBowCount++
                
                # Track tier stats for reporting
                $tierValue = $xpValue
                if (-not $tierStats.ContainsKey($tierValue)) {
                    $tierStats[$tierValue] = 0
                }
                $tierStats[$tierValue]++
            }
        }
        catch {
            Write-Host "  Error processing $fileName : $_" -ForegroundColor Red
        }
    }
    
    # Update mod stats
    if ($modBowCount -gt 0) {
        $modStats[$modName] = $modBowCount
        Write-Host "Updated $modBowCount bows/crossbows in $modName" -ForegroundColor Cyan
    }
}

# Display results
Write-Host "`nArchery XP Update Complete!" -ForegroundColor Green
Write-Host "Bows and crossbows processed: $processedCount" -ForegroundColor White
Write-Host "Items modified with archery XP: $modifiedCount" -ForegroundColor Cyan

# Display tier statistics
if ($tierStats.Count -gt 0) {
    Write-Host "`nItems by XP value:" -ForegroundColor Magenta
    foreach ($xp in ($tierStats.Keys | Sort-Object)) {
        $count = $tierStats[$xp]
        Write-Host "  XP $xp : $count item(s)" -ForegroundColor White
    }
}

# Display mod statistics
if ($modStats.Count -gt 0) {
    Write-Host "`nModified items by mod:" -ForegroundColor Magenta
    foreach ($mod in ($modStats.Keys | Sort-Object -Property {$modStats[$_]} -Descending)) {
        $count = $modStats[$mod]
        Write-Host "  $mod : $count item(s)" -ForegroundColor White
    }
}