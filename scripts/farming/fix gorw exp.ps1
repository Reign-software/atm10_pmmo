# Script to add farming XP for GROW and ACTIVATE_BLOCK events
$dataPath = "d:\src\atm10_pmmo\atm_10_pack\src\main\resources\data\"
$logPath = "d:\src\atm10_pmmo\scripts\farming_events_xp_log.txt"

# Initialize statistics
$stats = @{
    "blocksUpdated" = 0
    "growEventsAdded" = 0
    "activateEventsAdded" = 0
    "growEventsIncreased" = 0
    "totalFilesModified" = 0
}

# Start log file
"Farming Events XP Update started at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath
"Tasks:" | Out-File -FilePath $logPath -Append
" - Add/ensure GROW events have at least 40 farming XP" | Out-File -FilePath $logPath -Append
" - Add farming XP for ACTIVATE_BLOCK events for harvesting" | Out-File -FilePath $logPath -Append

# Get all mod directories
$modDirs = Get-ChildItem -Path $dataPath -Directory

foreach ($modDir in $modDirs) {
    $modName = $modDir.Name
    $modPmmoPath = Join-Path -Path $modDir.FullName -ChildPath "pmmo"
    
    # Skip if no PMMO data
    if (-not (Test-Path $modPmmoPath)) {
        continue
    }
    
    # Process blocks
    $blocksPath = Join-Path -Path $modPmmoPath -ChildPath "blocks"
    if (Test-Path $blocksPath) {
        $blockFiles = Get-ChildItem -Path $blocksPath -Filter "*.json"
        
        foreach ($blockFile in $blockFiles) {
            $blockName = $blockFile.BaseName
            $modified = $false
            
            # Load the JSON
            $blockJson = Get-Content -Path $blockFile.FullName -Raw | ConvertFrom-Json
            
            # Only process blocks that have farming XP for BLOCK_BREAK
            if ($blockJson.PSObject.Properties["xp_values"] -and 
                $blockJson.xp_values.PSObject.Properties["BLOCK_BREAK"] -and 
                $blockJson.xp_values.BLOCK_BREAK.PSObject.Properties["farming"]) {
                
                $blockBreakFarmingXp = $blockJson.xp_values.BLOCK_BREAK.farming
                
                # Determine if this is likely a crop or plant block that should have events
                $isCropOrPlant = $false
                $cropPatterns = @(
                    "*crop*", "*plant*", "*flower*", "*sapling*", "*seed*", 
                    "*berry*", "*fruit*", "*vegetable*", "*mushroom*", "*fungus*",
                    "*sprout*", "*blossom*", "*bloom*", "*garden*", "*farm*"
                )
                foreach ($pattern in $cropPatterns) {
                    if ($blockName -like $pattern) {
                        $isCropOrPlant = $true
                        break
                    }
                }
                
                # Special cases for mod-specific crops
                if ($modName -eq "mysticalagriculture" -or 
                    $modName -eq "mystical_agriculture" -or 
                    $modName -eq "pamhc2crops" -or 
                    $modName -eq "croparia" -or
                    $modName -eq "farmersdelight" -or
                    $modName -eq "simplefarming") {
                    $isCropOrPlant = $true
                }
                
                # Only proceed if this is likely a crop/plant
                if ($isCropOrPlant) {
                    Write-Host "Processing crop/plant: $modName : $blockName" -ForegroundColor Cyan
                    
                    # Calculate XP values - make them proportional to BLOCK_BREAK XP
                    # GROW event should be at least 40 XP or 5x BLOCK_BREAK XP
                    $growXp = [Math]::Max(40, $blockBreakFarmingXp * 5)
                    
                    # ACTIVATE_BLOCK should be same as BLOCK_BREAK for harvesting
                    $activateXp = $blockBreakFarmingXp
                    
                    # Ensure GROW event has farming XP
                    if (-not $blockJson.xp_values.PSObject.Properties["GROW"]) {
                        $blockJson.xp_values | Add-Member -NotePropertyName "GROW" -NotePropertyValue @{
                            "farming" = $growXp
                        } -Force
                        $modified = $true
                        $stats.growEventsAdded++
                        
                        "$modName : $blockName - Added GROW farming XP of $growXp" | Out-File -FilePath $logPath -Append
                    }
                    else {
                        if (-not $blockJson.xp_values.GROW.PSObject.Properties["farming"]) {
                            $blockJson.xp_values.GROW | Add-Member -NotePropertyName "farming" -NotePropertyValue $growXp -Force
                            $modified = $true
                            $stats.growEventsAdded++
                            
                            "$modName : $blockName - Added GROW farming XP of $growXp" | Out-File -FilePath $logPath -Append
                        }
                        else {
                            # Increase if less than minimum
                            $currentGrowXp = $blockJson.xp_values.GROW.farming
                            if ($currentGrowXp -lt 40) {
                                $blockJson.xp_values.GROW | Add-Member -NotePropertyName "farming" -NotePropertyValue $growXp -Force
                                $modified = $true
                                $stats.growEventsIncreased++
                                
                                "$modName : $blockName - Increased GROW farming XP from $currentGrowXp to $growXp" | Out-File -FilePath $logPath -Append
                            }
                        }
                    }
                    
                    # Ensure ACTIVATE_BLOCK event has farming XP
                    if (-not $blockJson.xp_values.PSObject.Properties["ACTIVATE_BLOCK"]) {
                        $blockJson.xp_values | Add-Member -NotePropertyName "ACTIVATE_BLOCK" -NotePropertyValue @{
                            "farming" = $activateXp
                        } -Force
                        $modified = $true
                        $stats.activateEventsAdded++
                        
                        "$modName : $blockName - Added ACTIVATE_BLOCK farming XP of $activateXp" | Out-File -FilePath $logPath -Append
                    }
                    else {
                        if (-not $blockJson.xp_values.ACTIVATE_BLOCK.PSObject.Properties["farming"]) {
                            $blockJson.xp_values.ACTIVATE_BLOCK | Add-Member -NotePropertyName "farming" -NotePropertyValue $activateXp -Force
                            $modified = $true
                            $stats.activateEventsAdded++
                            
                            "$modName : $blockName - Added ACTIVATE_BLOCK farming XP of $activateXp" | Out-File -FilePath $logPath -Append
                        }
                    }
                    
                    # Save changes if modified
                    if ($modified) {
                        $blockJson | ConvertTo-Json -Depth 10 | Set-Content -Path $blockFile.FullName -Encoding UTF8
                        $stats.blocksUpdated++
                        $stats.totalFilesModified++
                        
                        Write-Host "  Updated block: $modName : $blockName" -ForegroundColor Green
                    }
                }
            }
        }
    }
}

# Write completion stats to log
"Farming Events XP Update completed at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath -Append
"Statistics:" | Out-File -FilePath $logPath -Append
"  Blocks updated: $($stats.blocksUpdated)" | Out-File -FilePath $logPath -Append
"  GROW events added: $($stats.growEventsAdded)" | Out-File -FilePath $logPath -Append
"  ACTIVATE_BLOCK events added: $($stats.activateEventsAdded)" | Out-File -FilePath $logPath -Append
"  GROW events increased to minimum: $($stats.growEventsIncreased)" | Out-File -FilePath $logPath -Append
"  Total files modified: $($stats.totalFilesModified)" | Out-File -FilePath $logPath -Append

# Output stats to console
Write-Host "`nFarming Events XP Update completed!" -ForegroundColor Green
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  Blocks updated: $($stats.blocksUpdated)" -ForegroundColor White
Write-Host "  GROW events added: $($stats.growEventsAdded)" -ForegroundColor White
Write-Host "  ACTIVATE_BLOCK events added: $($stats.activateEventsAdded)" -ForegroundColor White
Write-Host "  GROW events increased to minimum: $($stats.growEventsIncreased)" -ForegroundColor White
Write-Host "  Total files modified: $($stats.totalFilesModified)" -ForegroundColor White
Write-Host "`nLog file saved to: $logPath" -ForegroundColor Yellow