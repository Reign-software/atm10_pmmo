# Script to analyze items/blocks and generate tech progression plan
$modTechRangesPath = "d:\src\atm10_pmmo\scripts\tech\mod_tech_ranges.json"
$dataPath = "d:\src\atm10_pmmo\atm_10_pack\src\main\resources\data\"
$outputPlanPath = "d:\src\atm10_pmmo\scripts\tech\mod_progression_plan.json"

# Load mod tech ranges data
$modTechRanges = Get-Content -Path $modTechRangesPath -Raw | ConvertFrom-Json

# Create progression plan structure
$progressionPlan = @{
    "modPlans" = @{}
    "generated" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "stats" = @{
        "modsProcessed" = 0
        "itemsAnalyzed" = 0
        "blocksAnalyzed" = 0
        "tiersAssigned" = 0
        "skippedNonTech" = 0
    }
}

# Define keywords for non-tech items/blocks to ignore
$nonTechKeywords = @(
    # Nature and decorative
    "leaves", "log", "wood", "planks", "sapling", "flower", "bush", "grass", "dirt", 
    "stone", "rock", "sand", "gravel", "clay", "soil", "path",
    
    # Ores and raw materials
    "ore", "nugget", "ingot", "raw", "dust", "gem", "crystal", "shard",
    
    # Decorative
    "stairs", "slab", "fence", "wall", "door", "trapdoor", "pane", "glass",
    "carpet", "bed", "lantern", "candle", "pot", "lamp", "light", "torch",
    "banner", "sign", "painting", "frame", "decoration", "ornament",
    
    # Food and crops
    "seed", "crop", "fruit", "vegetable", "food", "meal", "dish", "stew",
    "soup", "meat", "fish", "bread", "cake", "cookie", "pie", "berry"
)

# Define keyword-to-tier mapping (generic patterns across mods)
$keywordTiers = @{
    # Tier 0 - Basic items (start of mod progression)
    "basic" = 0
    "simple" = 0
    "primitive" = 0
    "wooden" = 0
    "starter" = 0
    "crude" = 0
    "stone" = 0
    "copper" = 0

    # Tier 1 - Early progression
    "iron" = 1
    "bronze" = 1
    "standard" = 1
    "normal" = 1
    "improved" = 1
    "steel" = 1
    "tin" = 1
    "lapis" = 1
    "block" = 1

    # Tier 2 - Mid progression
    "gold" = 2
    "silver" = 2
    "redstone" = 2
    "energized" = 2
    "enhanced" = 2
    "quartz" = 2
    "reinforced" = 2
    "intermediate" = 2
    "hardened" = 2
    "machine" = 2

    # Tier 3 - Advanced progression
    "diamond" = 3
    "emerald" = 3
    "obsidian" = 3
    "advanced" = 3
    "refined" = 3
    "precision" = 3
    "processor" = 3

    # Tier 4 - Late progression
    "elite" = 4
    "ultimate" = 4
    "resonant" = 4
    "extreme" = 4
    "superior" = 4
    "automated" = 4
    "netherite" = 4

    # Tier 5 - End-game
    "creative" = 5
    "quantum" = 5
    "perfect" = 5
    "infinity" = 5
    "cosmic" = 5
    "maximum" = 5
    "stellar" = 5
}

# Define tech-related keyword indicators (items that are definitely tech-related)
$techKeywords = @(
    "machine", "engine", "motor", "generator", "battery", "circuit", "chip", 
    "processor", "compressor", "furnace", "energy", "power", "cable", "wire", 
    "conduit", "pipe", "pump", "terminal", "interface", "controller", "panel",
    "cell", "turbine", "reactor", "storage", "tank", "capacitor", "mechanism",
    "device", "crafting", "assembly", "auto", "electric", "electronic", "solar", 
    "nuclear", "thermal", "wireless", "remote", "digital", "computer", "network",
    "robotics", "automated", "upgrade", "augment", "enhance", "core", "module"
)

# Define special keywords mapping for specific mods
$modSpecificKeywords = @{
    "ae2" = @{
        "1k" = 1
        "4k" = 2
        "16k" = 3
        "64k" = 4
        "256k" = 5
        "interface" = 3
        "controller" = 4
        "terminal" = 3
        "crafting" = 3
    }
    "mekanism" = @{
        "basic" = 1
        "advanced" = 2
        "elite" = 3
        "ultimate" = 4
        "factory" = 3
        "enriched" = 2
    }
    "thermal" = @{
        "basic" = 1
        "hardened" = 2
        "reinforced" = 3
        "signalum" = 3
        "enderium" = 4
        "resonant" = 4
    }
    "industrialforegoing" = @{
        "simple" = 1
        "advanced" = 3
        "supreme" = 4
    }
    "bigreactors" = @{
        "casing" = 1
        "controller" = 3
        "fuel_rod" = 2
        "control_rod" = 3
        "port" = 2
        "turbine" = 4
    }
    "computercraft" = @{
        "computer" = 2
        "advanced" = 3
        "turtle" = 3
        "disk" = 1
        "monitor" = 2
        "printer" = 3
        "speaker" = 2
    }
}

# Helper function to check if item/block is tech-related
function Is-TechRelated {
    param (
        [string]$itemName,
        [array]$techKeywords,
        [array]$nonTechKeywords
    )
    
    # First check if it matches any tech keywords (higher priority)
    foreach ($keyword in $techKeywords) {
        if ($itemName -like "*$keyword*") {
            return $true
        }
    }
    
    # Then check if it matches any non-tech keywords
    foreach ($keyword in $nonTechKeywords) {
        if ($itemName -like "*$keyword*") {
            return $false
        }
    }
    
    # Default to true if not explicitly excluded
    return $true
}

# Process each mod category except "none" and "unknown"
$categoriesToProcess = @("high-tech", "mid-high-tech", "mid-tech", "low-mid-tech", "low-tech")

foreach ($category in $categoriesToProcess) {
    Write-Host "Processing $category mods..." -ForegroundColor Cyan
    
    $mods = $modTechRanges.$category.PSObject.Properties.Name
    
    foreach ($modName in $mods) {
        $modData = $modTechRanges.$category.$modName
        $techMin = $modData.techMin
        $techMax = $modData.techMax
        
        # Skip if the mod doesn't have PMMO files or has techMin of 0
        if (-not $modData.hasPmmoFiles -or $techMin -eq 0) {
            Write-Host "  Skipping $modName - No tech requirements" -ForegroundColor Gray
            continue
        }
        
        $modPath = Join-Path -Path $dataPath -ChildPath $modName
        $modPmmoPath = Join-Path -Path $modPath -ChildPath "pmmo"
        
        if (-not (Test-Path $modPmmoPath)) {
            Write-Host "  Skipping $modName - No pmmo folder found" -ForegroundColor Yellow
            continue
        }
        
        Write-Host "  Analyzing $modName (Tech Range: $techMin-$techMax)" -ForegroundColor White
        
        # Create mod plan entry
        $modPlan = @{
            "category" = $category
            "techMin" = $techMin
            "techMax" = $techMax
            "blocks" = @{}
            "items" = @{}
            "tierKeywords" = @{}  # Store what keywords matched for documentation
            "stats" = @{
                "totalBlocks" = 0
                "totalItems" = 0
                "skippedBlocks" = 0
                "skippedItems" = 0
                "tierDistribution" = @{
                    "tier0" = 0
                    "tier1" = 0
                    "tier2" = 0
                    "tier3" = 0
                    "tier4" = 0 
                    "tier5" = 0
                }
            }
        }
        
        # Get the mod-specific keywords if they exist, otherwise use the general ones
        $currentKeywordTiers = $keywordTiers.Clone()
        if ($modSpecificKeywords.ContainsKey($modName)) {
            foreach ($keyword in $modSpecificKeywords[$modName].Keys) {
                $currentKeywordTiers[$keyword] = $modSpecificKeywords[$modName][$keyword]
            }
        }
        
        # Process blocks
        $blocksPath = Join-Path -Path $modPmmoPath -ChildPath "blocks"
        if (Test-Path $blocksPath) {
            $blockFiles = Get-ChildItem -Path $blocksPath -Filter "*.json"
            $modPlan.stats.totalBlocks = $blockFiles.Count
            
            foreach ($blockFile in $blockFiles) {
                $blockName = $blockFile.BaseName
                $progressionPlan.stats.blocksAnalyzed++
                
                # Skip non-tech blocks
                if (-not (Is-TechRelated -itemName $blockName -techKeywords $techKeywords -nonTechKeywords $nonTechKeywords)) {
                    $modPlan.stats.skippedBlocks++
                    $progressionPlan.stats.skippedNonTech++
                    continue
                }
                
                # Analyze block name for tier keywords
                $blockTier = 0  # Default to tier 0
                $matchedKeywords = @()
                
                foreach ($keyword in $currentKeywordTiers.Keys) {
                    if ($blockName -like "*$keyword*") {
                        $keywordTier = $currentKeywordTiers[$keyword]
                        if ($keywordTier -gt $blockTier) {
                            $blockTier = $keywordTier
                        }
                        $matchedKeywords += $keyword
                    }
                }
                
                # Calculate the actual tech level based on the mod's range and the block's tier
                if ($techMax -gt $techMin) {
                    $tierRange = 5  # 0-5 tiers
                    $techRange = $techMax - $techMin
                    $techPerTier = $techRange / $tierRange
                    $techLevel = $techMin + ($blockTier * $techPerTier)
                    # Round to nearest multiple of 5 for cleaner values
                    $techLevel = [math]::Round($techLevel / 5) * 5
                } else {
                    $techLevel = $techMin
                }
                
                # Store block tier info
                $modPlan.blocks[$blockName] = @{
                    "tier" = $blockTier
                    "techLevel" = $techLevel
                    "matchedKeywords" = $matchedKeywords
                }
                
                # Update tier distribution stats
                $modPlan.stats.tierDistribution["tier$blockTier"]++
                $progressionPlan.stats.tiersAssigned++
            }
        }
        
        # Process items
        $itemsPath = Join-Path -Path $modPmmoPath -ChildPath "items"
        if (Test-Path $itemsPath) {
            $itemFiles = Get-ChildItem -Path $itemsPath -Filter "*.json"
            $modPlan.stats.totalItems = $itemFiles.Count
            
            foreach ($itemFile in $itemFiles) {
                $itemName = $itemFile.BaseName
                $progressionPlan.stats.itemsAnalyzed++
                
                # Skip non-tech items
                if (-not (Is-TechRelated -itemName $itemName -techKeywords $techKeywords -nonTechKeywords $nonTechKeywords)) {
                    $modPlan.stats.skippedItems++
                    $progressionPlan.stats.skippedNonTech++
                    continue
                }
                
                # Analyze item name for tier keywords
                $itemTier = 0  # Default to tier 0
                $matchedKeywords = @()
                
                foreach ($keyword in $currentKeywordTiers.Keys) {
                    if ($itemName -like "*$keyword*") {
                        $keywordTier = $currentKeywordTiers[$keyword]
                        if ($keywordTier -gt $itemTier) {
                            $itemTier = $keywordTier
                        }
                        $matchedKeywords += $keyword
                    }
                }
                
                # Calculate the actual tech level based on the mod's range and the item's tier
                if ($techMax -gt $techMin) {
                    $tierRange = 5  # 0-5 tiers
                    $techRange = $techMax - $techMin
                    $techPerTier = $techRange / $tierRange
                    $techLevel = $techMin + ($itemTier * $techPerTier)
                    # Round to nearest multiple of 5 for cleaner values
                    $techLevel = [math]::Round($techLevel / 5) * 5
                } else {
                    $techLevel = $techMin
                }
                
                # Store item tier info
                $modPlan.items[$itemName] = @{
                    "tier" = $itemTier
                    "techLevel" = $techLevel
                    "matchedKeywords" = $matchedKeywords
                }
                
                # Update tier distribution stats
                $modPlan.stats.tierDistribution["tier$itemTier"]++
                $progressionPlan.stats.tiersAssigned++
            }
        }
        
        # Store mod-specific tier keywords used
        $modPlan.tierKeywords = $currentKeywordTiers
        
        # Add mod plan to overall plan
        $progressionPlan.modPlans[$modName] = $modPlan
        $progressionPlan.stats.modsProcessed++
    }
}

# Save the progression plan as JSON
$progressionPlan | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPlanPath -Encoding UTF8
Write-Host "Mod progression plan generated at: $outputPlanPath" -ForegroundColor Green
Write-Host "Stats:" -ForegroundColor Cyan
Write-Host "  Mods processed: $($progressionPlan.stats.modsProcessed)" -ForegroundColor White
Write-Host "  Items analyzed: $($progressionPlan.stats.itemsAnalyzed)" -ForegroundColor White
Write-Host "  Blocks analyzed: $($progressionPlan.stats.blocksAnalyzed)" -ForegroundColor White
Write-Host "  Tiers assigned: $($progressionPlan.stats.tiersAssigned)" -ForegroundColor White
Write-Host "  Skipped non-tech: $($progressionPlan.stats.skippedNonTech)" -ForegroundColor Gray