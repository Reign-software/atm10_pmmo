# Script to apply farming requirements to PMMO JSON files
$farmingPlanPath = "d:\src\atm10_pmmo\scripts\farming\farming_progression_plan.json"
$dataPath = "d:\src\atm10_pmmo\atm_10_pack\src\main\resources\data\"
$logPath = "d:\src\atm10_pmmo\scripts\farming\farming_implementation_log.txt"

# Load farming plan
$farmingPlan = Get-Content -Path $farmingPlanPath -Raw | ConvertFrom-Json

# Initialize statistics
$stats = @{
    "modsProcessed" = 0
    "filesUpdated" = 0
    "blockFilesUpdated" = 0
    "itemFilesUpdated" = 0
}

# XP calculation formula
function Get-FarmingXp {
    param([int]$farmingLevel)
    # Base XP of 20 plus 5 XP per farming level
    return 20 + ($farmingLevel * 5)
}

# Start log file
"Farming implementation started at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath
"Using XP formula: 20 + (farmingLevel * 5)" | Out-File -FilePath $logPath -Append

# Process each mod in the farming plan
foreach ($modName in $farmingPlan.modPlans.PSObject.Properties.Name) {
    $modPlan = $farmingPlan.modPlans.$modName
    
    Write-Host "Processing $modName" -ForegroundColor Cyan
    "Processing $modName" | Out-File -FilePath $logPath -Append
    
    $modPmmoPath = Join-Path -Path $dataPath -ChildPath "$modName\pmmo"
    
    # Process blocks
    $blocksPath = Join-Path -Path $modPmmoPath -ChildPath "blocks"
    if (Test-Path $blocksPath) {
        foreach ($blockName in $modPlan.blocks.PSObject.Properties.Name) {
            $blockFile = Join-Path -Path $blocksPath -ChildPath "$blockName.json"
            
            # Skip if file doesn't exist
            if (-not (Test-Path $blockFile)) {
                continue
            }
            
            $blockData = $modPlan.blocks.$blockName
            $farmingLevel = $blockData.farmingLevel
            $farmingXp = Get-FarmingXp -farmingLevel $farmingLevel
            
            Write-Host "  Updating $blockName (Farming Level: $farmingLevel, XP: $farmingXp)" -ForegroundColor Yellow
            "$blockName - Farming Level: $farmingLevel, XP: $farmingXp" | Out-File -FilePath $logPath -Append
            
            # Load the JSON
            $blockJson = Get-Content -Path $blockFile -Raw | ConvertFrom-Json
            $modified = $false
            
            # Process requirements
            if (-not $blockJson.PSObject.Properties["requirements"]) {
                $blockJson | Add-Member -NotePropertyName "requirements" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            # Ensure required sections exist
            $requiredSections = @("PLACE", "BREAK", "INTERACT")
            foreach ($section in $requiredSections) {
                if (-not $blockJson.requirements.PSObject.Properties[$section]) {
                    $blockJson.requirements | Add-Member -NotePropertyName $section -NotePropertyValue @{} -Force
                    $modified = $true
                }
            }
            
            # Add/update or remove farming requirement for PLACE and BREAK based on farming level
            if ($farmingLevel -gt 0) {
                # Add/update farming requirement for PLACE
                if (-not $blockJson.requirements.PLACE.PSObject.Properties["farming"] -or 
                    $blockJson.requirements.PLACE.farming -ne $farmingLevel) {
                    $blockJson.requirements.PLACE | Add-Member -NotePropertyName "farming" -NotePropertyValue $farmingLevel -Force
                    $modified = $true
                }
                
                # Add/update farming requirement for BREAK
                if (-not $blockJson.requirements.BREAK.PSObject.Properties["farming"] -or 
                    $blockJson.requirements.BREAK.farming -ne $farmingLevel) {
                    $blockJson.requirements.BREAK | Add-Member -NotePropertyName "farming" -NotePropertyValue $farmingLevel -Force
                    $modified = $true
                }
            }
            else {
                # Remove farming requirement if it exists and farming level is 0
                if ($blockJson.requirements.PLACE.PSObject.Properties["farming"]) {
                    $blockJson.requirements.PLACE.PSObject.Properties.Remove("farming")
                    $modified = $true
                }
                
                if ($blockJson.requirements.BREAK.PSObject.Properties["farming"]) {
                    $blockJson.requirements.BREAK.PSObject.Properties.Remove("farming")
                    $modified = $true
                }
            }
            
            # Process XP values
            if (-not $blockJson.PSObject.Properties["xp_values"]) {
                $blockJson | Add-Member -NotePropertyName "xp_values" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            # Ensure BLOCK_BREAK and CRAFT sections exist in xp_values
            if (-not $blockJson.xp_values.PSObject.Properties["BLOCK_BREAK"]) {
                $blockJson.xp_values | Add-Member -NotePropertyName "BLOCK_BREAK" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            if (-not $blockJson.xp_values.PSObject.Properties["CRAFT"]) {
                $blockJson.xp_values | Add-Member -NotePropertyName "CRAFT" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            # Ensure GROW section for crops if applicable
            $isCrop = $blockName -like "*crop*" -or $blockName -like "*sapling*" -or 
                     $blockName -like "*seed*" -or $blockName -like "*plant*" -or
                     $blockName -like "*sprout*" -or $blockName -like "*bloom*"
                     
            if ($isCrop -and -not $blockJson.xp_values.PSObject.Properties["GROW"]) {
                $blockJson.xp_values | Add-Member -NotePropertyName "GROW" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            # Add/update farming XP
            if (-not $blockJson.xp_values.BLOCK_BREAK.PSObject.Properties["farming"] -or 
                $blockJson.xp_values.BLOCK_BREAK.farming -ne [Math]::Round($farmingXp / 5)) {
                $blockJson.xp_values.BLOCK_BREAK | Add-Member -NotePropertyName "farming" -NotePropertyValue ([Math]::Round($farmingXp / 5)) -Force
                $modified = $true
            }
            
            if (-not $blockJson.xp_values.CRAFT.PSObject.Properties["farming"] -or 
                $blockJson.xp_values.CRAFT.farming -ne $farmingXp) {
                $blockJson.xp_values.CRAFT | Add-Member -NotePropertyName "farming" -NotePropertyValue $farmingXp -Force
                $modified = $true
            }
            
            # Add farming XP for growing if it's a crop
            if ($isCrop) {
                if (-not $blockJson.xp_values.GROW.PSObject.Properties["farming"] -or 
                    $blockJson.xp_values.GROW.farming -ne $farmingXp) {
                    $blockJson.xp_values.GROW | Add-Member -NotePropertyName "farming" -NotePropertyValue $farmingXp -Force
                    $modified = $true
                }
            }
            
            # Save changes if modified
            if ($modified) {
                $blockJson | ConvertTo-Json -Depth 10 | Set-Content -Path $blockFile -Encoding UTF8
                $stats.filesUpdated++
                $stats.blockFilesUpdated++
            }
        }
    }
    
    # Process items
    $itemsPath = Join-Path -Path $modPmmoPath -ChildPath "items"
    if (Test-Path $itemsPath) {
        foreach ($itemName in $modPlan.items.PSObject.Properties.Name) {
            $itemFile = Join-Path -Path $itemsPath -ChildPath "$itemName.json"
            
            # Skip if file doesn't exist
            if (-not (Test-Path $itemFile)) {
                continue
            }
            
            $itemData = $modPlan.items.$itemName
            $farmingLevel = $itemData.farmingLevel
            $farmingXp = Get-FarmingXp -farmingLevel $farmingLevel
            
            Write-Host "  Updating $itemName (Farming Level: $farmingLevel, XP: $farmingXp)" -ForegroundColor Yellow
            "$itemName - Farming Level: $farmingLevel, XP: $farmingXp" | Out-File -FilePath $logPath -Append
            
            # Load the JSON
            $itemJson = Get-Content -Path $itemFile -Raw | ConvertFrom-Json
            $modified = $false
            
            # Process requirements
            if (-not $itemJson.PSObject.Properties["requirements"]) {
                $itemJson | Add-Member -NotePropertyName "requirements" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            # Check if item is likely a farming tool
            $isFarmingTool = $itemName -like "*_hoe*" -or $itemName -like "*harvester*" -or 
                            $itemName -like "*scythe*" -or $itemName -like "*watering*" -or
                            $itemName -like "*fertilizer*" -or $itemName -like "*seed*" -or
                            $itemName -like "*planter*"
            
            # Ensure required sections exist
            $requiredSections = @("USE", "PLACE", "BREAK")
            if ($isFarmingTool) {
                $requiredSections += "TOOL"
            }
            
            foreach ($section in $requiredSections) {
                if (-not $itemJson.requirements.PSObject.Properties[$section]) {
                    $itemJson.requirements | Add-Member -NotePropertyName $section -NotePropertyValue @{} -Force
                    $modified = $true
                }
            }
            
            if ($farmingLevel -gt 0) {
                # Add/update farming requirements for PLACE
                if (-not $itemJson.requirements.PLACE.PSObject.Properties["farming"] -or 
                    $itemJson.requirements.PLACE.farming -ne $farmingLevel) {
                    $itemJson.requirements.PLACE | Add-Member -NotePropertyName "farming" -NotePropertyValue $farmingLevel -Force
                    $modified = $true
                }

                # Add/update farming requirements for BREAK
                if (-not $itemJson.requirements.BREAK.PSObject.Properties["farming"] -or 
                    $itemJson.requirements.BREAK.farming -ne $farmingLevel) {
                    $itemJson.requirements.BREAK | Add-Member -NotePropertyName "farming" -NotePropertyValue $farmingLevel -Force
                    $modified = $true
                }

                # Add/update farming requirements for USE
                if (-not $itemJson.requirements.USE.PSObject.Properties["farming"] -or 
                    $itemJson.requirements.USE.farming -ne $farmingLevel) {
                    $itemJson.requirements.USE | Add-Member -NotePropertyName "farming" -NotePropertyValue $farmingLevel -Force
                    $modified = $true
                }
            
            
                # Add farming tool requirement if it's a farming tool
                if ($isFarmingTool) {
                    if (-not $itemJson.requirements.TOOL.PSObject.Properties["farming"] -or 
                        $itemJson.requirements.TOOL.farming -ne $farmingLevel) {
                        $itemJson.requirements.TOOL | Add-Member -NotePropertyName "farming" -NotePropertyValue $farmingLevel -Force
                        $modified = $true
                    }
                }
            }
            
            # Process XP values
            if (-not $itemJson.PSObject.Properties["xp_values"]) {
                $itemJson | Add-Member -NotePropertyName "xp_values" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            # Ensure CRAFT section exists
            if (-not $itemJson.xp_values.PSObject.Properties["CRAFT"]) {
                $itemJson.xp_values | Add-Member -NotePropertyName "CRAFT" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            # Add/update farming XP for crafting
            if (-not $itemJson.xp_values.CRAFT.PSObject.Properties["farming"] -or 
                $itemJson.xp_values.CRAFT.farming -ne $farmingXp) {
                $itemJson.xp_values.CRAFT | Add-Member -NotePropertyName "farming" -NotePropertyValue $farmingXp -Force
                $modified = $true
            }
            
            # If it's a farming tool, also add XP for breaking speed
            if ($isFarmingTool) {
                # Ensure BREAK_SPEED section exists
                if (-not $itemJson.xp_values.PSObject.Properties["TOOL_BREAKING"]) {
                    $itemJson.xp_values | Add-Member -NotePropertyName "TOOL_BREAKING" -NotePropertyValue @{} -Force
                    $modified = $true
                }
                
                # Add farming XP for breaking speed
                if (-not $itemJson.xp_values.TOOL_BREAKING.PSObject.Properties["farming"] -or 
                    $itemJson.xp_values.TOOL_BREAKING.farming -ne [Math]::Round($farmingXp / 10)) {
                    $itemJson.xp_values.TOOL_BREAKING | Add-Member -NotePropertyName "farming" -NotePropertyValue ([Math]::Round($farmingXp / 10)) -Force
                    $modified = $true
                }
            }
            
            # Save changes if modified
            if ($modified) {
                $itemJson | ConvertTo-Json -Depth 10 | Set-Content -Path $itemFile -Encoding UTF8
                $stats.filesUpdated++
                $stats.itemFilesUpdated++
            }
        }
    }
    
    $stats.modsProcessed++
}

# Write completion stats to log
"Implementation completed at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath -Append
"Statistics:" | Out-File -FilePath $logPath -Append
"  Mods processed: $($stats.modsProcessed)" | Out-File -FilePath $logPath -Append
"  Total files updated: $($stats.filesUpdated)" | Out-File -FilePath $logPath -Append
"  Block files updated: $($stats.blockFilesUpdated)" | Out-File -FilePath $logPath -Append
"  Item files updated: $($stats.itemFilesUpdated)" | Out-File -FilePath $logPath -Append

# Output stats to console
Write-Host "`nFarming implementation completed!" -ForegroundColor Green
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  Mods processed: $($stats.modsProcessed)" -ForegroundColor White
Write-Host "  Total files updated: $($stats.filesUpdated)" -ForegroundColor White
Write-Host "  Block files updated: $($stats.blockFilesUpdated)" -ForegroundColor White
Write-Host "  Item files updated: $($stats.itemFilesUpdated)" -ForegroundColor White
Write-Host "`nLog file saved to: $logPath" -ForegroundColor Yellow