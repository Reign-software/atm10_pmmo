# Script to analyze and update item requirements for armor, tools, and weapons

# Define root path for data
$rootPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data"

# Get all mod directories
$modDirs = Get-ChildItem -Path $rootPath -Directory

# Set up counters for stats
$processedCount = 0
$modifiedCount = 0
$itemTypes = @{
    "armor" = 0
    "tool" = 0
    "weapon" = 0
    "tech" = 0
    "magic" = 0
    "other" = 0
}

# Define tier levels and their requirements
$tierLevels = @(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500)

# Define item type patterns
$armorPatterns = @(
    "helmet", "chestplate", "leggings", "boots", "armor", "suit", "_helm", 
    "_chest", "_legs", "_boots", "cuirass", "gauntlet", "greaves", "crown", "robe", "gear"
)

# Enhanced tool patterns with more specific matches to avoid false positives
$toolPatterns = @{
    "pickaxe" = @("pickaxe", "_pick", "_pick_", "pick_", "miner", "paxel")
    "axe" = @("_axe", "axe_", "_axe_", "hatchet", "chopper", "lumber", "felling")
    "shovel" = @("shovel", "spade", "excavator", "digger")
    "hoe" = @("_hoe", "hoe_", "_hoe_", "scythe", "tiller", "cultivator")
    "shears" = @("shears", "cutter", "clippers", "scissors")
}

# Add specific patterns for multi-tools that aren't caught by "paxel"
$multiToolPatterns = @(
    "atomic_disassembler", "omni_tool", "dread_excavator", 
    "ultimine", "aiot", "multi_tool", "multitool", "all_in_one"
)

# Enhanced weapon detection to handle specialized weapon types
$weaponPatterns = @(
    "sword", "dagger", "blade", "knife", "mace", "hammer", "axe", 
    "staff", "wand", "bow", "crossbow", "gun", "rifle", "launcher", 
    "weapon", "katana", "scythe", "rapier", "cleaver", "glaive", 
    "halberd", "battleaxe", "greatsword", "spear", "pike", "javelin",
    "shuriken", "trident", "sickle", "flail", "chakram"
)

# Expanded archery detection
$archeryPatterns = @(
    "bow", "arrow", "crossbow", "bolt", "quiver", 
    "longbow", "shortbow", "compound_bow", "recurve"
)

# Enhanced tech detection with mod-specific patterns
$techPatterns = @(
    # General tech patterns
    "meka", "quantum", "jetpack", "module", "augment", "circuit", "capacitor",
    "battery", "reactor", "atomic", "power", "energy", "drill", "electric",
    "mech", "nano", "flux", "laser", "industrial", "machine", "generator",
    "turbine", "motor", "engine", "pump", "cable", "pipe", "conduit", "cell",
    
    # Mod-specific tech items that might not match general patterns
    "disassembler", "configurator", "entangler", "excavator",
    "seismic", "teleporter", "portable_tank", "robit", "network_reader",
    "gas_tank", "fluid_tank", "resonator", "upgrade"
)

# Enhanced magic detection with more patterns
$magicPatterns = @(
    # General magic patterns
    "arcane", "mystic", "magic", "enchanted", "sorcery", "wizard", "witch",
    "warlock", "mana", "soul", "spirit", "elemental", "scroll", "tome",
    "grimoire", "rune", "ritual", "spell", "aura", "essence", "glyph",
    
    # Mod-specific magic items
    "source", "familiar", "charm", "talisman", "totem", "wand", "focus",
    "ritual", "psi", "blood_orb", "soulium", "starbeam", "stellarite",
    "occult", "runic", "forbidden", "ethereal", "astral", "constellation",
    "celestial", "eldritch", "void", "thaumic", "infusion"
)

# Define mod categories for more accurate item classification
$techMods = @(
    "mekanism", "thermal", "immersiveengineering", "industrialforegoing", 
    "create", "ae2", "extendedae", "powah", "rftoolspower", "rftoolsutility", 
    "rftoolscontrol", "rftoolsbuilder", "rftoolsbase", "fluxnetworks",
    "pneumaticcraft", "moderndynamics", "pipez", "ironjetpacks", "modern_industrialization",
    "biggerreactors", "bigreactors", "modular_machinery_reborn", "extended_industrialization",
    "xnet", "sfm", "megacells", "integratedtunnels", "integrateddynamics", "laserio",
    "wireleschargers", "wirelessdimmers", "modularrouters", "stevescarts"
)

$magicMods = @(
    "botania", "twilightforest", "ars_nouveau", "forbidden_arcanus", 
    "ars_elemental", "occultism", "evilcraft", "naturesaura", "rootsclassic",
    "irons_spellbooks", "ars_additions", "mahoutsukai", "toomanyglyphs",
    "ars_scalaes", "relics", "reliquary", "crystalix", "theurgy", "arsomega",
    "not_enough_glyphs", "arseng", "ars_omega", "cataclysm"
)

# Define skill requirements per item type
function Get-SkillRequirements {
    param(
        [string]$itemType,
        [int]$tier,
        [bool]$isTech = $false,
        [bool]$isMagic = $false
    )
    
    # Base level for specified tier
    $baseLevel = $tierLevels[$tier]
    
    # Return requirements based on item type
    switch ($itemType) {
        "pickaxe" { 
            $result = @{
                "smithing" = $baseLevel
                "mining" = $baseLevel
            }
        }
        "axe" { 
            $result = @{
                "smithing" = $baseLevel
                "woodcutting" = $baseLevel
            }
        }
        "shovel" { 
            $result = @{
                "smithing" = $baseLevel
                "excavation" = $baseLevel
            }
        }
        "hoe" { 
            $result = @{
                "smithing" = $baseLevel
                "farming" = $baseLevel
            }
        }
        "shears" { 
            $result = @{
                "smithing" = $baseLevel
                "farming" = [Math]::Max(0, $baseLevel - 50)
            }
        }
        "paxel" { 
            # Paxel is a special case - combine pickaxe, axe, and shovel requirements
            $result = @{
                "smithing" = $baseLevel
                "mining" = $baseLevel
                "woodcutting" = $baseLevel
                "excavation" = $baseLevel
            }
        }
        "weapon" { 
            $result = @{
                "smithing" = $baseLevel
                "combat" = $baseLevel
            }
            # Add archery requirement for bows and crossbows
            if ($fileName -match "bow" -or $fileName -match "arrow") {
                $result.Remove("combat")
                $result["archery"] = $baseLevel
            }
        }
        "armor" { 
            $result = @{
                "smithing" = $baseLevel
                "endurance" = $baseLevel
            }
        }
        default {
            $result = @{
                "smithing" = $baseLevel
            }
        }
    }
    
    # Add technology skill if it's a tech item
    if ($isTech) {
        $result["technology"] = $baseLevel
    }
    
    # Add magic skill if it's a magic item
    if ($isMagic) {
        $result["magic"] = $baseLevel
    }
    
    return $result
}

# Function to determine tier based on item name and material - enhanced to handle overlapping material names
function Get-ItemTier {
    param([string]$itemName)
    
    # Define material tiers
    $materialTiers = @{
        # Tier 0 - Wood, Leather, Stone
        0 = @("wooden", "wood", "stone", "leather", "flint", "bone")
        
        # Tier 1 - Iron, Chain, Copper
        1 = @("iron", "chainmail", "chain", "copper", "bronze", "brass", "steel")
        
        # Tier 2 - Gold, Silver, Electrum
        2 = @("gold", "silver", "electrum", "invar", "nickel")
        
        # Tier 3 - Diamond, Emerald, Ruby
        3 = @("diamond", "emerald", "ruby", "sapphire", "topaz", "amethyst", "quartz", "obsidian")
        
        # Tier 4 - Netherite, Platinum
        4 = @("netherite", "platinum", "osmium", "titanium", "tungsten")
        
        # Tier 5 - Enhanced Materials
        5 = @("reinforced", "enhanced", "refined", "iridium", "vibranium", "signalum", "lumium", "enderium")
        
        # Tier 6 - Allthemodium
        6 = @("allthemodium", "allthemod", "crimson_iron", "azure_silver")
        
        # Tier 7 - Vibranium
        7 = @("vibranium", "elementium", "terrasteel")
        
        # Tier 8 - Unobtainium
        8 = @("unobtainium", "unobtanium", "draconium")
        
        # Tier 9 - Advanced Materials
        9 = @("awakened", "chaotic", "stellar", "infinity")
        
        # Tier 10 - Ultimate/Creative Materials
        10 = @("creative", "ultimate", "cosmic", "universal", "infinity")
    }
    
    # Handle special cases first
    if ($itemName -match "creative" -or $itemName -match "ultimate" -or $itemName -match "infinity") {
        return 10
    }
    
    if ($itemName -match "awakened" -or $itemName -match "chaotic" -or $itemName -match "stellar") {
        return 9
    }
    
    # Check each tier's materials, starting from highest tier
    for ($i = 10; $i -ge 0; $i--) {
        foreach ($material in $materialTiers[$i]) {
            # More precise matching to avoid false positives
            if (($itemName -match "^${material}" -or 
                 $itemName -match "_${material}" -or 
                 $itemName -match "${material}_" -or 
                 $itemName -match "_${material}_") -and 
                 # Exclude "pickled" items that falsely match "pick"
                 -not $itemName -match "pickle") {
                return $i
            }
        }
    }
    
    # Specific mod-based tier assignments for items that don't match material patterns
    if ($modName -match "biggerreactors|bigreactors" -and -not $itemName -match "basic") {
        return 4  # Base BiggerReactors/BigReactors items start at tier 4
    }
    
    if ($modName -match "mekanism" -and -not $itemName -match "basic") {
        return 3  # Base Mekanism items start at tier 3
    }
    
    # Default to tier 1 if no match is found
    return 1
}

# Process all item JSON files
Write-Host "Starting item requirement analysis..." -ForegroundColor Cyan

foreach ($mod in $modDirs) {
    $modName = $mod.Name
    $itemsPath = Join-Path -Path $mod.FullName -ChildPath "pmmo\items"
    
    # Skip if the items directory doesn't exist
    if (-not (Test-Path $itemsPath)) {
        continue
    }
    
    Write-Host "Processing $modName items..." -ForegroundColor Yellow
    
    # Get all JSON files in the items directory
    $itemFiles = Get-ChildItem -Path $itemsPath -Filter "*.json"
    
    foreach ($file in $itemFiles) {
        $fileName = $file.BaseName.ToLower()
        $processedCount++
        
        # Determine item type
        $itemType = "other"
        $isTech = $false
        $isMagic = $false
        $isPaxel = $false
        $isMultiTool = $false
        
        # Special check for multi-tools (paxels and others) first
        if ($fileName -match "paxel") {
            $itemType = "paxel"
            $isPaxel = $true
            $isMultiTool = $true
            $itemTypes.tool++
        } else {
            # Check for other multi-tools
            foreach ($pattern in $multiToolPatterns) {
                if ($fileName -match $pattern) {
                    $itemType = "paxel"  # Treat as paxel for requirements
                    $isMultiTool = $true
                    $itemTypes.tool++
                    break
                }
            }
            
            # Only check other types if not already identified as multi-tool
            if (-not $isMultiTool) {
                # Check if it's armor
                foreach ($pattern in $armorPatterns) {
                    if ($fileName -match $pattern) {
                        $itemType = "armor"
                        $itemTypes.armor++
                        break
                    }
                }
                
                # Check if it's a tool
                if ($itemType -eq "other") {
                    foreach ($toolType in $toolPatterns.Keys) {
                        foreach ($pattern in $toolPatterns[$toolType]) {
                            # Exclude false positives like "pickled" in food items
                            if ($fileName -match $pattern -and 
                                -not ($pattern -match "pick" -and $fileName -match "pickle")) {
                                $itemType = $toolType
                                $itemTypes.tool++
                                break
                            }
                        }
                        if ($itemType -ne "other") { break }
                    }
                }
                
                # Check if it's a weapon
                if ($itemType -eq "other") {
                    foreach ($pattern in $weaponPatterns) {
                        if ($fileName -match $pattern) {
                            $itemType = "weapon"
                            $itemTypes.weapon++
                            break
                        }
                    }
                }
            }
        }
        
        # Check if it's tech based on both pattern and mod
        $isTech = $false
        foreach ($pattern in $techPatterns) {
            if ($fileName -match $pattern) {
                $isTech = $true
                $itemTypes.tech++
                break
            }
        }
        if (-not $isTech) {
            foreach ($techMod in $techMods) {
                if ($modName -match $techMod) {
                    $isTech = $true
                    $itemTypes.tech++
                    break
                }
            }
        }
        
        # Check if it's magic based on both pattern and mod
        $isMagic = $false
        foreach ($pattern in $magicPatterns) {
            if ($fileName -match $pattern) {
                $isMagic = $true
                $itemTypes.magic++
                break
            }
        }
        if (-not $isMagic) {
            foreach ($magicMod in $magicMods) {
                if ($modName -match $magicMod) {
                    $isMagic = $true
                    $itemTypes.magic++
                    break
                }
            }
        }
        
        # If still "other", count it
        if ($itemType -eq "other") {
            $itemTypes.other++
        }
        
        # Get the item's tier based on name and material
        $tier = Get-ItemTier -itemName $fileName
        
        # Get the appropriate requirements
        $requirements = Get-SkillRequirements -itemType $itemType -tier $tier -isTech $isTech -isMagic $isMagic
        
        # Read the JSON content
        try {
            $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json -ErrorAction Stop
            $modified = $false
            
            # Check if requirements exists
            if (-not $jsonContent.PSObject.Properties["requirements"]) {
                $jsonContent | Add-Member -NotePropertyName "requirements" -NotePropertyValue @{} -Force
                $modified = $true
            }
            
            # Define which requirement types to check based on item type
            $requirementTypes = @()
            
            switch ($itemType) {
                "armor" {
                    $requirementTypes = @("WEAR", "USE")
                }
                "paxel" {
                    # Paxel is a special case - it acts as all tools
                    $requirementTypes = @("TOOL", "USE")
                }
                { $_ -in @("pickaxe", "axe", "shovel", "hoe", "shears") } {
                    $requirementTypes = @("TOOL", "USE")
                }
                "weapon" {
                    $requirementTypes = @("WEAPON", "USE")
                }
                default {
                    $requirementTypes = @("USE")
                    # If it seems like equipment, add wear requirement
                    if ($fileName -match "(helmet|chestplate|leggings|boots|armor|ring|amulet|charm|belt)") {
                        $requirementTypes += "WEAR"
                    }
                    # If it seems like a tool, add tool requirement
                    if ($fileName -match "(tool|hammer|wrench|screwdriver|saw|drill)") {
                        $requirementTypes += "TOOL"
                    }
                }
            }
            
            # Create the requirement fields if they don't exist
            foreach ($reqType in $requirementTypes) {
                if (-not $jsonContent.requirements.PSObject.Properties[$reqType]) {
                    $jsonContent.requirements | Add-Member -NotePropertyName $reqType -NotePropertyValue @{} -Force
                    $modified = $true
                }
                
                # Add skill requirements
                foreach ($skill in $requirements.Keys) {
                    # Skip if skill is already set with a higher value
                    $currentValue = 0
                    if ($jsonContent.requirements.$reqType.PSObject.Properties[$skill]) {
                        $currentValue = $jsonContent.requirements.$reqType.$skill
                    }
                    
                    if ($currentValue -lt $requirements[$skill]) {
                        $jsonContent.requirements.$reqType | Add-Member -NotePropertyName $skill -NotePropertyValue $requirements[$skill] -Force
                        $modified = $true
                    }
                }
            }
            
            # Special handling for archery weapons
            if ($itemType -eq "weapon") {
                $isArchery = $false
                foreach ($pattern in $archeryPatterns) {
                    if ($fileName -match $pattern) {
                        $isArchery = $true
                        break
                    }
                }
                
                if ($isArchery) {
                    # Override requirements for archery weapons
                    $requirements = Get-SkillRequirements -itemType "weapon" -tier $tier -isTech $isTech -isMagic $isMagic
                    $requirements.Remove("combat")
                    $requirements["archery"] = $tierLevels[$tier]
                }
            }
            
            # Save changes if any modifications were made
            if ($modified) {
                $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $file.FullName
                Write-Host "  Updated: $fileName ($itemType, Tier $tier)" -ForegroundColor Green
                $modifiedCount++
            }
        }
        catch {
            Write-Host "  Error processing $fileName : $_" -ForegroundColor Red
        }
    }
}

# Display results
Write-Host "`nItem Requirements Analysis Complete!" -ForegroundColor Cyan
Write-Host "Files processed: $processedCount" -ForegroundColor White
Write-Host "Files modified: $modifiedCount" -ForegroundColor Green
Write-Host "`nItem types found:" -ForegroundColor Yellow
Write-Host "  Armor: $($itemTypes.armor)" -ForegroundColor Magenta
Write-Host "  Tools: $($itemTypes.tool)" -ForegroundColor Blue
Write-Host "  Weapons: $($itemTypes.weapon)" -ForegroundColor Red
Write-Host "  Tech items: $($itemTypes.tech)" -ForegroundColor Cyan
Write-Host "  Magic items: $($itemTypes.magic)" -ForegroundColor Yellow
Write-Host "  Other items: $($itemTypes.other)" -ForegroundColor Gray

# Add summary of mod coverage to the results
Write-Host "`nTechnology Mods Identified:" -ForegroundColor Cyan
foreach ($mod in ($techMods | Sort-Object)) {
    Write-Host "  $mod" -ForegroundColor Gray
}

Write-Host "`nMagic Mods Identified:" -ForegroundColor Magenta
foreach ($mod in ($magicMods | Sort-Object)) {
    Write-Host "  $mod" -ForegroundColor Gray
}
