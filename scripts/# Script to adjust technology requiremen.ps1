# Script to adjust technology requirements for Sophisticated Storage and Backpacks
$dataPath = "d:\src\atm10_pmmo\atm_10_pack\src\main\resources\data\"
$logPath = "d:\src\atm10_pmmo\scripts\sophisticated_storage_adjustments_log.txt"

# Initialize statistics
$stats = @{
    "itemsAdjusted" = 0
    "blocksAdjusted" = 0
    "totalFilesModified" = 0
}

# Start log file
"Sophisticated Storage & Backpacks adjustment started at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath
"Task: Adjust technology requirements to range from 0 to 150" | Out-File -FilePath $logPath -Append

# Define tier system based on patterns
$tierPatterns = @{
    # Tier 0 - Basic (0 requirement)
    0 = @("wooden_", "basic_", "normal_", "simple_", "copper_")
    
    # Tier 1 - Limited Tier 1 (25 requirement)
    1 = @("limited_barrel_1", "limited_chest_1", "limited_backpack", "iron_")
    
    # Tier 2 - Limited Tier 2 (50 requirement)
    2 = @("limited_barrel_2", "limited_chest_2", "gold_")
    
    # Tier 3 - Limited Tier 3 (75 requirement)
    3 = @("limited_barrel_3", "limited_chest_3", "diamond_")
    
    # Tier 4 - Limited Tier 4 (100 requirement)
    4 = @("limited_barrel_4", "limited_chest_4", "netherite_")
    
    # Tier 5 - Special upgrades (125 requirement)
    5 = @("_upgrade_", "_filter_", "_controller_", "advanced_")
    
    # Tier 6 - End game variants (150 requirement)
    6 = @("shulker_box", "ender_", "ultimate_", "advanced_netherite_")
}

# Calculate values based on tier
function Get-TechnologyValues {
    param (
        [int]$tier
    )
    
    # Calculate requirements and XP values based on tier
    $requirementValue = $tier * 25  # 0, 25, 50, 75, 100, 125, 150
    $craftXpValue = 50 + ($requirementValue * 12)  # 0, 50, 100, 150, 200, 250, 300
    $breakXpValue = 10 + ($requirementValue * 0.25)  # 0, 6.25, 12.5, 18.75, 25, 31.25, 37.5
    
    return @{
        "requirement" = $requirementValue
        "craftXp" = $craftXpValue
        "breakXp" = $breakXpValue
    }
}

# Function to determine tier based on name
function Get-ItemTier {
    param (
        [string]$name
    )
    
    # Default to tier 0
    $foundTier = 0
    
    # Check each tier pattern
    for ($i = 6; $i -ge 0; $i--) {
        foreach ($pattern in $tierPatterns[$i]) {
            if ($name -like "*$pattern*") {
                return $i
            }
        }
    }
    
    return $foundTier
}

# Process mods
$targetMods = @("sophisticatedstorage", "sophisticatedbackpacks")

foreach ($modName in $targetMods) {
    $modPmmoPath = Join-Path -Path $dataPath -ChildPath "$modName\pmmo"
    
    # Skip if no PMMO data
    if (-not (Test-Path $modPmmoPath)) {
        Write-Host "No PMMO data found for $modName" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "Processing $modName..." -ForegroundColor Cyan
    "$modName processing started" | Out-File -FilePath $logPath -Append
    
    # Process blocks
    $blocksPath = Join-Path -Path $modPmmoPath -ChildPath "blocks"
    if (Test-Path $blocksPath) {
        $blockFiles = Get-ChildItem -Path $blocksPath -Filter "*.json"
        
        foreach ($blockFile in $blockFiles) {
            $blockName = $blockFile.BaseName
            Write-Host "  Processing block: $blockName" -ForegroundColor Yellow
            
            # Determine tier and values
            $tier = Get-ItemTier -name $blockName
            $values = Get-TechnologyValues -tier $tier
            
            # Load the JSON
            $blockJson = Get-Content -Path $blockFile.FullName -Raw | ConvertFrom-Json
            $modified = $false
            
            # Update requirements
            if ($blockJson.PSObject.Properties["requirements"]) {
                # Update PLACE requirement
                if ($blockJson.requirements.PSObject.Properties["PLACE"]) {
                    if ($blockJson.requirements.PLACE.PSObject.Properties["technology"] -or 
                        $values.requirement -gt 0) {
                        $blockJson.requirements.PLACE | Add-Member -NotePropertyName "technology" -NotePropertyValue $values.requirement -Force
                        $modified = $true
                    }
                }
                
                # Update BREAK requirement
                if ($blockJson.requirements.PSObject.Properties["BREAK"]) {
                    if ($blockJson.requirements.BREAK.PSObject.Properties["technology"] -or 
                        $values.requirement -gt 0) {
                        $blockJson.requirements.BREAK | Add-Member -NotePropertyName "technology" -NotePropertyValue $values.requirement -Force
                        $modified = $true
                    }
                }
                
                # Ensure INTERACT is empty (following your previous script's logic)
                if ($blockJson.requirements.PSObject.Properties["INTERACT"]) {
                    if (($blockJson.requirements.INTERACT.PSObject.Properties | Measure-Object).Count -gt 0) {
                        $blockJson.requirements.INTERACT = New-Object PSObject
                        $modified = $true
                    }
                }
            }
            
            # Update XP values
            if ($blockJson.PSObject.Properties["xp_values"]) {
                # Update CRAFT XP
                if ($blockJson.xp_values.PSObject.Properties["CRAFT"]) {
                    if ($blockJson.xp_values.CRAFT.PSObject.Properties["technology"] -or 
                        $values.craftXp -gt 0) {
                        $blockJson.xp_values.CRAFT | Add-Member -NotePropertyName "technology" -NotePropertyValue $values.craftXp -Force
                        $modified = $true
                    }
                }
                
                # Update BLOCK_BREAK XP
                if ($blockJson.xp_values.PSObject.Properties["BLOCK_BREAK"]) {
                    if ($blockJson.xp_values.BLOCK_BREAK.PSObject.Properties["technology"] -or 
                        $values.breakXp -gt 0) {
                        $blockJson.xp_values.BLOCK_BREAK | Add-Member -NotePropertyName "technology" -NotePropertyValue $values.breakXp -Force
                        $modified = $true
                    }
                }
                
                # Update BLOCK_PLACE XP (same as BLOCK_BREAK)
                if ($blockJson.xp_values.PSObject.Properties["BLOCK_PLACE"]) {
                    if ($blockJson.xp_values.BLOCK_PLACE.PSObject.Properties["technology"] -or 
                        $values.breakXp -gt 0) {
                        $blockJson.xp_values.BLOCK_PLACE | Add-Member -NotePropertyName "technology" -NotePropertyValue $values.breakXp -Force
                        $modified = $true
                    }
                }
                
            }
            
            # Save changes if modified
            if ($modified) {
                $blockJson | ConvertTo-Json -Depth 10 | Set-Content -Path $blockFile.FullName -Encoding UTF8
                $stats.blocksAdjusted++
                $stats.totalFilesModified++
                
                Write-Host "    Adjusted block $blockName to tier $tier (tech level: $($values.requirement))" -ForegroundColor Green
                "$blockName - Adjusted to tier $tier (tech req: $($values.requirement), craft XP: $($values.craftXp), break XP: $($values.breakXp))" | Out-File -FilePath $logPath -Append
            }
        }
    }
    
    # Process items
    $itemsPath = Join-Path -Path $modPmmoPath -ChildPath "items"
    if (Test-Path $itemsPath) {
        $itemFiles = Get-ChildItem -Path $itemsPath -Filter "*.json"
        
        foreach ($itemFile in $itemFiles) {
            $itemName = $itemFile.BaseName
            Write-Host "  Processing item: $itemName" -ForegroundColor Yellow
            
            # Determine tier and values
            $tier = Get-ItemTier -name $itemName
            $values = Get-TechnologyValues -tier $tier
            
            # Load the JSON
            $itemJson = Get-Content -Path $itemFile.FullName -Raw | ConvertFrom-Json
            $modified = $false
            
            # Update requirements
            if ($itemJson.PSObject.Properties["requirements"]) {
                # Update USE requirement
                if ($itemJson.requirements.PSObject.Properties["USE"]) {
                    if ($itemJson.requirements.USE.PSObject.Properties["technology"] -or 
                        $values.requirement -gt 0) {
                        $itemJson.requirements.USE | Add-Member -NotePropertyName "technology" -NotePropertyValue $values.requirement -Force
                        $modified = $true
                    }
                }
                
                # Update TOOL requirement if present
                if ($itemJson.requirements.PSObject.Properties["TOOL"]) {
                    if ($itemJson.requirements.TOOL.PSObject.Properties["technology"] -or 
                        $values.requirement -gt 0) {
                        $itemJson.requirements.TOOL | Add-Member -NotePropertyName "technology" -NotePropertyValue $values.requirement -Force
                        $modified = $true
                    }
                }

                # Ensure INTERACT is empty (following your previous script's logic)
                if ($itemJson.requirements.PSObject.Properties["INTERACT"]) {
                    if (($itemJson.requirements.INTERACT.PSObject.Properties | Measure-Object).Count -gt 0) {
                        $itemJson.requirements.INTERACT = New-Object PSObject
                        $modified = $true
                    }
                }
            }
            
            # Update XP values
            if ($itemJson.PSObject.Properties["xp_values"]) {
                # Update CRAFT XP
                if ($itemJson.xp_values.PSObject.Properties["CRAFT"]) {
                    if ($itemJson.xp_values.CRAFT.PSObject.Properties["technology"] -or 
                        $values.craftXp -gt 0) {
                        $itemJson.xp_values.CRAFT | Add-Member -NotePropertyName "technology" -NotePropertyValue $values.craftXp -Force
                        $modified = $true
                    }
                }
            }
            
            # Save changes if modified
            if ($modified) {
                $itemJson | ConvertTo-Json -Depth 10 | Set-Content -Path $itemFile.FullName -Encoding UTF8
                $stats.itemsAdjusted++
                $stats.totalFilesModified++
                
                Write-Host "    Adjusted item $itemName to tier $tier (tech level: $($values.requirement))" -ForegroundColor Green
                "$itemName - Adjusted to tier $tier (tech req: $($values.requirement), craft XP: $($values.craftXp))" | Out-File -FilePath $logPath -Append
            }
        }
    }
}

# Write completion stats to log
"Adjustment completed at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath -Append
"Statistics:" | Out-File -FilePath $logPath -Append
"  Blocks adjusted: $($stats.blocksAdjusted)" | Out-File -FilePath $logPath -Append
"  Items adjusted: $($stats.itemsAdjusted)" | Out-File -FilePath $logPath -Append
"  Total files modified: $($stats.totalFilesModified)" | Out-File -FilePath $logPath -Append

# Output stats to console
Write-Host "`nSophisticated Storage & Backpacks adjustment completed!" -ForegroundColor Green
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  Blocks adjusted: $($stats.blocksAdjusted)" -ForegroundColor White
Write-Host "  Items adjusted: $($stats.itemsAdjusted)" -ForegroundColor White
Write-Host "  Total files modified: $($stats.totalFilesModified)" -ForegroundColor White
Write-Host "`nLog file saved to: $logPath" -ForegroundColor Yellow