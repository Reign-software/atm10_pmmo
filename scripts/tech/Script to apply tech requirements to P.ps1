# Script to apply tech requirements to PMMO JSON files based on progression plan
$progressionPlanPath = "d:\src\atm10_pmmo\scripts\tech\mod_progression_plan.json"
$dataPath = "d:\src\atm10_pmmo\atm_10_pack\src\main\resources\data\"
$logPath = "d:\src\atm10_pmmo\scripts\tech\tech_implementation_log.txt"

# Load progression plan
$progressionPlan = Get-Content -Path $progressionPlanPath -Raw | ConvertFrom-Json

# Initialize statistics
$stats = @{
    "modsProcessed" = 0
    "filesUpdated" = 0
    "blockFilesUpdated" = 0
    "itemFilesUpdated" = 0
}

# Start log file
"Tech implementation started at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath

# Process each mod in the progression plan
foreach ($modName in $progressionPlan.modPlans.PSObject.Properties.Name) {
    $modPlan = $progressionPlan.modPlans.$modName
    
    Write-Host "Processing $modName (Category: $($modPlan.category))" -ForegroundColor Cyan
    "Processing $modName (Category: $($modPlan.category))" | Out-File -FilePath $logPath -Append
    
    $modPmmoPath = Join-Path -Path $dataPath -ChildPath "$modName\pmmo"
    
    # Process blocks
    $blocksPath = Join-Path -Path $modPmmoPath -ChildPath "blocks"
    if (Test-Path $blocksPath) {
        $blockFiles = Get-ChildItem -Path $blocksPath -Filter "*.json"
        
        foreach ($blockFile in $blockFiles) {
            $blockName = $blockFile.BaseName
            
            # Skip if block isn't in the plan
            if (-not $modPlan.blocks.PSObject.Properties[$blockName]) {
                continue
            }
            
            $blockPlan = $modPlan.blocks.$blockName
            $techLevel = $blockPlan.techLevel
            
            Write-Host "  Updating $blockName (Tech Level: $techLevel)" -ForegroundColor Yellow
            "$blockName - Tech Level: $techLevel" | Out-File -FilePath $logPath -Append
            
            # Load the JSON
            $blockJson = Get-Content -Path $blockFile.FullName -Raw | ConvertFrom-Json
            $modified = $false
            
            # Calculate XP values (base 400 + 5 per tech level)
            $craftXp = 400 + ($techLevel * 5)
            
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
            
            # Add/update technology requirement for PLACE
            if (-not $blockJson.requirements.PLACE.PSObject.Properties["technology"] -or 
                $blockJson.requirements.PLACE.technology -ne $techLevel) {
                $blockJson.requirements.PLACE | Add-Member -NotePropertyName "technology" -NotePropertyValue $techLevel -Force
                $modified = $true
            }

            # Add/update technology requirement for BREAK
            if (-not $blockJson.requirements.BREAK.PSObject.Properties["technology"] -or 
                $blockJson.requirements.BREAK.technology -ne $techLevel) {
                $blockJson.requirements.BREAK | Add-Member -NotePropertyName "technology" -NotePropertyValue $techLevel -Force
                $modified = $true
            }

            # Add/update technology requirement for INTERACT (tech level - 100, minimum 0)
            $interactTechLevel = [Math]::Max($techLevel - 100, 0)

            # If interactTechLevel is 0, remove any existing technology requirement
            if ($interactTechLevel -eq 0) {
                if ($blockJson.requirements.INTERACT.PSObject.Properties["technology"]) {
                    $blockJson.requirements.INTERACT.PSObject.Properties.Remove("technology")
                    $modified = $true
                }
            } else {
                # Otherwise add/update with adjusted tech level
                if (-not $blockJson.requirements.INTERACT.PSObject.Properties["technology"] -or 
                    $blockJson.requirements.INTERACT.technology -ne $interactTechLevel) {
                    $blockJson.requirements.INTERACT | Add-Member -NotePropertyName "technology" -NotePropertyValue $interactTechLevel -Force
                    $modified = $true
                }
            }
            
            # Process XP values
            if (-not $blockJson.PSObject.Properties["xp_values"]) {
                $blockJson | Add-Member -NotePropertyName "xp_values" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            # Ensure CRAFT section exists
            if (-not $blockJson.xp_values.PSObject.Properties["CRAFT"]) {
                $blockJson.xp_values | Add-Member -NotePropertyName "CRAFT" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            # Add/update technology XP
            if (-not $blockJson.xp_values.CRAFT.PSObject.Properties["technology"] -or 
                $blockJson.xp_values.CRAFT.technology -ne $craftXp) {
                $blockJson.xp_values.CRAFT | Add-Member -NotePropertyName "technology" -NotePropertyValue $craftXp -Force
                $modified = $true
            }
            
            # Save changes if modified
            if ($modified) {
                $blockJson | ConvertTo-Json -Depth 10 | Set-Content -Path $blockFile.FullName
                $stats.filesUpdated++
                $stats.blockFilesUpdated++
            }
        }
    }
    
    # Process items
    $itemsPath = Join-Path -Path $modPmmoPath -ChildPath "items"
    if (Test-Path $itemsPath) {
        $itemFiles = Get-ChildItem -Path $itemsPath -Filter "*.json"
        
        foreach ($itemFile in $itemFiles) {
            $itemName = $itemFile.BaseName
            
            # Skip if item isn't in the plan
            if (-not $modPlan.items.PSObject.Properties[$itemName]) {
                continue
            }
            
            $itemPlan = $modPlan.items.$itemName
            $techLevel = $itemPlan.techLevel
            
            Write-Host "  Updating $itemName (Tech Level: $techLevel)" -ForegroundColor Yellow
            "$itemName - Tech Level: $techLevel" | Out-File -FilePath $logPath -Append
            
            # Load the JSON
            $itemJson = Get-Content -Path $itemFile.FullName -Raw | ConvertFrom-Json
            $modified = $false
            
            # Calculate XP values (base 400 + 5 per tech level)
            $craftXp = 400 + ($techLevel * 5)
            
            # Process requirements
            if (-not $itemJson.PSObject.Properties["requirements"]) {
                $itemJson | Add-Member -NotePropertyName "requirements" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            # Ensure required sections exist
            $requiredSections = @("PLACE", "BREAK", "INTERACT", "USE", "TOOL", "WEAPON")
            foreach ($section in $requiredSections) {
                if (-not $itemJson.requirements.PSObject.Properties[$section]) {
                    $itemJson.requirements | Add-Member -NotePropertyName $section -NotePropertyValue @{} -Force
                    $modified = $true
                }
            }
            
            # Add/update technology requirements
            
            # For PLACE
            if (-not $itemJson.requirements.PLACE.PSObject.Properties["technology"] -or 
                $itemJson.requirements.PLACE.technology -ne $techLevel) {
                $itemJson.requirements.PLACE | Add-Member -NotePropertyName "technology" -NotePropertyValue $techLevel -Force
                $modified = $true
            }
            
            # For USE
            if (-not $itemJson.requirements.USE.PSObject.Properties["technology"] -or 
                $itemJson.requirements.USE.technology -ne $techLevel) {
                $itemJson.requirements.USE | Add-Member -NotePropertyName "technology" -NotePropertyValue $techLevel -Force
                $modified = $true
            }
            
            # For TOOL and WEAPON (if it seems like it might be one)
            $isTool = $itemName -match "(axe|pickaxe|shovel|hoe|saw|hammer|drill|wrench|screwdriver)"
            $isWeapon = $itemName -match "(sword|bow|gun|wand|staff|weapon|dagger|mace|blade|arrow)"
            
            if ($isTool -and (-not $itemJson.requirements.TOOL.PSObject.Properties["technology"] -or 
                $itemJson.requirements.TOOL.technology -ne $techLevel)) {
                $itemJson.requirements.TOOL | Add-Member -NotePropertyName "technology" -NotePropertyValue $techLevel -Force
                $modified = $true
            }
            
            if ($isWeapon -and (-not $itemJson.requirements.WEAPON.PSObject.Properties["technology"] -or 
                $itemJson.requirements.WEAPON.technology -ne $techLevel)) {
                $itemJson.requirements.WEAPON | Add-Member -NotePropertyName "technology" -NotePropertyValue $techLevel -Force
                $modified = $true
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
            
            # Add/update technology XP
            if (-not $itemJson.xp_values.CRAFT.PSObject.Properties["technology"] -or 
                $itemJson.xp_values.CRAFT.technology -ne $craftXp) {
                $itemJson.xp_values.CRAFT | Add-Member -NotePropertyName "technology" -NotePropertyValue $craftXp -Force
                $modified = $true
            }
            
            # Save changes if modified
            if ($modified) {
                $itemJson | ConvertTo-Json -Depth 10 | Set-Content -Path $itemFile.FullName
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
Write-Host "`nImplementation completed!" -ForegroundColor Green
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  Mods processed: $($stats.modsProcessed)" -ForegroundColor White
Write-Host "  Total files updated: $($stats.filesUpdated)" -ForegroundColor White
Write-Host "  Block files updated: $($stats.blockFilesUpdated)" -ForegroundColor White
Write-Host "  Item files updated: $($stats.itemFilesUpdated)" -ForegroundColor White
Write-Host "`nLog file saved to: $logPath" -ForegroundColor Yellow