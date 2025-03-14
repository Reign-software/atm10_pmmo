# Script to analyze mods for alchemy-related content with improved tier assignment
$dataPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data\"
$outputPlanPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\scripts\alchemy\alchemy_progression_plan.json"

# Create progression plan structure
$alchemyPlan = @{
    "modPlans" = @{}
    "generated" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "stats" = @{
        "modsProcessed" = 0
        "itemsAnalyzed" = 0
        "blocksAnalyzed" = 0
        "alchemyItemsFound" = 0
        "alchemyBlocksFound" = 0
    }
}

# Define alchemy-related keywords
$alchemyKeywords = @(
    # Brewing and potions
    "potion", "brew", "brewing", "cauldron", "alchemical", "alchemy", "alchemic", "flask", "vial", "elixir",
    "extract", "concoction", "philter", "philtre", "draught", "tincture", "solution",
    
    # Magical ingredients and components
    "herb", "reagent", "catalyst", "mixture", "tonic", "distill", "extract",
    
    # Specific mod systems
    "thaumcraft", "witchery", "aspectus", "transmutation", "philosopher", "pylon"
)

# Define keyword-to-tier mapping
$alchemyTiers = @{
    # Tier 0 - Basic alchemy
    "basic" = 0
    "simple" = 0
    "crude" = 0
    "common" = 0
    "mundane" = 0
    "minor" = 0
    "weak" = 0
    
    # Tier 1 - Intermediate alchemy
    "standard" = 1
    "normal" = 1
    "regular" = 1
    "improved" = 1
    "enhanced" = 1
    "uncommon" = 1
    
    # Tier 2 - Advanced alchemy
    "greater" = 2
    "refined" = 2
    "potent" = 2
    "strong" = 2
    "advanced" = 2
    "rare" = 2
    
    # Tier 3 - Master alchemy
    "superior" = 3
    "master" = 3
    "major" = 3
    "exceptional" = 3
    "excellent" = 3
    "epic" = 3
    
    # Tier 4 - Legendary alchemy
    "legendary" = 4
    "ultimate" = 4
    "supreme" = 4
    "perfect" = 4
    "mythical" = 4
    
    # Tier 5 - Godly alchemy
    "divine" = 5
    "godly" = 5
    "transcendent" = 5
    "cosmic" = 5
    "infinity" = 5
}

# Define mod-specific keyword tiers
$modSpecificTiers = @{
    # Minecraft potion progression path
    "minecraft" = @{
        # Brewing equipment - progression path
        "brewing_stand" = 0   # Starting point
        "cauldron" = 0        # Basic item
        "fermented" = 1       # Intermediate ingredient
        "rabbit_foot" = 1     # Intermediate ingredient
        "magma_cream" = 1     # Intermediate ingredient
        "ghast_tear" = 2      # Advanced ingredient
        "blaze_powder" = 1    # Nether ingredient
        "glistering_melon" = 1 # Intermediate ingredient
        "golden_carrot" = 1   # Intermediate ingredient
        "pufferfish" = 1      # Intermediate ingredient
        
        # Potion base types - progressive complexity
        "water_bottle" = 0    # Starting point
        "awkward" = 0         # Base potion
        "thick" = 0           # Base potion
        "mundane" = 0         # Base potion
        
        # Effect potions - tier by effect power
        "healing" = 1        # Basic effect
        "night_vision" = 1   # Basic effect
        "swiftness" = 1      # Basic effect
        "leaping" = 1        # Basic effect
        "fire_resistance" = 1 # Basic effect
        "slow_falling" = 1   # Basic effect
        "water_breathing" = 1 # Basic effect
        "invisibility" = 2   # Advanced effect
        "strength" = 2       # Advanced effect
        "regeneration" = 2   # Advanced effect
        "turtle_master" = 3  # Complex effect
        
        # Modifiers - increasing complexity
        "extended" = 1       # Basic modifier
        "strong" = 2         # Advanced modifier
        
        # Delivery methods - increasing complexity
        "splash" = 1         # Basic delivery
        "lingering" = 2      # Advanced delivery
    }
}

# Default tier assignment by mod (for mods without specific keywords in items)
$modDefaultTiers = @{
    "minecraft" = 1
    "theurgy" = 2
    "ars_nouveau" = 3
    "mysticalagriculture" = 2
    "forbidden_arcanus" = 3
    "botania" = 2
    "occultism" = 2
    "evilcraft" = 2
    "irons_spellbooks" = 2
    "tombstone" = 3
    "reliquary" = 3
    "mahoutsukai" = 3
    "potionsmaster" = 2
    "apothic_enchanting" = 3
    "herbsandharvest" = 1
    "crystalix" = 2
    "rootsclassic" = 1
    "pylon" = 3  # Setting pylon mod to tier 3 (300 alchemy)
    "pylons" = 3  # Alternative name that might be used
}

# Alchemy category indicators (certain keywords that indicate specific tier ranges)
$alchemyCategoryIndicators = @{
    # Processing/equipment (generally higher tier)
    "distill" = @{minTier = 2; maxTier = 4}
    "cauldron" = @{minTier = 1; maxTier = 3}
    "altar" = @{minTier = 2; maxTier = 4}
    "ritual" = @{minTier = 2; maxTier = 5}
    "extract" = @{minTier = 1; maxTier = 3}
    
    
    # Completed items (generally higher tier)
    "potion" = @{minTier = 0; maxTier = 3}
    "elixir" = @{minTier = 2; maxTier = 4}
    "tonic" = @{minTier = 1; maxTier = 3}
    
    
    # Pylon specific
    "pylon" = @{minTier = 3; maxTier = 5}
}

# Function to determine if item/block is alchemy-related
function Is-AlchemyRelated {
    param ([string]$name, [string]$modName)
    
    # Special case for pylon mod - all items should be considered alchemy-related
    if ($modName -eq "pylon" -or $modName -eq "pylons") {
        return $true
    }
    
    # Special case for minecraft brewing items
    if ($modName -eq "minecraft" -and 
        ($name -like "*potion*" -or $name -like "*brewing*" -or 
         $name -like "*cauldron*" -or $name -like "*blaze*" -or
         $name -like "*lingering*" -or $name -like "*splash*" -or
         $name -like "*fermented*" -or $name -like "*spider_eye*" -or
         $name -like "*ghast_tear*" -or $name -like "*magma_cream*" -or
         $name -like "*rabbit_foot*" -or $name -like "*glistering_melon*" -or
         $name -like "*golden_carrot*" -or $name -like "*pufferfish*" -or
         $name -like "*phantom_membrane*" -or $name -like "*nether_wart*")) {
        return $true
    }
    
    # General keyword matching for other mods
    foreach ($keyword in $alchemyKeywords) {
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
    return 1
}

# Function to enforce minimum alchemy level for specific mods
function Enforce-MinimumAlchemyLevel {
    param (
        [string]$modName,
        [int]$currentLevel
    )
    
    # Enforce minimum of 300 for pylon mod
    if (($modName -eq "pylon" -or $modName -eq "pylons") -and $currentLevel -lt 300) {
        return 300
    }
    
    return $currentLevel
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
    
    $modHasAlchemy = $false
    $modDefaultTier = Get-ModDefaultTier -modName $modName
    
    # Create mod plan
    $modPlan = @{
        "blocks" = @{}
        "items" = @{}
        "stats" = @{
            "totalItems" = 0
            "totalBlocks" = 0
            "alchemyItems" = 0
            "alchemyBlocks" = 0
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
            $alchemyPlan.stats.blocksAnalyzed++
            
            if (Is-AlchemyRelated -name $blockName -modName $modName) {
                $modHasAlchemy = $true
                $alchemyPlan.stats.alchemyBlocksFound++
                $modPlan.stats.alchemyBlocks++
                
                # Start with the mod's default tier
                $blockTier = $modDefaultTier
                $matchedKeywords = @()
                $categoryAdjustment = $false
                
                # Get mod-specific tiers if available
                $tierKeywords = $alchemyTiers.Clone()
                if ($modSpecificTiers.ContainsKey($modName)) {
                    foreach ($keyword in $modSpecificTiers[$modName].Keys) {
                        $tierKeywords[$keyword] = $modSpecificTiers[$modName][$keyword]
                    }
                }
                
                # Check for category indicators first (e.g., altar, cauldron)
                foreach ($category in $alchemyCategoryIndicators.Keys) {
                    if ($blockName -like "*$category*") {
                        $minTier = $alchemyCategoryIndicators[$category].minTier
                        $maxTier = $alchemyCategoryIndicators[$category].maxTier
                        
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
                
                # Calculate actual alchemy level (0-500 scale)
                $alchemyLevel = $blockTier * 100
                if ($alchemyLevel -gt 500) { $alchemyLevel = 500 }
                
                # Enforce mod-specific minimum levels
                $alchemyLevel = Enforce-MinimumAlchemyLevel -modName $modName -currentLevel $alchemyLevel
                
                # Add to plan
                $modPlan.blocks[$blockName] = @{
                    "tier" = $blockTier
                    "alchemyLevel" = $alchemyLevel
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
            $alchemyPlan.stats.itemsAnalyzed++
            
            if (Is-AlchemyRelated -name $itemName -modName $modName) {
                $modHasAlchemy = $true
                $alchemyPlan.stats.alchemyItemsFound++
                $modPlan.stats.alchemyItems++
                
                # Start with the mod's default tier
                $itemTier = $modDefaultTier
                $matchedKeywords = @()
                $categoryAdjustment = $false
                
                # Get mod-specific tiers if available
                $tierKeywords = $alchemyTiers.Clone()
                if ($modSpecificTiers.ContainsKey($modName)) {
                    foreach ($keyword in $modSpecificTiers[$modName].Keys) {
                        $tierKeywords[$keyword] = $modSpecificTiers[$modName][$keyword]
                    }
                }
                
                # Check for category indicators first (e.g., potion, essence)
                foreach ($category in $alchemyCategoryIndicators.Keys) {
                    if ($itemName -like "*$category*") {
                        $minTier = $alchemyCategoryIndicators[$category].minTier
                        $maxTier = $alchemyCategoryIndicators[$category].maxTier
                        
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
                
                # Calculate actual alchemy level (0-500 scale)
                $alchemyLevel = $itemTier * 100
                if ($alchemyLevel -gt 500) { $alchemyLevel = 500 }
                
                # Enforce mod-specific minimum levels
                $alchemyLevel = Enforce-MinimumAlchemyLevel -modName $modName -currentLevel $alchemyLevel
                
                # Add to plan
                $modPlan.items[$itemName] = @{
                    "tier" = $itemTier
                    "alchemyLevel" = $alchemyLevel
                    "matchedKeywords" = $matchedKeywords
                }
                
                # Update tier distribution
                $modPlan.stats.tierDistribution["tier$itemTier"]++
            }
        }
    }
    
    # Add mod to plan if it has alchemy content
    if ($modHasAlchemy) {
        $alchemyPlan.modPlans[$modName] = $modPlan
        $alchemyPlan.stats.modsProcessed++
        
        Write-Host "Found alchemy content in $modName - Items: $($modPlan.stats.alchemyItems), Blocks: $($modPlan.stats.alchemyBlocks)" -ForegroundColor Cyan
    }
}

# Save the plan
$alchemyPlan | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPlanPath -Encoding UTF8
Write-Host "`nAlchemy analysis complete!" -ForegroundColor Green
Write-Host "Found alchemy content in $($alchemyPlan.stats.modsProcessed) mods" -ForegroundColor Yellow
Write-Host "Total alchemy items found: $($alchemyPlan.stats.alchemyItemsFound)" -ForegroundColor Yellow
Write-Host "Total alchemy blocks found: $($alchemyPlan.stats.alchemyBlocksFound)" -ForegroundColor Yellow
Write-Host "Plan saved to: $outputPlanPath" -