# Script to analyze mods for farming-related content
$dataPath = "d:\src\atm10_pmmo\atm_10_pack\src\main\resources\data\"
$outputPlanPath = "d:\src\atm10_pmmo\scripts\farming\farming_progression_plan.json"

# Create progression plan structure
$farmingPlan = @{
    "modPlans" = @{}
    "generated" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "stats" = @{
        "modsProcessed" = 0
        "itemsAnalyzed" = 0
        "blocksAnalyzed" = 0
        "farmingItemsFound" = 0
        "farmingBlocksFound" = 0
    }
}

# Define farming-related keywords
$farmingKeywords = @(
    # Basic farming
    "farm", "seed", "crop", "sapling", "plant", "garden", "cultivat", "sprout", 
    "grow", "harvest", "hoe", "plow", "till", "fertilizer", "compost", "manure", "mulch",
    
    # Crops and plants
    "wheat", "potato", "carrot", "beetroot", "melon", "pumpkin", "bean", "corn", "rice", 
    "tomato", "lettuce", "cabbage", "onion", "garlic", "pepper", "berry", "fruit", "vegetable",
    "sugarcane", "bamboo", "cactus", "flower", "mushroom", "cocoa", "netherwart", "cotton",

    # Animals and husbandry
    "animal", "cow", "pig", "sheep", "chicken", "rabbit", "horse", "llama", "bee", "fish",
    "feed", "breed",
    
    # Equipment and machinery
    "watering", "irrigat", "sprinkler", "harvester", "planter", "scarecrow", "greenhouse",
    "feeder", "silo", "barn", "coop", "pen", "trough", "pasture", "ranch", "milk"
)

# Define keyword-to-tier mapping
$farmingTiers = @{
    # Tier 0 - Basic farming
    "basic" = 0
    "simple" = 0
    "crude" = 0
    "wooden" = 0
    "starter" = 0
    "primitive" = 0
    "hand" = 0
    
    # Tier 1 - Early farming
    "stone" = 1
    "flint" = 1
    "bone" = 1
    "standard" = 1
    "normal" = 1
    "copper" = 1
    "tin" = 1
    
    # Tier 2 - Mid farming
    "iron" = 2
    "bronze" = 2
    "steel" = 2
    "improved" = 2
    "enhanced" = 2
    "gold" = 2
    "automated" = 2
    "mechanical" = 2
    
    # Tier 3 - Advanced farming
    "diamond" = 3
    "advanced" = 3
    "electric" = 3
    "powered" = 3
    "reinforced" = 3
    "redstone" = 3
    "industrial" = 3
    
    # Tier 4 - Expert farming
    "emerald" = 4
    "expert" = 4
    "netherite" = 4
    "ultimate" = 4
    "optimized" = 4
    "enchanted" = 4
    
    # Tier 5 - Master farming
    "creative" = 5
    "perfect" = 5
    "quantum" = 5
    "cosmic" = 5
    "master" = 5
    "legendary" = 5
}

# Define mod-specific keyword tiers
$modSpecificTiers = @{
    "minecraft" = @{
        "wooden_hoe" = 0
        "stone_hoe" = 0
        "iron_hoe" = 1
        "golden_hoe" = 1
        "diamond_hoe" = 2
        "netherite_hoe" = 3
        "wheat" = 0
        "carrot" = 0
        "potato" = 0
        "beetroot" = 0
        "pumpkin" = 1
        "melon" = 1
        "cocoa" = 1
        "nether_wart" = 2
        "chorus" = 3
        "composter" = 0
        "bone_meal" = 0
        "hay_block" = 1
        "bee" = 2
        "honey" = 2
        "beehive" = 1
    }
    "farmingforblockheads" = @{
        "market" = 0
        "feeding_trough" = 1
        "chicken_nest" = 1
        "fertilizer" = 2
    }
    "mysticalagriculture" = @{
        # Base material tiers
        "inferium" = 1
        "prudentium" = 2
        "tertium" = 3
        "imperium" = 4
        "supremium" = 5
        "awakened_supremium" = 5
        
        # Tools and equipment
        "inferium_hoe" = 1
        "prudentium_hoe" = 2
        "tertium_hoe" = 3
        "imperium_hoe" = 4
        "supremium_hoe" = 5
        "awakened_supremium_hoe" = 5
        
        "inferium_watering_can" = 1
        "prudentium_watering_can" = 2
        "tertium_watering_can" = 3
        "imperium_watering_can" = 4
        "supremium_watering_can" = 5
        "awakened_supremium_watering_can" = 5
        
        "inferium_growth_accelerator" = 1
        "prudentium_growth_accelerator" = 2
        "tertium_growth_accelerator" = 3
        "imperium_growth_accelerator" = 4
        "supremium_growth_accelerator" = 5
        "awakened_supremium_growth_accelerator" = 5
        
        "inferium_farmland" = 1
        "prudentium_farmland" = 2
        "tertium_farmland" = 3
        "imperium_farmland" = 4
        "supremium_farmland" = 5
        
        # Basic resource seeds
        "dirt_seeds" = 1
        "stone_seeds" = 1
        "wood_seeds" = 1
        "ice_seeds" = 1
        "water_seeds" = 1
        "fire_seeds" = 1
        "air_seeds" = 1
        "earth_seeds" = 1
        
        # Common metal/material seeds
        "iron_seeds" = 2
        "copper_seeds" = 2
        "tin_seeds" = 2
        "zinc_seeds" = 2
        "brass_seeds" = 2
        "bronze_seeds" = 2
        "silver_seeds" = 2
        "lead_seeds" = 2
        "nickel_seeds" = 2
        "coal_seeds" = 2
        "redstone_seeds" = 2
        "glowstone_seeds" = 2
        "obsidian_seeds" = 2
        "saltpeter_seeds" = 2
        "silicon_seeds" = 2
        "sulfur_seeds" = 2
        "aluminum_seeds" = 2
        "limestone_seeds" = 2
        "steel_seeds" = 2
        "graphite_seeds" = 2
        
        # Uncommon material seeds
        "gold_seeds" = 3
        "diamond_seeds" = 3
        "lapis_lazuli_seeds" = 3
        "emerald_seeds" = 3
        "quartz_seeds" = 3
        "nether_quartz_seeds" = 3
        "certus_quartz_seeds" = 3
        "fluix_seeds" = 3
        "osmium_seeds" = 3
        "uranium_seeds" = 3
        "iridium_seeds" = 3
        "platinum_seeds" = 3
        "manyullyn_seeds" = 3
        
        # Rare material seeds
        "netherite_seeds" = 4
        "enderium_seeds" = 4
        "signalum_seeds" = 4
        "lumium_seeds" = 4
        "refined_obsidian_seeds" = 4
        "refined_glowstone_seeds" = 4
        "starmetal_seeds" = 4
        "vibranium_seeds" = 4
        "draconium_seeds" = 4
        
        # End-game material seeds
        "nether_star_seeds" = 5
        "dragon_egg_seeds" = 5
        "gaia_spirit_seeds" = 5
        "neutronium_seeds" = 5
        "unobtainium_seeds" = 5
        "allthemodium_seeds" = 5
        "awakened_draconium_seeds" = 5
        
        # Passive mob seeds
        "chicken_seeds" = 1
        "cow_seeds" = 1
        "pig_seeds" = 1
        "sheep_seeds" = 1
        "rabbit_seeds" = 1
        "squid_seeds" = 1
        "fish_seeds" = 1
        "turtle_seeds" = 1
        
        # Hostile mob seeds
        "zombie_seeds" = 2
        "skeleton_seeds" = 2
        "creeper_seeds" = 2
        "spider_seeds" = 2
        "slime_seeds" = 2
        "blaze_seeds" = 2
        "ghast_seeds" = 2
        
        # Special mob seeds
        "enderman_seeds" = 3
        "wither_skeleton_seeds" = 3
        
        # Resource essence
        "dirt_essence" = 1
        "wood_essence" = 1
        "stone_essence" = 1
        "chicken_essence" = 1
        "cow_essence" = 1
        "pig_essence" = 1
        "sheep_essence" = 1
        "rabbit_essence" = 1
        "fish_essence" = 1
        
        # Special items
        "mystical_fertilizer" = 3
        "harvester" = 3
        "seed_reprocessor" = 2
    }
    "immersiveengineering" = @{
        "garden_cloche" = 2
        "hemp" = 1
    }
    "industrialforegoing" = @{
        "plant_gatherer" = 2
        "plant_sower" = 2
        "plant_fertilizer" = 2
        "animal_feeder" = 2
        "animal_rancher" = 3
        "animal_baby_separator" = 3
        "sewage" = 2
        "fertilizer" = 2
    }
    "thermal" = @{
        "phytogro" = 2
        "insolator" = 2
    }
    "pamhc" = @{
        "market" = 1
        "garden" = 1
        "presser" = 2
        "grinder" = 2
        "oven" = 2
    }
}

# Default tier assignment by mod (for mods without specific keywords in items)
$modDefaultTiers = @{
    "minecraft" = 0
    "mysticalagriculture" = 2  # Default tier for mystical agriculture items with no specific match
    "pamhc" = 1
    "farmingforblockheads" = 0
    "croptopia" = 1
    "industrialforegoing" = 2
    "immersiveengineering" = 2
    "thermal" = 2
    "rustic" = 1
    "agricraft" = 1
    "harvestcraft" = 1
    "simplyseasons" = 1
}

# Farming category indicators (certain keywords that indicate specific tier ranges)
$farmingCategoryIndicators = @{
    # Tools
    "hoe" = @{minTier = 0; maxTier = 5}  # Extended to tier 5 for mystical agriculture
    "watering" = @{minTier = 0; maxTier = 5}  # Extended to tier 5 for mystical agriculture
    "scythe" = @{minTier = 1; maxTier = 4}
    
    # Seeds and basic crops
    "seed" = @{minTier = 0; maxTier = 5}  # Extended to tier 5 for mystical agriculture
    "crop" = @{minTier = 0; maxTier = 5}
    "sapling" = @{minTier = 0; maxTier = 3}
    
    # Advanced crops and special plants
    "essence" = @{minTier = 1; maxTier = 5}
    "magical" = @{minTier = 2; maxTier = 5}
    "special" = @{minTier = 2; maxTier = 5}
    
    # Processing equipment
    "mill" = @{minTier = 1; maxTier = 3}
    "press" = @{minTier = 1; maxTier = 3}
    "harvester" = @{minTier = 2; maxTier = 4}
    "fertilizer" = @{minTier = 1; maxTier = 5}  # Extended for mystical fertilizer
    
    # Animal husbandry
    "feed" = @{minTier = 0; maxTier = 2}
    "breeder" = @{minTier = 2; maxTier = 3}
    "collector" = @{minTier = 1; maxTier = 3}
    
    # Mystical agriculture specific
    "growth_accelerator" = @{minTier = 1; maxTier = 5}
    "farmland" = @{minTier = 1; maxTier = 5}
}

# Function to determine if item/block is farming-related
function Is-FarmingRelated {
    param ([string]$name, [string]$modName)
    
    # Special case for farming mods - consider all items potentially farming-related
    $farmingCoreMods = @("mysticalagriculture", "farmingforblockheads", "croptopia", "agricraft", 
                       "harvestcraft", "pamhc", "croparia", "rustic", "simplecorn", "simplytea")
    
    if ($farmingCoreMods -contains $modName) {
        return $true
    }
    
    # Special case for minecraft farming items
    if ($modName -eq "minecraft" -and 
        ($name -like "*_hoe*" -or $name -like "*seed*" -or $name -like "*sapling*" -or
         $name -like "*wheat*" -or $name -like "*carrot*" -or $name -like "*potato*" -or
         $name -like "*beetroot*" -or $name -like "*melon*" -or $name -like "*pumpkin*" -or
         $name -like "*sugar*" -or $name -like "*cactus*" -or $name -like "*bamboo*" -or
         $name -like "*cocoa*" -or $name -like "*nether_wart*" -or $name -like "*chorus*" -or
         $name -like "*hay*" -or $name -like "*milk*" -or $name -like "*egg*" -or
         $name -like "*wool*" -or $name -like "*leather*" -or $name -like "*beef*" -or
         $name -like "*pork*" -or $name -like "*mutton*" -or $name -like "*chicken*" -or
         $name -like "*composter*" -or $name -like "*bone_meal*" -or $name -like "*bee*" -or
         $name -like "*honey*" -or $name -like "*lead*" -or $name -like "*saddle*")) {
        return $true
    }
    
    # General keyword matching for other mods
    foreach ($keyword in $farmingKeywords) {
        if ($name -like "*$keyword*") {
            return $true
        }
    }
    
    return $false
}

# Function to get the default tier for a mod, with fallback
function Get-ModDefaultTier {
    param (
        [string]$modName
    )
    
    if ($modDefaultTiers.ContainsKey($modName)) {
        return $modDefaultTiers[$modName]
    }
    
    # Default tier for mods without a specific assignment
    return 0
}

# Special function to handle Mystical Agriculture seed tiers
function Get-MysticalAgricultureTier {
    param (
        [string]$itemName
    )
    
    # Check if it's a specifically defined item
    if ($modSpecificTiers.mysticalagriculture.ContainsKey($itemName)) {
        return $modSpecificTiers.mysticalagriculture[$itemName]
    }
    
    # Check tier by material prefix name
    if ($itemName -like "inferium_*") { return 1 }
    if ($itemName -like "prudentium_*") { return 2 }
    if ($itemName -like "tertium_*") { return 3 }
    if ($itemName -like "imperium_*") { return 4 }
    if ($itemName -like "supremium_*") { return 5 }
    if ($itemName -like "awakened_supremium_*") { return 5 }
    
    # Resource categorization for seeds not specifically mapped
    if ($itemName -like "*_seeds") {
        # Get the base material name
        $material = $itemName -replace "_seeds", ""
        
        # Metal tiers
        $tier1Metals = @("copper", "tin", "zinc", "nickel", "lead", "aluminum")
        $tier2Metals = @("iron", "steel", "bronze", "brass", "silver", "constantan", "invar", "electrum")
        $tier3Metals = @("gold", "diamond", "emerald", "lapis", "osmium", "uranium", "platinum", "manyullyn")
        $tier4Metals = @("netherite", "enderium", "signalum", "lumium", "draconium", "vibranium")
        $tier5Metals = @("allthemodium", "unobtainium", "gaia", "nether_star", "dragon_egg", "awakened_draconium")
        
        if ($tier1Metals -contains $material) { return 1 }
        if ($tier2Metals -contains $material) { return 2 }
        if ($tier3Metals -contains $material) { return 3 }
        if ($tier4Metals -contains $material) { return 4 }
        if ($tier5Metals -contains $material) { return 5 }
        
        # Default tier for unknown seeds
        return 2
    }
    
    # Default tier for unknown items
    return 2
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
    
    $modHasFarming = $false
    $modDefaultTier = Get-ModDefaultTier -modName $modName
    
    # Create mod plan
    $modPlan = @{
        "blocks" = @{}
        "items" = @{}
        "stats" = @{
            "totalItems" = 0
            "totalBlocks" = 0
            "farmingItems" = 0
            "farmingBlocks" = 0
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
    
    # Process blocks
    $blocksPath = Join-Path -Path $modPmmoPath -ChildPath "blocks"
    if (Test-Path $blocksPath) {
        $blockFiles = Get-ChildItem -Path $blocksPath -Filter "*.json"
        $modPlan.stats.totalBlocks = $blockFiles.Count
        
        foreach ($blockFile in $blockFiles) {
            $blockName = $blockFile.BaseName
            $farmingPlan.stats.blocksAnalyzed++
            
            if (Is-FarmingRelated -name $blockName -modName $modName) {
                $modHasFarming = $true
                $farmingPlan.stats.farmingBlocksFound++
                $modPlan.stats.farmingBlocks++
                
                # Special handling for mystical_agriculture
                if ($modName -eq "mysticalagriculture") {
                    $blockTier = Get-MysticalAgricultureTier -itemName $blockName
                    $matchedKeywords = @("mystical_agriculture:$blockName")
                }
                else {
                    # Start with the mod's default tier
                    $blockTier = $modDefaultTier
                    $matchedKeywords = @()
                    $categoryAdjustment = $false
                    
                    # Get mod-specific tiers if available
                    $tierKeywords = $farmingTiers.Clone()
                    if ($modSpecificTiers.ContainsKey($modName)) {
                        foreach ($keyword in $modSpecificTiers[$modName].Keys) {
                            $tierKeywords[$keyword] = $modSpecificTiers[$modName][$keyword]
                        }
                    }
                    
                    # Check for category indicators first
                    foreach ($category in $farmingCategoryIndicators.Keys) {
                        if ($blockName -like "*$category*") {
                            $minTier = $farmingCategoryIndicators[$category].minTier
                            $maxTier = $farmingCategoryIndicators[$category].maxTier
                            
                            # Adjust tier based on category range
                            if ($blockTier -lt $minTier) {
                                $blockTier = $minTier
                                $categoryAdjustment = $true
                                $matchedKeywords += "category:$category"
                            } elseif ($blockTier -gt $maxTier) {
                                $blockTier = $maxTier
                                $categoryAdjustment = $true
                                $matchedKeywords += "category:$category"
                            }
                        }
                    }
                    
                    # Then check for specific tier keywords
                    foreach ($keyword in $tierKeywords.Keys) {
                        if ($blockName -like "*$keyword*") {
                            $keywordTier = $tierKeywords[$keyword]
                            
                            # Only override if the keyword tier is higher or no category adjustment happened
                            if ($keywordTier -gt $blockTier -or -not $categoryAdjustment) {
                                $blockTier = $keywordTier
                                $matchedKeywords += $keyword
                            }
                        }
                    }
                }
                
                # Calculate actual farming level (0-500 scale)
                $farmingLevel = $blockTier * 100
                if ($farmingLevel -gt 500) { $farmingLevel = 500 }
                
                # Add to plan
                $modPlan.blocks[$blockName] = @{
                    "tier" = $blockTier
                    "farmingLevel" = $farmingLevel
                    "matchedKeywords" = $matchedKeywords
                }
                
                # Update tier distribution
                $modPlan.stats.tierDistribution["tier$blockTier"]++
            }
        }
    }
    
    # Process items
    $itemsPath = Join-Path -Path $modPmmoPath -ChildPath "items"
    if (Test-Path $itemsPath) {
        $itemFiles = Get-ChildItem -Path $itemsPath -Filter "*.json"
        $modPlan.stats.totalItems = $itemFiles.Count
        
        foreach ($itemFile in $itemFiles) {
            $itemName = $itemFile.BaseName
            $farmingPlan.stats.itemsAnalyzed++
            
            if (Is-FarmingRelated -name $itemName -modName $modName) {
                $modHasFarming = $true
                $farmingPlan.stats.farmingItemsFound++
                $modPlan.stats.farmingItems++
                
                # Special handling for mystical_agriculture
                if ($modName -eq "mysticalagriculture") {
                    $itemTier = Get-MysticalAgricultureTier -itemName $itemName
                    $matchedKeywords = @("mystical_agriculture:$itemName")
                }
                else {
                    # Start with the mod's default tier
                    $itemTier = $modDefaultTier
                    $matchedKeywords = @()
                    $categoryAdjustment = $false
                    
                    # Get mod-specific tiers if available
                    $tierKeywords = $farmingTiers.Clone()
                    if ($modSpecificTiers.ContainsKey($modName)) {
                        foreach ($keyword in $modSpecificTiers[$modName].Keys) {
                            $tierKeywords[$keyword] = $modSpecificTiers[$modName][$keyword]
                        }
                    }
                    
                    # Check for category indicators first
                    foreach ($category in $farmingCategoryIndicators.Keys) {
                        if ($itemName -like "*$category*") {
                            $minTier = $farmingCategoryIndicators[$category].minTier
                            $maxTier = $farmingCategoryIndicators[$category].maxTier
                            
                            # Adjust tier based on category range
                            if ($itemTier -lt $minTier) {
                                $itemTier = $minTier
                                $categoryAdjustment = $true
                                $matchedKeywords += "category:$category"
                            } elseif ($itemTier -gt $maxTier) {
                                $itemTier = $maxTier
                                $categoryAdjustment = $true
                                $matchedKeywords += "category:$category"
                            }
                        }
                    }
                    
                    # Then check for specific tier keywords
                    foreach ($keyword in $tierKeywords.Keys) {
                        if ($itemName -like "*$keyword*") {
                            $keywordTier = $tierKeywords[$keyword]
                            
                            # Only override if the keyword tier is higher or no category adjustment happened
                            if ($keywordTier -gt $itemTier -or -not $categoryAdjustment) {
                                $itemTier = $keywordTier
                                $matchedKeywords += $keyword
                            }
                        }
                    }
                }
                
                # Calculate actual farming level (0-500 scale)
                $farmingLevel = $itemTier * 100
                if ($farmingLevel -gt 500) { $farmingLevel = 500 }
                
                # Add to plan
                $modPlan.items[$itemName] = @{
                    "tier" = $itemTier
                    "farmingLevel" = $farmingLevel
                    "matchedKeywords" = $matchedKeywords
                }
                
                # Update tier distribution
                $modPlan.stats.tierDistribution["tier$itemTier"]++
            }
        }
    }
    
    # Add mod to plan if it has farming content
    if ($modHasFarming) {
        $farmingPlan.modPlans[$modName] = $modPlan
        $farmingPlan.stats.modsProcessed++
        
        Write-Host "Found farming content in $modName - Items: $($modPlan.stats.farmingItems), Blocks: $($modPlan.stats.farmingBlocks)" -ForegroundColor Cyan
    }
}

# Save the plan
$farmingPlan | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPlanPath -Encoding UTF8
Write-Host "`nFarming analysis complete!" -ForegroundColor Green
Write-Host "Found farming content in $($farmingPlan.stats.modsProcessed) mods" -ForegroundColor Yellow
Write-Host "Total farming items found: $($farmingPlan.stats.farmingItemsFound)" -ForegroundColor Yellow
Write-Host "Total farming blocks found: $($farmingPlan.stats.farmingBlocksFound)" -ForegroundColor Yellow
Write-Host "Plan saved to: $outputPlanPath" -ForegroundColor Cyan