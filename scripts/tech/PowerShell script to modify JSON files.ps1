# Script to configure Create mod technology progression
$directoryPath = "d:\src\atm10_pmmo\atm_10_pack\src\main\resources\data\create\pmmo"
$logPath = "d:\src\atm10_pmmo\scripts\create_tech_adjustments_log.txt"

# Start log file
"Create Mod Technology Adjustments started at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath

# Get all JSON files for items and blocks
$itemFiles = Get-ChildItem -Path "$directoryPath\items" -Filter "*.json" -Recurse -ErrorAction SilentlyContinue
$blockFiles = Get-ChildItem -Path "$directoryPath\blocks" -Filter "*.json" -Recurse -ErrorAction SilentlyContinue
$jsonFiles = $itemFiles + $blockFiles

Write-Host "Found $($jsonFiles.Count) total JSON files to process" -ForegroundColor Cyan
"Found $($jsonFiles.Count) total JSON files to process" | Out-File -FilePath $logPath -Append

# Initialize statistics
$stats = @{
    "filesModified" = 0
    "tier0Items" = 0
    "tier1Items" = 0
    "tier2Items" = 0
    "tier3Items" = 0
    "tier4Items" = 0
    "tier5Items" = 0
}

# Base configuration values - more modest starting values
$baseCraftExp = 400  # Base craft XP value
$craftExpPerLevel = 50  # Additional craft XP per level (scaled to max level 5)
$craftExpMultiplier = 1.0  # Adjustment multiplier for special items

# Technology level requirements - start at 0
$baseTechLevel = 0
$levelStep = 40  # Each tier increases by this amount

# Define Create mod keyword-to-level mapping
$keywordLevels = @{
    # Tier 0 - Basic components (0 requirement)
    "andesite_alloy" = 0
    "shaft" = 0
    "cogwheel" = 0
    "belt" = 0
    "pulley" = 0
    "gearbox" = 0
    "vertical_gearbox" = 0
    "hand_crank" = 0
    "water_wheel" = 0
    "wooden" = 0
    "andesite" = 0
    "copper" = 0
    "zinc" = 0
    "ladder" = 0
    "seat" = 0
    "casing" = 0
    "case" = 0
    "window" = 0
    "toll" = 0
    "wrench" = 0
    
    # Tier 1 - Basic mechanisms (40 requirement)
    "brass" = 1
    "brass_casing" = 1
    "brass_tunnel" = 1
    "mechanical_press" = 1
    "mechanical_mixer" = 1
    "mechanical_saw" = 1
    "mechanical_drill" = 1
    "deployer" = 1
    "fan" = 1
    "funnel" = 1
    "chute" = 1
    "fluid_pipe" = 1
    "fluid_valve" = 1
    "fluid_tank" = 1
    "spout" = 1
    "item_drain" = 1
    "hose_pulley" = 1
    "portable_fluid" = 1
    "blaze_burner" = 1
    "goggles" = 1
    
    # Tier 2 - Intermediate components (80 requirement)
    "millstone" = 2
    "basin" = 2
    "mechanical_crafter" = 2
    "mechanical_piston" = 2
    "piston_extension" = 2
    "gantry" = 2
    "clutch" = 2
    "gearshift" = 2
    "encased_chain_drive" = 2
    "adjustable_chain_gearshift" = 2
    "sequenced_gearshift" = 2
    "rotation_speed_controller" = 2
    "crushing_wheel" = 2
    "contraption" = 2
    "portable_storage" = 2
    "sticker" = 2
    "track" = 2
    
    # Tier 3 - Advanced kinetics (120 requirement)
    "windmill" = 3
    "steam_engine" = 3
    "furnace_engine" = 3
    "flywheel" = 3
    "mechanical_arm" = 3
    "mechanical_pump" = 3
    "smart" = 3
    "filter" = 3
    "brass_funnel" = 3
    "brass_hand" = 3
    "schematic" = 3
    "schematicannon" = 3
    "extendo_grip" = 3
    "potato_cannon" = 3
    "linked_controller" = 3
    
    # Tier 4 - Complex automation (160 requirement)
    "sequencer" = 4
    "redstone_link" = 4
    "controller_rail" = 4
    "peculiar_bell" = 4
    "nixie_tube" = 4
    "display_board" = 4
    "rose_quartz" = 4
    "electron_tube" = 4
    "precision" = 4
    "mechanical_bearing" = 4
    "rope_pulley" = 4
    "linear_chassis" = 4
    "radial_chassis" = 4
    "minecart" = 4
    "contraption_controls" = 4
    
    # Tier 5 - Endgame machinery (200 requirement)
    "creative" = 5
    "handheld_worldshaper" = 5
    "refined_radiance" = 5
    "shadow_steel" = 5
    "chromatic_compound" = 5
    "wand_of_symmetry" = 5
    "clockwork_bearing" = 5
    "mysterious" = 5
    "chromatic" = 5
    "railway" = 5
}

# Process each JSON file
Write-Host "Beginning processing of Create mod files..." -ForegroundColor Cyan
"Beginning processing of Create mod files..." | Out-File -FilePath $logPath -Append

foreach ($file in $jsonFiles) {
    $fileName = $file.BaseName.ToLower()
    
    # Skip non-Create content (safety check)
    if ($file.FullName -notmatch "create") {
        continue
    }
    
    # Determine technology level based on filename
    $level = 0
    $matchedKeyword = ""
    
    foreach ($keyword in $keywordLevels.Keys) {
        if ($fileName -match $keyword) {
            $keywordLevel = $keywordLevels[$keyword]
            if ($keywordLevel -gt $level) {
                $level = $keywordLevel
                $matchedKeyword = $keyword
            }
        }
    }
    
    # Track stats
    $statKey = "tier${level}Items"
    $stats[$statKey]++
    
    # Calculate technology requirement based on level
    $techRequirement = $baseTechLevel + ($level * $levelStep)
    
    # Calculate craft XP
    $craftExp = $baseCraftExp + ($level * $craftExpPerLevel)
    
    # Apply special multipliers for certain items
    if ($fileName -match "creative" -or $fileName -match "refined_radiance" -or $fileName -match "shadow_steel") {
        $craftExp = $craftExp * 2
    }
    
    # Round to nice values
    $craftExp = [Math]::Round($craftExp)
    
    # Read the JSON content
    try {
        $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        $modified = $false
        
        # Check if xp_values exists
        if (-not $jsonContent.PSObject.Properties["xp_values"]) {
            $jsonContent | Add-Member -NotePropertyName "xp_values" -NotePropertyValue @{}
            $modified = $true
        }
        
        # Check if xp_values.CRAFT exists
        if (-not $jsonContent.xp_values.PSObject.Properties["CRAFT"]) {
            $jsonContent.xp_values | Add-Member -NotePropertyName "CRAFT" -NotePropertyValue @{}
            $modified = $true
        }
        
        # Update technology XP for crafting
        if (-not $jsonContent.xp_values.CRAFT.PSObject.Properties["technology"] -or 
            $jsonContent.xp_values.CRAFT.technology -ne $craftExp) {
            $jsonContent.xp_values.CRAFT | Add-Member -NotePropertyName "technology" -NotePropertyValue $craftExp -Force
            $modified = $true
        }
         
        # Check if requirements exists
        if (-not $jsonContent.PSObject.Properties["requirements"]) {
            $jsonContent | Add-Member -NotePropertyName "requirements" -NotePropertyValue @{}
            $modified = $true
        }
        
        # Ensure all requirement categories exist
        $requirementNodes = @("PLACE", "USE", "INTERACT", "BREAK", "TOOL", "WEAPON", "WEAR")
        
        foreach ($node in $requirementNodes) {
            if (-not $jsonContent.requirements.PSObject.Properties[$node]) {
                $jsonContent.requirements | Add-Member -NotePropertyName $node -NotePropertyValue @{}
                $modified = $true
            }
        }
        
        # Only add technology requirements for tier 1+
        if ($level -gt 0) {
            # For items, set USE requirement
            if ($file.FullName -match "\\items\\") {
                if (-not $jsonContent.requirements.USE.PSObject.Properties["technology"] -or 
                    $jsonContent.requirements.USE.technology -ne $techRequirement) {
                    $jsonContent.requirements.USE | Add-Member -NotePropertyName "technology" -NotePropertyValue $techRequirement -Force
                    $modified = $true
                }
            }
            
            # For blocks, set PLACE and INTERACT requirements
            if ($file.FullName -match "\\blocks\\") {
                if (-not $jsonContent.requirements.PLACE.PSObject.Properties["technology"] -or 
                    $jsonContent.requirements.PLACE.technology -ne $techRequirement) {
                    $jsonContent.requirements.PLACE | Add-Member -NotePropertyName "technology" -NotePropertyValue $techRequirement -Force
                    $modified = $true
                }
                
                # Only add INTERACT requirements for interactive blocks
                $interactiveBlockPatterns = @("controller", "terminal", "interface", "toggle", "lever", "button", "link", "engine")
                $needsInteractRequirement = $false
                
                foreach ($pattern in $interactiveBlockPatterns) {
                    if ($fileName -match $pattern) {
                        $needsInteractRequirement = $true
                        break
                    }
                }
                
                if ($needsInteractRequirement) {
                    if (-not $jsonContent.requirements.INTERACT.PSObject.Properties["technology"] -or 
                        $jsonContent.requirements.INTERACT.technology -ne $techRequirement) {
                        $jsonContent.requirements.INTERACT | Add-Member -NotePropertyName "technology" -NotePropertyValue $techRequirement -Force
                        $modified = $true
                    }
                } else {
                    # Clear INTERACT requirement for non-interactive blocks
                    if ($jsonContent.requirements.INTERACT.PSObject.Properties["technology"]) {
                        $jsonContent.requirements.INTERACT.PSObject.Properties.Remove("technology")
                        $modified = $true
                    }
                }
            }
        } else {
            # For tier 0, ensure no tech requirements exist
            foreach ($node in $requirementNodes) {
                if ($jsonContent.requirements.$node.PSObject.Properties["technology"]) {
                    $jsonContent.requirements.$node.PSObject.Properties.Remove("technology")
                    $modified = $true
                }
            }
        }
        
        # For tools, set TOOL requirement
        if ($fileName -match "wrench" -or $fileName -match "hammer" -or $fileName -match "saw" -or 
            $fileName -match "drill" -or $fileName -match "goggles") {
            if ($level -gt 0) {
                if (-not $jsonContent.requirements.TOOL.PSObject.Properties["technology"] -or 
                    $jsonContent.requirements.TOOL.technology -ne $techRequirement) {
                    $jsonContent.requirements.TOOL | Add-Member -NotePropertyName "technology" -NotePropertyValue $techRequirement -Force
                    $modified = $true
                }
            }
        }
        
        # For weapons, set WEAPON requirement
        if ($fileName -match "cannon" -or $fileName -match "blade") {
            if ($level -gt 0) {
                if (-not $jsonContent.requirements.WEAPON.PSObject.Properties["technology"] -or 
                    $jsonContent.requirements.WEAPON.technology -ne $techRequirement) {
                    $jsonContent.requirements.WEAPON | Add-Member -NotePropertyName "technology" -NotePropertyValue $techRequirement -Force
                    $modified = $true
                }
            }
        }

        # Check if xp_values exists
        if (-not $jsonContent.PSObject.Properties["xp_values"]) {
            $jsonContent | Add-Member -NotePropertyName "xp_values" -NotePropertyValue @{} -Force
            $modified = $true
        }

        # Check if xp_values.CRAFT exists
        if (-not $jsonContent.xp_values.PSObject.Properties["CRAFT"]) {
            $jsonContent.xp_values | Add-Member -NotePropertyName "CRAFT" -NotePropertyValue @{} -Force
            $modified = $true
        }

        # Update technology XP for crafting - this is the key fix
        $jsonContent.xp_values.CRAFT = @{ "technology" = $craftExp }
        $modified = $true
        
        # Save changes if any modifications were made
        if ($modified) {
            $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $file.FullName -Encoding UTF8
            $stats.filesModified++
            
            $logMessage = "[$level] $fileName - Set tech level to $techRequirement (craft XP: $craftExp)"
            $logMessage | Out-File -FilePath $logPath -Append
            
            Write-Host "  Updated: $fileName (Tier $level, Tech: $techRequirement)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  Error processing $($file.FullName): $_" -ForegroundColor Red
        "Error processing $($file.FullName): $_" | Out-File -FilePath $logPath -Append
    }
}

# Write summary to log
"Create Mod Technology Adjustments completed at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath -Append
"Statistics:" | Out-File -FilePath $logPath -Append
"  Total files modified: $($stats.filesModified)" | Out-File -FilePath $logPath -Append
"  Tier 0 items (Tech 0): $($stats.tier0Items)" | Out-File -FilePath $logPath -Append
"  Tier 1 items (Tech 40): $($stats.tier1Items)" | Out-File -FilePath $logPath -Append
"  Tier 2 items (Tech 80): $($stats.tier2Items)" | Out-File -FilePath $logPath -Append
"  Tier 3 items (Tech 120): $($stats.tier3Items)" | Out-File -FilePath $logPath -Append
"  Tier 4 items (Tech 160): $($stats.tier4Items)" | Out-File -FilePath $logPath -Append
"  Tier 5 items (Tech 200): $($stats.tier5Items)" | Out-File -FilePath $logPath -Append

# Output stats to console
Write-Host "`nCreate Mod Technology Adjustments completed!" -ForegroundColor Green
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  Total files modified: $($stats.filesModified)" -ForegroundColor White
Write-Host "  Tier 0 items (Tech 0): $($stats.tier0Items)" -ForegroundColor White
Write-Host "  Tier 1 items (Tech 40): $($stats.tier1Items)" -ForegroundColor White
Write-Host "  Tier 2 items (Tech 80): $($stats.tier2Items)" -ForegroundColor White
Write-Host "  Tier 3 items (Tech 120): $($stats.tier3Items)" -ForegroundColor White
Write-Host "  Tier 4 items (Tech 160): $($stats.tier4Items)" -ForegroundColor White
Write-Host "  Tier 5 items (Tech 200): $($stats.tier5Items)" -ForegroundColor White
Write-Host "`nLog file saved to: $logPath" -ForegroundColor Yellow