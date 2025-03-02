# Enhanced PowerShell script to modify mining ore JSON files for PMMO
$rootPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data"

# Define mod folders to check - expanded list based on UnknownOreSuggestions
$modFolders = @(
    # Original mods
    "minecraft",
    "mekanism",
    "thermal",
    "create",
    "immersiveengineering",
    "alltheores",
    "allthemodium",
    "biggerreactors",
    "bigreactors",
    "powah",
    "silentgear",
    "silentgems",
    "ae2",
    "extendedcrafting",
    "industrialforegoing",
    "tinkers",
    "tconstruct",
    "botania",
    "blue_skies",
    "twilightforest",
    "undergarden",
    "beyond_earth",
    "mysticalagriculture",
    "rftools",
    
    # Added mods from UnknownOreSuggestions
    "integrateddynamics",
    "ironfurnaces",
    "irons_spellbooks",
    "mcwpaths",
    "luminax",
    "modern_industrialization",
    "evilcraft",
    "eternal_starlight",
    "extendedae",
    "forbidden_arcanus",
    "factory_blocks",
    "herbsandharvest",
    "rechiseled",
    "railcraft",
    "productivetrees",
    "productivebees",
    "securitycraft",
    "xycraft_world",
    "theurgy",
    "the_bumblezone",
    "stevescarts",
    "supplementaries",
    "mysticalagradditions",
    "occultism",
    "justdirethings",
    "cataclysm"
)

# Auto-discover all mod folders if possible
try {
    $availableMods = Get-ChildItem -Path $rootPath -Directory | Select-Object -ExpandProperty Name
    if ($availableMods.Count -gt $modFolders.Count) {
        Write-Host "Found $(($availableMods | Measure-Object).Count) mods in the data directory." -ForegroundColor Green
        $modFolders = $availableMods
    }
} catch {
    Write-Host "Using predefined mod list." -ForegroundColor Yellow
}

$oreJsonPaths = @()
foreach ($mod in $modFolders) {
    $modPath = Join-Path -Path $rootPath -ChildPath "$mod\pmmo"
    if (Test-Path $modPath) {
        $oreJsonPaths += $modPath
    }
}

Write-Host "Scanning directories:" -ForegroundColor Cyan
$oreJsonPaths | ForEach-Object { Write-Host "  $_" }

# Configuration values
$baseMiningLevel = 0       # Base mining level required
$levelIncreasePerTier = 50 # Level requirement increase per tier (0, 50, 100, 150, etc.)
# Note: XP is now defined in the tier mapping below instead of a multiplier

# Define keyword-to-tier mapping for ores with 11 tiers (0-10)
$oreTiers = @{
    # Tier 0 - Stone and Common Materials (Level 0, 10 XP)
    "stone" = 0
    "granite" = 0
    "diorite" = 0
    "andesite" = 0
    "deepslate" = 0
    "tuff" = 0
    "gravel" = 0
    "dirt" = 0
    "sand" = 0
    "sandstone" = 0
    "netherrack" = 0
    
    # Tier 1 - Basic Ores (Level 50, 15 XP)
    "coal_ore" = 1
    "iron_ore" = 1
    "copper_ore" = 1
    "tin_ore" = 1
    "clay" = 1
    
    # Tier 2 - Intermediate Ores (Level 100, 20 XP)
    "gold_ore" = 2
    "redstone_ore" = 2
    "lead_ore" = 2
    "zinc_ore" = 2
    "bauxite" = 2         # Aluminum ore variant
    "crystalized_menril" = 2         # IntegratedDynamics crystal block
    "crystalized_chorus" = 2         # IntegratedDynamics crystal block
    "crystal_quartz" = 2             # SecurityCraft materials
    "reinforced_crystal_quartz" = 2  # SecurityCraft materials
    "chiseled_crystal_quartz" = 2    # SecurityCraft materials
    "smooth_crystal_quartz" = 2      # SecurityCraft materials
    "fluorite_ore" = 2               # Mekanism ore
    "deepslate_fluorite_ore" = 2     # Mekanism ore
    "sal_ammoniac_ore" = 2           # Theurgy ore
    "deepslate_sal_ammoniac_ore" = 2 # Theurgy ore
    "bort_ore" = 2                   # SilentGear ore
    "deepslate_bort_ore" = 2         # SilentGear ore
    
    # Tier 3 - Advanced Overworld Ores (Level 150, 30 XP)
    "lapis_ore" = 3
    "aluminum_ore" = 3
    "silver_ore" = 3
    "nickel_ore" = 3
    "quartz_ore" = 3
    "apatite_ore" = 3
    "sulfur_ore" = 3
    "niter_ore" = 3
    "antimony_ore" = 3               # Modern Industrialization ore
    "deepslate_antimony_ore" = 3     # Modern Industrialization ore
    "bauxite_ore" = 3                # Modern Industrialization ore
    "deepslate_bauxite_ore" = 3      # Modern Industrialization ore
    "monazite_ore" = 3               # Modern Industrialization ore
    "deepslate_monazite_ore" = 3     # Modern Industrialization ore
    "salt_ore" = 3                   # Modern Industrialization ore
    "deepslate_salt_ore" = 3         # Modern Industrialization ore
    "dark_ore" = 3                   # EvilCraft ore
    "dark_ore_deepslate" = 3         # EvilCraft ore
    "deepslate_sulfur_ore" = 3       # Railcraft ore
    
    # Tier 4 - Nether Resources (Level 200, 40 XP)
    "nether_gold_ore" = 4
    "nether_quartz_ore" = 4
    "glowstone" = 4
    "cinnabar_ore" = 4
    "bitumen" = 4
    "certus_quartz" = 4      # Applied Energistics
    "charged_certus" = 4     # Applied Energistics
    "iesnium_ore" = 4                # Occultism ore
    "iesnium_ore_natural" = 4        # Occultism ore
    "deepslate_nickel_ore" = 4       # Multiple mods
    "deepslate_zinc_ore" = 4         # Railcraft ore
    
    # Tier 5 - Precious Materials (Level 250, 60 XP)
    "diamond_ore" = 5
    "emerald_ore" = 5
    "sapphire_ore" = 5
    "ruby_ore" = 5
    "amethyst" = 5
    "tungsten_ore" = 5               # Modern Industrialization ore
    "deepslate_tungsten_ore" = 5     # Modern Industrialization ore
    "titanium_ore" = 5               # Modern Industrialization ore
    "arcane_crystal_ore" = 5         # Forbidden Arcanus ore
    "deepslate_arcane_crystal_ore" = 5 # Forbidden Arcanus ore
    "uraninite_ore" = 5              # Powah ore
    "uraninite_ore_poor" = 5         # Powah ore
    "uraninite_ore_dense" = 5        # Powah ore variant
    "deepslate_uraninite_ore" = 5    # Powah ore 
    "deepslate_uraninite_ore_poor" = 5 # Powah ore
    "deepslate_uraninite_ore_dense" = 5 # Powah ore variant
    
    # Tier 6 - Industrial Resources (Level 300, 80 XP)
    "uranium_ore" = 6
    "platinum_ore" = 6
    "osmium_ore" = 6
    "iridium_ore" = 6
    "fluix" = 6             # Applied Energistics
    "saltpeter_ore" = 6              # Railcraft ore
    "inferium_ore" = 6               # Mystical Agriculture progression ore
    "deepslate_inferium_ore" = 6     # Mystical Agriculture progression ore
    "prosperity_ore" = 6             # Mystical Agriculture progression ore
    "deepslate_prosperity_ore" = 6   # Mystical Agriculture progression ore
    
    # Tier 7 - Exotic Materials (Level 350, 100 XP)
    "ancient_debris" = 7
    "crimson_iron" = 7       # Silent Gear
    "azure_silver" = 7       # Silent Gear
    "cobalt_ore" = 7
    "resource_" = 7          # Mekanism prefix
    "nether_inferium_ore" = 7        # Mystical Agradditions nether ore
    "nether_prosperity_ore" = 7      # Mystical Agradditions nether ore
    "mithril_ore" = 7                # Iron's Spellbooks rare ore
    "deepslate_mithril_ore" = 7      # Iron's Spellbooks rare ore
    
    # Tier 8 - End and Dimensional Resources (Level 400, 120 XP)
    "end_stone" = 8
    "draconium_ore" = 8
    "allthemodium_ore" = 8
    "allthemodium" = 8
    "yellorite_ore" = 8
    "anglesite_ore" = 8              # BigReactors rare ore
    "benitoite_ore" = 8              # BigReactors rare ore
    "end_inferium_ore" = 8           # Mystical Agradditions end ore
    "end_prosperity_ore" = 8         # Mystical Agradditions end ore
    "haze_ice_atalphaite_ore" = 8    # Eternal Starlight dimensional ore
    "eternal_ice_atalphaite_ore" = 8 # Eternal Starlight dimensional ore
    "haze_ice_saltpeter_ore" = 8     # Eternal Starlight dimensional ore
    "eternal_ice_saltpeter_ore" = 8  # Eternal Starlight dimensional ore
    
    # Tier 9 - Rare Dimensional Materials (Level 450, 150 XP)
    "vibranium_ore" = 9
    "vibranium" = 9
    "resonant_end_stone" = 9 # Thermal
    "benitoite" = 9         # Extreme Reactors
    "adamantite_ore" = 9
    "aluminum_ore_kivi" = 9          # Xycraft World rare dimensional ore
    "xychorium_ore_deepslate_blue" = 9 # Xycraft World rare ore
    "xychorium_ore_deepslate_green" = 9 # Xycraft World rare ore
    "xychorium_ore_deepslate_light" = 9 # Xycraft World rare ore
    "xychorium_ore_deepslate_red" = 9 # Xycraft World rare ore
    "xychorium_ore_deepslate_dark" = 9 # Xycraft World rare ore
    "xychorium_ore_kivi_blue" = 9    # Xycraft World rare ore
    "xychorium_ore_kivi_dark" = 9    # Xycraft World rare ore
    "xychorium_ore_kivi_green" = 9   # Xycraft World rare ore
    "xychorium_ore_kivi_light" = 9   # Xycraft World rare ore
    "xychorium_ore_kivi_red" = 9     # Xycraft World rare ore
    "soulium_ore" = 9                # Mystical Agriculture rare ore
    
    # Tier 10 - Mythical Materials (Level 500, 200 XP)
    "unobtainium_ore" = 10
    "unobtainium" = 10
    "infinity_ore" = 10
    "nether_star_ore" = 10
    "awakened_draconium_ore" = 10
    "chaotic_ore" = 10
    "creative" = 10           # Creative tier items
    "netherstar" = 10
    "dragon_egg" = 10
    "time_crystal" = 10              # Just Dire Things mythical crystals
    "time_crystal_block" = 10        # Just Dire Things mythical crystals
    "time_crystal_budding_block" = 10 # Just Dire Things mythical crystals
    "time_crystal_cluster" = 10      # Just Dire Things mythical crystals
    "celestigem_block" = 10          # Just Dire Things mythical gems
    "raw_celestigem_ore" = 10        # Just Dire Things mythical ore
    "raw_eclipsealloy_ore" = 10      # Just Dire Things mythical ore
    "void_crystal" = 10              # Cataclysm mythical crystal
    "ancient_metal_block" = 10       # Cataclysm endgame material
    "nitro_crystal_crux" = 10        # Mystical Agradditions endgame material
    
    # Quality variants
    "poor_" = -1              # Lower-quality ore variants (reduce tier by 1)
    "normal_" = 0             # Normal quality variants (no change)
    "dense_" = 1              # Higher density variants (increase tier by 1)
    "rich_" = 2               # Rich ore variants (increase tier by 2)
}

# Add support for variants with these prefixes/suffixes - now they directly adjust tiers
$prefixModifiers = @{
    "deepslate_" = 1       # Deepslate variants are one tier higher
    "raw_" = 0             # No change for raw variants
    "nether_" = 1          # Higher tier for nether variants
    "end_" = 2             # Even higher for end variants
}

$suffixModifiers = @{
    "_cluster" = 1         # Clusters one tier higher than normal ore
    "_deposit" = 0         # Deposits same as normal ore
    "_shard" = -1          # Shards one tier lower than normal ore
    "_dust" = -2           # Dusts two tiers lower than ore
}

# Define XP values for each tier - increasing in a more balanced way
$tierXPValues = @(10, 15, 20, 30, 40, 60, 80, 100, 120, 200, 400)

# Special case handling for specific crystal blocks
$crystalBlocks = @{
    # Crystal growth/variants in different tiers
    "spirited_crystal_block" = 8     # Powah
    "niotic_crystal_block" = 7       # Powah
    "blazing_crystal_block" = 6      # Powah
    "nitro_crystal_block" = 9        # Powah
    
    # Starlight crystals from Eternal Starlight
    "blue_starlight_crystal_cluster" = 7
    "red_starlight_crystal_cluster" = 7
    "blooming_blue_starlight_crystal_cluster" = 8
    "blooming_red_starlight_crystal_cluster" = 8
    "blue_starlight_crystal_block" = 7
    "red_starlight_crystal_block" = 7
    
    # Honey crystals from The Bumblezone
    "honey_crystal" = 5
    "glistering_honey_crystal" = 6
    "crystalline_flower" = 5
}

# Counter for tracking processed files
$processedCount = 0
$modifiedCount = 0
$statsPerTier = @(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

# Process all JSON files in the specified directories
$jsonFiles = Get-ChildItem -Path $oreJsonPaths -Filter "*.json" -Recurse

foreach ($file in $jsonFiles) {
    $processedCount++
    $modified = $false
    $fileName = $file.BaseName.ToLower()
    $isOre = $false
    $tier = -1
    $tierModifier = 0

    # Check if this is an ore file by looking for keywords in the name
    foreach ($keyword in $oreTiers.Keys) {
        if ($fileName -match $keyword) {
            $keywordTier = $oreTiers[$keyword]
            
            # For quality modifiers like "poor_", "rich_", etc., apply as a modifier
            if ($keyword -match "^(poor_|normal_|dense_|rich_)$") {
                $tierModifier += $keywordTier
            } else {
                # For regular ore types, set the base tier
                $tier = $keywordTier
                $isOre = $true
            }
            
            # Check for prefix modifiers
            foreach ($prefix in $prefixModifiers.Keys) {
                if ($fileName -match "^$prefix") {
                    $tierModifier += $prefixModifiers[$prefix]
                    break
                }
            }
            
            # Check for suffix modifiers
            foreach ($suffix in $suffixModifiers.Keys) {
                if ($fileName -match "$suffix$") {
                    $tierModifier += $suffixModifiers[$suffix]
                    break
                }
            }
            
            if ($isOre) {
                Write-Host "Found ore: $($file.Name) (Base Tier $tier, Modifier $tierModifier)" -ForegroundColor Yellow
                break
            }
        }
    }

    # Special case handling for specific crystal blocks
    foreach ($block in $crystalBlocks.Keys) {
        if ($fileName -match $block) {
            $tier = $crystalBlocks[$block]
            $isOre = $true
            break
        }
    }

    # If it's not recognized as an ore by name but has "ore" in the name, default to tier 1
    if (-not $isOre -and ($fileName -match "ore" -or $fileName -match "vein" -or $fileName -match "deposit")) {
        $isOre = $true
        $tier = 1  # Basic ores start at tier 1
        Write-Host "Found unclassified ore: $($file.Name) (Default Tier $tier)" -ForegroundColor Yellow
    }

    if ($isOre) {
        # Apply tier modifier but keep within valid range
        $adjustedTier = [Math]::Max(0, [Math]::Min(10, $tier + $tierModifier))
        
        # Calculate values based on adjusted tier
        $miningLevel = $baseMiningLevel + ($adjustedTier * $levelIncreasePerTier)
        $breakXP = $tierXPValues[$adjustedTier]
        
        # Read the JSON content
        try {
            $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            
            # Check if xp_values exists
            if (-not $jsonContent.PSObject.Properties["xp_values"]) {
                $jsonContent | Add-Member -NotePropertyName "xp_values" -NotePropertyValue @{}
                $modified = $true
            }
            
            # Check if xp_values.BLOCK_BREAK exists
            if (-not $jsonContent.xp_values.PSObject.Properties["BLOCK_BREAK"]) {
                $jsonContent.xp_values | Add-Member -NotePropertyName "BLOCK_BREAK" -NotePropertyValue @{}
                $modified = $true
            }
            
            # Add/update mining XP value
            if (-not $jsonContent.xp_values.BLOCK_BREAK.PSObject.Properties["mining"] -or 
                $jsonContent.xp_values.BLOCK_BREAK.mining -ne $breakXP) {
                $jsonContent.xp_values.BLOCK_BREAK | Add-Member -NotePropertyName "mining" -NotePropertyValue $breakXP -Force
                $modified = $true
                Write-Host "  Setting mining XP: $breakXP" -ForegroundColor Cyan
            }
            
            # Check if requirements exists
            if (-not $jsonContent.PSObject.Properties["requirements"]) {
                $jsonContent | Add-Member -NotePropertyName "requirements" -NotePropertyValue @{}
                $modified = $true
            }
            
            # Check if requirements.BREAK exists
            if (-not $jsonContent.requirements.PSObject.Properties["BREAK"]) {
                $jsonContent.requirements | Add-Member -NotePropertyName "BREAK" -NotePropertyValue @{}
                $modified = $true
            }
            
            # Add/update mining level requirement if it's tier 1 or higher
            if ($adjustedTier -ge 1) {
                if (-not $jsonContent.requirements.BREAK.PSObject.Properties["mining"] -or 
                    $jsonContent.requirements.BREAK.mining -ne $miningLevel) {
                    $jsonContent.requirements.BREAK | Add-Member -NotePropertyName "mining" -NotePropertyValue $miningLevel -Force
                    $modified = $true
                    Write-Host "  Setting mining requirement: $miningLevel" -ForegroundColor Magenta
                }
            }
            
            # Save changes if any modifications were made
            if ($modified) {
                $jsonContent | ConvertTo-Json -Depth 20 | Set-Content -Path $file.FullName
                Write-Host "Updated: $($file.Name)" -ForegroundColor Green
                $modifiedCount++
            } else {
                Write-Host "No changes needed for: $($file.Name)" -ForegroundColor DarkGray
            }
            
            # Update statistics
            $statsPerTier[$adjustedTier]++
        }
        catch {
            Write-Host "Error processing $($file.FullName): $_" -ForegroundColor Red
        }
    }
}

Write-Host "Processing complete!" -ForegroundColor Cyan
Write-Host "Files processed: $processedCount" -ForegroundColor White
Write-Host "Files modified: $modifiedCount" -ForegroundColor Green

# Mining Level Summary
Write-Host "`nMining Level Requirements:" -ForegroundColor Cyan
for ($i = 0; $i -le 10; $i++) {
    $level = $baseMiningLevel + ($i * $levelIncreasePerTier)
    $xp = $tierXPValues[$i]
    Write-Host "Tier $i : Level $level required, $xp XP per ore (Found: $($statsPerTier[$i]))" -ForegroundColor Yellow
}
