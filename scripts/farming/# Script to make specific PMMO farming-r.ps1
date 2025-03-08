# Script to make specific PMMO farming-related adjustments
$dataPath = "d:\src\atm10_pmmo\atm_10_pack\src\main\resources\data\"
$logPath = "d:\src\atm10_pmmo\scripts\farming\farming_adjustments_log.txt"

# Initialize statistics
$stats = @{
    "grassBlocksUpdated" = 0
    "seedItemsUpdated" = 0
    "armorItemsUpdated" = 0
    "totalFilesModified" = 0
}

# Start log file
"Farming adjustments started at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath
"Tasks:" | Out-File -FilePath $logPath -Append
" - Change excavation to farming on grass blocks" | Out-File -FilePath $logPath -Append
" - Set farming XP=10 for seed items' BLOCK_PLACE action" | Out-File -FilePath $logPath -Append
" - Remove farming requirements from armor items" | Out-File -FilePath $logPath -Append

# Get all mod directories
$modDirs = Get-ChildItem -Path $dataPath -Directory

foreach ($modDir in $modDirs) {
    $modName = $modDir.Name
    $modPmmoPath = Join-Path -Path $modDir.FullName -ChildPath "pmmo"
    
    # Skip if no PMMO data
    if (-not (Test-Path $modPmmoPath)) {
        continue
    }
    
    # Process blocks - Task 1: Change excavation to farming on grass
    $blocksPath = Join-Path -Path $modPmmoPath -ChildPath "blocks"
    if (Test-Path $blocksPath) {
        # Find grass-like blocks using multiple patterns
        $grassBlockPatterns = @("*grass*", "*fern*", "*tall_grass*", "*foliage*", "*undergrowth*", "*weed*")
        $grassBlockFiles = @()
        
        foreach ($pattern in $grassBlockPatterns) {
            $grassBlockFiles += Get-ChildItem -Path $blocksPath -Filter $pattern
        }
        
        $grassBlockFiles = $grassBlockFiles | Sort-Object FullName -Unique
        
        foreach ($blockFile in $grassBlockFiles) {
            $blockName = $blockFile.BaseName
            Write-Host "Processing grass block: $blockName" -ForegroundColor Yellow
            
            # Load the JSON
            $blockJson = Get-Content -Path $blockFile.FullName -Raw | ConvertFrom-Json
            $modified = $false
            
            # Process xp_values - change excavation to farming
            if ($blockJson.PSObject.Properties["xp_values"]) {
                # BLOCK_BREAK section
                if ($blockJson.xp_values.PSObject.Properties["BLOCK_BREAK"]) {
                    if ($blockJson.xp_values.BLOCK_BREAK.PSObject.Properties["excavation"]) {
                        $excavationValue = $blockJson.xp_values.BLOCK_BREAK.excavation
                        
                        # Add or update farming value with excavation value
                        $blockJson.xp_values.BLOCK_BREAK | Add-Member -NotePropertyName "farming" -NotePropertyValue $excavationValue -Force
                        
                        # Remove excavation value
                        $blockJson.xp_values.BLOCK_BREAK.PSObject.Properties.Remove("excavation")
                        $modified = $true
                        
                        "$blockName - Changed BLOCK_BREAK XP from excavation to farming: $excavationValue" | Out-File -FilePath $logPath -Append
                    }
                }
                
                # BREAK_SPEED section
                if ($blockJson.xp_values.PSObject.Properties["BREAK_SPEED"]) {
                    if ($blockJson.xp_values.BREAK_SPEED.PSObject.Properties["excavation"]) {
                        $excavationValue = $blockJson.xp_values.BREAK_SPEED.excavation
                        
                        # Add or update farming value with excavation value
                        $blockJson.xp_values.BREAK_SPEED | Add-Member -NotePropertyName "farming" -NotePropertyValue $excavationValue -Force
                        
                        # Remove excavation value
                        $blockJson.xp_values.BREAK_SPEED.PSObject.Properties.Remove("excavation")
                        $modified = $true
                        
                        "$blockName - Changed BREAK_SPEED XP from excavation to farming: $excavationValue" | Out-File -FilePath $logPath -Append
                    }
                }
            }
            
            # Process requirements - change excavation to farming
            if ($blockJson.PSObject.Properties["requirements"]) {
                # BREAK section
                if ($blockJson.requirements.PSObject.Properties["BREAK"]) {
                    if ($blockJson.requirements.BREAK.PSObject.Properties["excavation"]) {
                        $excavationValue = $blockJson.requirements.BREAK.excavation
                        
                        # Add or update farming value with excavation value
                        $blockJson.requirements.BREAK | Add-Member -NotePropertyName "farming" -NotePropertyValue $excavationValue -Force
                        
                        # Remove excavation value
                        $blockJson.requirements.BREAK.PSObject.Properties.Remove("excavation")
                        $modified = $true
                        
                        "$blockName - Changed BREAK requirement from excavation to farming: $excavationValue" | Out-File -FilePath $logPath -Append
                    }
                }
            }
            
            # Save changes if modified
            if ($modified) {
                $blockJson | ConvertTo-Json -Depth 10 | Set-Content -Path $blockFile.FullName -Encoding UTF8
                $stats.grassBlocksUpdated++
                $stats.totalFilesModified++
                
                Write-Host "  Updated grass block: $blockName" -ForegroundColor Green
            }
        }
    }
    
    # Process items - Task 2 & 3: Update seeds and remove farming from armor
    $itemsPath = Join-Path -Path $modPmmoPath -ChildPath "items"
    if (Test-Path $itemsPath) {
        # Task 2: Set farming XP=10 for seed BLOCK_PLACE
        # Find seed-like items using multiple patterns
        $seedItemPatterns = @("*seed*", "*crop*", "*sapling*", "*wheat*", "*beans*", "*berry*", "*plant*", "*spore*")
        $seedItemFiles = @()
        
        foreach ($pattern in $seedItemPatterns) {
            $seedItemFiles += Get-ChildItem -Path $itemsPath -Filter $pattern
        }
        
        $seedItemFiles = $seedItemFiles | Sort-Object FullName -Unique
        
        foreach ($itemFile in $seedItemFiles) {
            $itemName = $itemFile.BaseName
            Write-Host "Processing seed item: $itemName" -ForegroundColor Yellow
            
            # Load the JSON
            $itemJson = Get-Content -Path $itemFile.FullName -Raw | ConvertFrom-Json
            $modified = $false
            
            # Process xp_values for BLOCK_PLACE
            if (-not $itemJson.PSObject.Properties["xp_values"]) {
                $itemJson | Add-Member -NotePropertyName "xp_values" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            if (-not $itemJson.xp_values.PSObject.Properties["BLOCK_PLACE"]) {
                $itemJson.xp_values | Add-Member -NotePropertyName "BLOCK_PLACE" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            # Set farming XP to 10 for BLOCK_PLACE
            if (-not $itemJson.xp_values.BLOCK_PLACE.PSObject.Properties["farming"] -or 
                $itemJson.xp_values.BLOCK_PLACE.farming -ne 10) {
                $itemJson.xp_values.BLOCK_PLACE | Add-Member -NotePropertyName "farming" -NotePropertyValue 10 -Force
                $modified = $true
                
                "$itemName - Set BLOCK_PLACE farming XP to 10" | Out-File -FilePath $logPath -Append
            }
            
            # Save changes if modified
            if ($modified) {
                $itemJson | ConvertTo-Json -Depth 10 | Set-Content -Path $itemFile.FullName -Encoding UTF8
                $stats.seedItemsUpdated++
                $stats.totalFilesModified++
                
                Write-Host "  Updated seed item: $itemName" -ForegroundColor Green
            }
        }
        
        # Task 3: Remove farming requirements from armor items
        $armorKeywords = @("helmet", "chestplate", "leggings", "boots", "armor", "_cap", "_tunic", "_pants", "_boots", 
                           "cuirass", "greaves", "sabatons", "helm", "_plate", "gauntlet", "gloves")
        $armorFiles = @()
        
        # Find armor items using multiple filters
        foreach ($keyword in $armorKeywords) {
            $armorFiles += Get-ChildItem -Path $itemsPath -Filter "*$keyword*.json"
        }
        
        # Remove duplicates
        $armorFiles = $armorFiles | Sort-Object FullName -Unique
        
        foreach ($itemFile in $armorFiles) {
            $itemName = $itemFile.BaseName
            Write-Host "Processing armor item: $itemName" -ForegroundColor Yellow
            
            # Load the JSON
            $itemJson = Get-Content -Path $itemFile.FullName -Raw | ConvertFrom-Json
            $modified = $false
            
            # Check if there are farming requirements
            if ($itemJson.PSObject.Properties["requirements"]) {
                $requirementSections = @("WEAR", "USE", "BREAK", "PLACE", "TOOL", "WEAPON")
                
                foreach ($section in $requirementSections) {
                    if ($itemJson.requirements.PSObject.Properties[$section]) {
                        if ($itemJson.requirements.$section.PSObject.Properties["farming"]) {
                            $farmingValue = $itemJson.requirements.$section.farming
                            
                            # Remove farming requirement
                            $itemJson.requirements.$section.PSObject.Properties.Remove("farming")
                            $modified = $true
                            
                            "$itemName - Removed $section farming requirement: $farmingValue" | Out-File -FilePath $logPath -Append
                        }
                    }
                }
            }
            
            # Also remove farming bonuses if present
            if ($itemJson.PSObject.Properties["bonuses"]) {
                if ($itemJson.bonuses.PSObject.Properties["WORN"]) {
                    if ($itemJson.bonuses.WORN.PSObject.Properties["farming"]) {
                        $farmingValue = $itemJson.bonuses.WORN.farming
                        
                        # Remove farming bonus
                        $itemJson.bonuses.WORN.PSObject.Properties.Remove("farming")
                        $modified = $true
                        
                        "$itemName - Removed WORN farming bonus: $farmingValue" | Out-File -FilePath $logPath -Append
                    }
                }
                
                if ($itemJson.bonuses.PSObject.Properties["HELD"]) {
                    if ($itemJson.bonuses.HELD.PSObject.Properties["farming"]) {
                        $farmingValue = $itemJson.bonuses.HELD.farming
                        
                        # Remove farming bonus
                        $itemJson.bonuses.HELD.PSObject.Properties.Remove("farming")
                        $modified = $true
                        
                        "$itemName - Removed HELD farming bonus: $farmingValue" | Out-File -FilePath $logPath -Append
                    }
                }
            }
            
            # Save changes if modified
            if ($modified) {
                $itemJson | ConvertTo-Json -Depth 10 | Set-Content -Path $itemFile.FullName -Encoding UTF8
                $stats.armorItemsUpdated++
                $stats.totalFilesModified++
                
                Write-Host "  Updated armor item: $itemName" -ForegroundColor Green
            }
        }
    }
}

# Write completion stats to log
"Adjustments completed at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath -Append
"Statistics:" | Out-File -FilePath $logPath -Append
"  Grass blocks updated: $($stats.grassBlocksUpdated)" | Out-File -FilePath $logPath -Append
"  Seed items updated: $($stats.seedItemsUpdated)" | Out-File -FilePath $logPath -Append
"  Armor items updated: $($stats.armorItemsUpdated)" | Out-File -FilePath $logPath -Append
"  Total files modified: $($stats.totalFilesModified)" | Out-File -FilePath $logPath -Append

# Output stats to console
Write-Host "`nFarming adjustments completed!" -ForegroundColor Green
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  Grass blocks updated: $($stats.grassBlocksUpdated)" -ForegroundColor White
Write-Host "  Seed items updated: $($stats.seedItemsUpdated)" -ForegroundColor White
Write-Host "  Armor items updated: $($stats.armorItemsUpdated)" -ForegroundColor White
Write-Host "  Total files modified: $($stats.totalFilesModified)" -ForegroundColor White
Write-Host "`nLog file saved to: $logPath" -ForegroundColor Yellow