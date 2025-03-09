# Script to convert woodcutting to farming for grass and flowers
$dataPath = "d:\src\atm10_pmmo\atm_10_pack\src\main\resources\data\"
$logPath = "d:\src\atm10_pmmo\scripts\grass_to_farming_conversion_log.txt"

# Initialize statistics
$stats = @{
    "blocksConverted" = 0
    "itemsConverted" = 0
    "totalFilesModified" = 0
}

# Start log file
"Grass/Flowers XP conversion started at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath
"Tasks:" | Out-File -FilePath $logPath -Append
" - Convert woodcutting XP to farming XP for grass and flower blocks/items" | Out-File -FilePath $logPath -Append
" - Set BLOCK_BREAK farming XP to 40 for all grass and flower blocks" | Out-File -FilePath $logPath -Append

# Define patterns for grass and flowers - expanded to include mod-specific plants
$grassFlowerPatterns = @(
    # Vanilla and common patterns
    "*grass*", "*flower*", "*dandelion*", "*poppy*", 
    "*orchid*", "*allium*", "*bluet*", "*tulip*",
    "*daisy*", "*sunflower*", "*lilac*", "*rose*", 
    "*peony*", "*fern*", "*weed*", "*bush*", 
    "*shrub*", "*sprout*", "*seagrass*",
    "*lily*", "*moss*",
    
    # Mystical Agriculture patterns
    "*essence_flower*", "*mystical_flower*", "*infusion_flower*",
    "*magical_plant*", "*mystical_crop*", "*essence_plant*",
    "*infusion_crop*", "*prosperity*", "*inferium*", "*prudentium*",
    "*tertium*", "*imperium*", "*supremium*", "*awakened_crop*",
    
    # Biomes We've Gone / Biomes O' Plenty patterns
    "*blossom*", "*wildflower*", "*bulb*", "*bloom*", "*cattail*",
    "*clover*", "*reed*", "*root*", "*sprout*", "*lavender*", 
    "*hydrangea*", "*yellow_hibiscus*", "*orange_cosmos*", "*pink_daffodil*",
    "*pink_hibiscus*", "*glowshroom*", "*toadstool*", "*bell_flower*",
    
    # Additional mod flowers
    "*floral*", "*petal*", "*botania*", "*botanical*", "*florid*", 
    "*flora*", "*pistil*", "*stamen*", "*luminous_*"
)

# Define specific mod flower mapping - direct matches for specific mods
$specificModFlowers = @{
    "mysticalagriculture" = @(
        "*_crop", "*_essence", "*_seeds", "*_bloom", "*_petal"
    )
    "biomesoplenty" = @(
        "*_flower", "*_rose", "*_tulip", "*_lily", "*_wildflower"
    )
    "biomesogone" = @(
        "*_flower", "*_bloom", "*_rose", "*_lavender", "*_hibiscus"
    )
    "botania" = @(
        "*_mystical*", "*_flower*", "*_petal*", "*_blossom*"
    )
}

# Get all mod directories
$modDirs = Get-ChildItem -Path $dataPath -Directory

foreach ($modDir in $modDirs) {
    $modName = $modDir.Name
    $modPmmoPath = Join-Path -Path $modDir.FullName -ChildPath "pmmo"
    
    # Skip if no PMMO data
    if (-not (Test-Path $modPmmoPath)) {
        continue
    }
    
    Write-Host "Processing $modName..." -ForegroundColor Cyan
    
    # Add mod-specific patterns if this is a known mod with flowers
    $currentPatterns = $grassFlowerPatterns.Clone()
    if ($specificModFlowers.ContainsKey($modName)) {
        $currentPatterns += $specificModFlowers[$modName]
        Write-Host "  Using extended patterns for $modName" -ForegroundColor Magenta
    }
    
    # Process blocks
    $blocksPath = Join-Path -Path $modPmmoPath -ChildPath "blocks"
    if (Test-Path $blocksPath) {
        # Find grass and flower blocks using the patterns
        $grassFlowerFiles = @()
        
        foreach ($pattern in $currentPatterns) {
            $grassFlowerFiles += Get-ChildItem -Path $blocksPath -Filter $pattern
        }
        
        # For certain specific mods, include all blocks if requested
        if ($modName -eq "mysticalagriculture" -or $modName -eq "mystical_agriculture" -or 
            $modName -eq "botania" -or $modName -eq "biomesoplenty" -or 
            $modName -eq "biomesogone" -or $modName -eq "biomeswevegone") {
            
            # Add all crop/plant-specific blocks
            $additionalFiles = Get-ChildItem -Path $blocksPath -Filter "*.json"
            Write-Host "  Including all blocks from $modName" -ForegroundColor Magenta
            $grassFlowerFiles += $additionalFiles
        }
        
        # Remove duplicates
        $grassFlowerFiles = $grassFlowerFiles | Sort-Object FullName -Unique
        
        Write-Host "  Found $($grassFlowerFiles.Count) potential grass/flower blocks" -ForegroundColor White
        
        foreach ($blockFile in $grassFlowerFiles) {
            $blockName = $blockFile.BaseName
            Write-Host "    Processing block: $blockName" -ForegroundColor Yellow
            
            # Load the JSON
            $blockJson = Get-Content -Path $blockFile.FullName -Raw | ConvertFrom-Json
            $modified = $false
            
            # Process requirements - convert woodcutting to farming
            if ($blockJson.PSObject.Properties["requirements"]) {
                foreach ($reqType in @("PLACE", "BREAK", "INTERACT", "USE")) {
                    if ($blockJson.requirements.PSObject.Properties[$reqType] -and 
                        $blockJson.requirements.$reqType.PSObject.Properties["woodcutting"]) {
                        
                        $woodcuttingValue = $blockJson.requirements.$reqType.woodcutting
                        $blockJson.requirements.$reqType | Add-Member -NotePropertyName "farming" -NotePropertyValue $woodcuttingValue -Force
                        $blockJson.requirements.$reqType.PSObject.Properties.Remove("woodcutting")
                        $modified = $true
                        
                        "$blockName - Converted $reqType requirement from woodcutting to farming: $woodcuttingValue" | Out-File -FilePath $logPath -Append
                    }
                }
            }
            
            # Process XP values - convert woodcutting to farming and set BLOCK_BREAK to 40
            if ($blockJson.PSObject.Properties["xp_values"]) {
                foreach ($xpType in ($blockJson.xp_values.PSObject.Properties | Select-Object -ExpandProperty Name)) {
                    if ($blockJson.xp_values.$xpType.PSObject.Properties["woodcutting"]) {
                        $woodcuttingValue = $blockJson.xp_values.$xpType.woodcutting
                        
                        # If it's BLOCK_BREAK, set farming to 40
                        if ($xpType -eq "BLOCK_BREAK") {
                            $blockJson.xp_values.$xpType | Add-Member -NotePropertyName "farming" -NotePropertyValue 40 -Force
                            "$blockName - Set BLOCK_BREAK farming XP to 40 (was woodcutting: $woodcuttingValue)" | Out-File -FilePath $logPath -Append
                        }
                        else {
                            $blockJson.xp_values.$xpType | Add-Member -NotePropertyName "farming" -NotePropertyValue $woodcuttingValue -Force
                            "$blockName - Converted $xpType XP from woodcutting to farming: $woodcuttingValue" | Out-File -FilePath $logPath -Append
                        }
                        
                        $blockJson.xp_values.$xpType.PSObject.Properties.Remove("woodcutting")
                        $modified = $true
                    }
                    # If no woodcutting but it's BLOCK_BREAK, set farming to 40
                    elseif ($xpType -eq "BLOCK_BREAK" -and -not $blockJson.xp_values.$xpType.PSObject.Properties["farming"]) {
                        $blockJson.xp_values.$xpType | Add-Member -NotePropertyName "farming" -NotePropertyValue 40 -Force
                        $modified = $true
                        "$blockName - Added BLOCK_BREAK farming XP of 40" | Out-File -FilePath $logPath -Append
                    }
                }
                
                # Ensure BLOCK_BREAK section exists with farming XP=40
                if (-not $blockJson.xp_values.PSObject.Properties["BLOCK_BREAK"]) {
                    $blockJson.xp_values | Add-Member -NotePropertyName "BLOCK_BREAK" -NotePropertyValue @{
                        "farming" = 40
                    } -Force
                    $modified = $true
                    "$blockName - Added BLOCK_BREAK section with farming XP of 40" | Out-File -FilePath $logPath -Append
                }
            }
            
            # Save changes if modified
            if ($modified) {
                $blockJson | ConvertTo-Json -Depth 10 | Set-Content -Path $blockFile.FullName -Encoding UTF8
                $stats.blocksConverted++
                $stats.totalFilesModified++
                
                Write-Host "      Updated block: $blockName" -ForegroundColor Green
            }
        }
    }
    
    # Process items
    $itemsPath = Join-Path -Path $modPmmoPath -ChildPath "items"
    if (Test-Path $itemsPath) {
        # Find grass and flower items using the patterns
        $grassFlowerFiles = @()
        
        foreach ($pattern in $currentPatterns) {
            $grassFlowerFiles += Get-ChildItem -Path $itemsPath -Filter $pattern
        }
        
        # For certain specific mods, include all items if requested
        if ($modName -eq "mysticalagriculture" -or $modName -eq "mystical_agriculture" -or 
            $modName -eq "botania" -or $modName -eq "biomesoplenty" -or 
            $modName -eq "biomesogone" -or $modName -eq "biomeswevegone") {
            
            # Add plant/seed/flower-related items specifically
            $seedPatterns = @("*seed*", "*crop*", "*essence*", "*petal*", "*flower*")
            foreach ($pattern in $seedPatterns) {
                $additionalFiles = Get-ChildItem -Path $itemsPath -Filter $pattern
                $grassFlowerFiles += $additionalFiles
            }
            Write-Host "  Including specialized items from $modName" -ForegroundColor Magenta
        }
        
        # Remove duplicates
        $grassFlowerFiles = $grassFlowerFiles | Sort-Object FullName -Unique
        
        Write-Host "  Found $($grassFlowerFiles.Count) potential grass/flower items" -ForegroundColor White
        
        foreach ($itemFile in $grassFlowerFiles) {
            $itemName = $itemFile.BaseName
            Write-Host "    Processing item: $itemName" -ForegroundColor Yellow
            
            # Load the JSON
            $itemJson = Get-Content -Path $itemFile.FullName -Raw | ConvertFrom-Json
            $modified = $false
            
            # Process requirements - convert woodcutting to farming
            if ($itemJson.PSObject.Properties["requirements"]) {
                foreach ($reqType in @("PLACE", "BREAK", "INTERACT", "USE", "TOOL", "WEAPON", "WEAR")) {
                    if ($itemJson.requirements.PSObject.Properties[$reqType] -and 
                        $itemJson.requirements.$reqType.PSObject.Properties["woodcutting"]) {
                        
                        $woodcuttingValue = $itemJson.requirements.$reqType.woodcutting
                        $itemJson.requirements.$reqType | Add-Member -NotePropertyName "farming" -NotePropertyValue $woodcuttingValue -Force
                        $itemJson.requirements.$reqType.PSObject.Properties.Remove("woodcutting")
                        $modified = $true
                        
                        "$itemName - Converted $reqType requirement from woodcutting to farming: $woodcuttingValue" | Out-File -FilePath $logPath -Append
                    }
                }
            }
            
            # Process XP values - convert woodcutting to farming
            if ($itemJson.PSObject.Properties["xp_values"]) {
                foreach ($xpType in ($itemJson.xp_values.PSObject.Properties | Select-Object -ExpandProperty Name)) {
                    if ($itemJson.xp_values.$xpType.PSObject.Properties["woodcutting"]) {
                        $woodcuttingValue = $itemJson.xp_values.$xpType.woodcutting
                        
                        # Convert woodcutting to farming, maintaining the value
                        $itemJson.xp_values.$xpType | Add-Member -NotePropertyName "farming" -NotePropertyValue $woodcuttingValue -Force
                        $itemJson.xp_values.$xpType.PSObject.Properties.Remove("woodcutting")
                        $modified = $true
                        
                        "$itemName - Converted $xpType XP from woodcutting to farming: $woodcuttingValue" | Out-File -FilePath $logPath -Append
                    }
                }
            }
            
            # Save changes if modified
            if ($modified) {
                $itemJson | ConvertTo-Json -Depth 10 | Set-Content -Path $itemFile.FullName -Encoding UTF8
                $stats.itemsConverted++
                $stats.totalFilesModified++
                
                Write-Host "      Updated item: $itemName" -ForegroundColor Green
            }
        }
    }
}

# Write completion stats to log
"Conversion completed at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath -Append
"Statistics:" | Out-File -FilePath $logPath -Append
"  Blocks converted: $($stats.blocksConverted)" | Out-File -FilePath $logPath -Append
"  Items converted: $($stats.itemsConverted)" | Out-File -FilePath $logPath -Append
"  Total files modified: $($stats.totalFilesModified)" | Out-File -FilePath $logPath -Append

# Output stats to console
Write-Host "`nGrass/Flowers to farming XP conversion completed!" -ForegroundColor Green
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  Blocks converted: $($stats.blocksConverted)" -ForegroundColor White
Write-Host "  Items converted: $($stats.itemsConverted)" -ForegroundColor White
Write-Host "  Total files modified: $($stats.totalFilesModified)" -ForegroundColor White
Write-Host "`nLog file saved to: $logPath" -ForegroundColor Yellow