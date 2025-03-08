# Script to apply alchemy requirements to PMMO JSON files
$alchemyPlanPath = "d:\src\atm10_pmmo\scripts\alchemy\alchemy_progression_plan.json"
$dataPath = "d:\src\atm10_pmmo\atm_10_pack\src\main\resources\data\"
$logPath = "d:\src\atm10_pmmo\scripts\alchemy\alchemy_implementation_log.txt"

# Load alchemy plan
$alchemyPlan = Get-Content -Path $alchemyPlanPath -Raw | ConvertFrom-Json

# Initialize statistics
$stats = @{
    "modsProcessed" = 0
    "filesUpdated" = 0
    "blockFilesUpdated" = 0
    "itemFilesUpdated" = 0
}

# XP calculation formula
function Get-AlchemyXp {
    param([int]$alchemyLevel)
    # Base XP of 400 plus 5 XP per alchemy level
    return 400 + ($alchemyLevel * 5)
}

# Start log file
"Alchemy implementation started at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath
"Using XP formula: 400 + (alchemyLevel * 5)" | Out-File -FilePath $logPath -Append

# Process each mod in the alchemy plan
foreach ($modName in $alchemyPlan.modPlans.PSObject.Properties.Name) {
    $modPlan = $alchemyPlan.modPlans.$modName
    
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
            $alchemyLevel = $blockData.alchemyLevel
            $alchemyXp = Get-AlchemyXp -alchemyLevel $alchemyLevel
            
            Write-Host "  Updating $blockName (Alchemy Level: $alchemyLevel, XP: $alchemyXp)" -ForegroundColor Yellow
            "$blockName - Alchemy Level: $alchemyLevel, XP: $alchemyXp" | Out-File -FilePath $logPath -Append
            
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
            
            # Add/update alchemy requirement for PLACE and BREAK
            if (-not $blockJson.requirements.PLACE.PSObject.Properties["alchemy"] -or 
                $blockJson.requirements.PLACE.alchemy -ne $alchemyLevel) {
                $blockJson.requirements.PLACE | Add-Member -NotePropertyName "alchemy" -NotePropertyValue $alchemyLevel -Force
                $modified = $true
            }
            
            if (-not $blockJson.requirements.INTERACT.PSObject.Properties["alchemy"] -or 
                $blockJson.requirements.INTERACT.alchemy -ne $alchemyLevel) {
                $blockJson.requirements.INTERACT | Add-Member -NotePropertyName "alchemy" -NotePropertyValue $alchemyLevel -Force
                $modified = $true
            }

            if (-not $blockJson.requirements.INTERACT.PSObject.Properties["alchemy"] -or 
                $blockJson.requirements.INTERACT.alchemy -ne $alchemyLevel) {
                $blockJson.requirements.INTERACT | Add-Member -NotePropertyName "alchemy" -NotePropertyValue $alchemyLevel -Force
                $modified = $true
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
            
            # Add/update alchemy XP
            if (-not $blockJson.xp_values.CRAFT.PSObject.Properties["alchemy"] -or 
                $blockJson.xp_values.CRAFT.alchemy -ne $alchemyXp) {
                $blockJson.xp_values.CRAFT | Add-Member -NotePropertyName "alchemy" -NotePropertyValue $alchemyXp -Force
                $modified = $true
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
            $alchemyLevel = $itemData.alchemyLevel
            $alchemyXp = Get-AlchemyXp -alchemyLevel $alchemyLevel
            
            Write-Host "  Updating $itemName (Alchemy Level: $alchemyLevel, XP: $alchemyXp)" -ForegroundColor Yellow
            "$itemName - Alchemy Level: $alchemyLevel, XP: $alchemyXp" | Out-File -FilePath $logPath -Append
            
            # Load the JSON
            $itemJson = Get-Content -Path $itemFile -Raw | ConvertFrom-Json
            $modified = $false
            
            # Process requirements
            if (-not $itemJson.PSObject.Properties["requirements"]) {
                $itemJson | Add-Member -NotePropertyName "requirements" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            # Ensure required sections exist
            $requiredSections = @("USE", "INTERACT", "PLACE", "BREAK")
            foreach ($section in $requiredSections) {
                if (-not $itemJson.requirements.PSObject.Properties[$section]) {
                    $itemJson.requirements | Add-Member -NotePropertyName $section -NotePropertyValue @{} -Force
                    $modified = $true
                }
            }
            
            # Add/update alchemy requirements
            if (-not $itemJson.requirements.USE.PSObject.Properties["alchemy"] -or 
                $itemJson.requirements.USE.alchemy -ne $alchemyLevel) {
                $itemJson.requirements.USE | Add-Member -NotePropertyName "alchemy" -NotePropertyValue $alchemyLevel -Force
                $modified = $true
            }
            
            if (-not $itemJson.requirements.INTERACT.PSObject.Properties["alchemy"] -or 
                $itemJson.requirements.INTERACT.alchemy -ne $alchemyLevel) {
                $itemJson.requirements.INTERACT | Add-Member -NotePropertyName "alchemy" -NotePropertyValue $alchemyLevel -Force
                $modified = $true
            }
            
            if (-not $itemJson.requirements.PLACE.PSObject.Properties["alchemy"] -or 
                $itemJson.requirements.PLACE.alchemy -ne $alchemyLevel) {
                $itemJson.requirements.PLACE | Add-Member -NotePropertyName "alchemy" -NotePropertyValue $alchemyLevel -Force
                $modified = $true
            }

            if (-not $itemJson.requirements.BREAK.PSObject.Properties["alchemy"] -or 
                $itemJson.requirements.BREAK.alchemy -ne $alchemyLevel) {
                $itemJson.requirements.BREAK | Add-Member -NotePropertyName "alchemy" -NotePropertyValue $alchemyLevel -Force
                $modified = $true
            }
            
            # Process XP values
            if (-not $itemJson.PSObject.Properties["xp_values"]) {
                $itemJson | Add-Member -NotePropertyName "xp_values" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            
            # Add/update alchemy XP
            if (-not $itemJson.xp_values.CRAFT.PSObject.Properties["alchemy"] -or 
                $itemJson.xp_values.CRAFT.alchemy -ne $alchemyXp) {
                $itemJson.xp_values.CRAFT | Add-Member -NotePropertyName "alchemy" -NotePropertyValue $alchemyXp -Force
                $modified = $true
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
Write-Host "`nAlchemy implementation completed!" -ForegroundColor Green
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  Mods processed: $($stats.modsProcessed)" -ForegroundColor White
Write-Host "  Total files updated: $($stats.filesUpdated)" -ForegroundColor White
Write-Host "  Block files updated: $($stats.blockFilesUpdated)" -ForegroundColor White
Write-Host "  Item files updated: $($stats.itemFilesUpdated)" -ForegroundColor White
Write-Host "`nLog file saved to: $logPath" -ForegroundColor Yellow