# Script to analyze item types and tiers without modifying them - JSON output version

# Define root path for data
$rootPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data"

# Get all mod directories
$modDirs = Get-ChildItem -Path $rootPath -Directory

# Set up counters and collections
$modStats = @{}
$itemCount = 0
$itemsByType = @{
    "armor" = @()
    "pickaxe" = @()
    "axe" = @()
    "shovel" = @()
    "hoe" = @()
    "shears" = @()
    "paxel" = @()  # Add special category for paxels
    "weapon" = @()
    "tech" = @()
    "magic" = @()
    "other" = @()
}
$itemsByTier = @{}
for ($i = 0; $i -le 10; $i++) {
    $itemsByTier[$i] = @()
}

# Define item type patterns
$armorPatterns = @(
    "helmet", "chestplate", "leggings", "boots", "armor", "suit", "_helm", 
    "_chest", "_legs", "_boots", "cuirass", "gauntlet", "greaves", "crown", "robe", "gear"
)

$toolPatterns = @{
    "pickaxe" = @("pickaxe", "pick", "miner", "paxel")
    "axe" = @("axe", "hatchet", "chopper", "lumber")
    "shovel" = @("shovel", "spade", "excavator", "digger")
    "hoe" = @("hoe", "scythe", "tiller", "cultivator")
    "shears" = @("shears", "cutter", "clippers", "scissors")
}

$weaponPatterns = @(
    "sword", "dagger", "blade", "knife", "mace", "hammer", "axe", "staff", "wand", 
    "bow", "crossbow", "gun", "rifle", "launcher", "weapon", "katana", "scythe"
)

$techPatterns = @(
    "meka", "quantum", "jetpack", "module", "augment", "circuit", "capacitor", "battery",
    "reactor", "atomic", "power", "energy", "drill", "electric", "mech", "nano"
)

$magicPatterns = @(
    "arcane", "mystic", "magic", "enchanted", "sorcery", "wizard", "witch", "warlock", 
    "mana", "soul", "spirit", "elemental", "scroll", "tome", "grimoire", "rune"
)

# Function to determine tier based on item name and material
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
    
    # Check each tier's materials
    for ($i = 10; $i -ge 0; $i--) {
        foreach ($material in $materialTiers[$i]) {
            if ($itemName -match $material) {
                return $i
            }
        }
    }
    
    # Default to tier 1 if no match is found
    return 1
}

# Process all item JSON files
Write-Host "Starting item analysis..." -ForegroundColor Cyan

foreach ($mod in $modDirs) {
    $modName = $mod.Name
    $itemsPath = Join-Path -Path $mod.FullName -ChildPath "pmmo\items"
    $modItemCount = 0
    
    # Skip if the items directory doesn't exist
    if (-not (Test-Path $itemsPath)) {
        continue
    }
    
    # Get all JSON files in the items directory
    $itemFiles = Get-ChildItem -Path $itemsPath -Filter "*.json"
    
    foreach ($file in $itemFiles) {
        $fileName = $file.BaseName.ToLower()
        $itemCount++
        $modItemCount++
        
        # Create item info object
        $itemInfo = @{
            Name = $fileName
            Mod = $modName
            Type = "other"
            Tier = 0
            IsTech = $false
            IsMagic = $false
            FilePath = $file.FullName
        }
        
        # Special check for paxels first
        if ($fileName -match "paxel") {
            $itemInfo.Type = "paxel"
        } else {
            # Determine item type
            foreach ($pattern in $armorPatterns) {
                if ($fileName -match $pattern) {
                    $itemInfo.Type = "armor"
                    break
                }
            }
            
            # Check if it's a tool
            if ($itemInfo.Type -eq "other") {
                foreach ($toolType in $toolPatterns.Keys) {
                    foreach ($pattern in $toolPatterns[$toolType]) {
                        if ($fileName -match $pattern) {
                            $itemInfo.Type = $toolType
                            break
                        }
                    }
                    if ($itemInfo.Type -ne "other") { break }
                }
            }
            
            # Check if it's a weapon
            if ($itemInfo.Type -eq "other") {
                foreach ($pattern in $weaponPatterns) {
                    if ($fileName -match $pattern) {
                        $itemInfo.Type = "weapon"
                        break
                    }
                }
            }
        }

        # Check if it's tech
        foreach ($pattern in $techPatterns) {
            if ($fileName -match $pattern -or $modName -match "(mekanism|thermal|immersive|applied|rftools|industrial|create|flux)") {
                $itemInfo.IsTech = $true
                break
            }
        }
        
        # Check if it's magic
        foreach ($pattern in $magicPatterns) {
            if ($fileName -match $pattern -or $modName -match "(botania|thaumcraft|astral|blood|ars|forbidden|occultism|evilcraft)") {
                $itemInfo.IsMagic = $true
                break
            }
        }
        
        # Get the item's tier based on name and material
        $itemInfo.Tier = Get-ItemTier -itemName $fileName
        
        # Add item to the appropriate collections
        $itemsByType[$itemInfo.Type] += [PSCustomObject]$itemInfo
        
        # Also categorize by tech/magic if applicable
        if ($itemInfo.IsTech) {
            $itemsByType["tech"] += [PSCustomObject]$itemInfo
        }
        if ($itemInfo.IsMagic) {
            $itemsByType["magic"] += [PSCustomObject]$itemInfo
        }
        
        # Add to tier-based collection
        $itemsByTier[$itemInfo.Tier] += [PSCustomObject]$itemInfo
    }
    
    # Add mod stats
    if ($modItemCount -gt 0) {
        $modStats[$modName] = $modItemCount
    }
}

# Generate the JSON report structure
$reportObject = @{
    summary = @{
        totalItems = $itemCount
        armorItems = $itemsByType.armor.Count
        toolItems = @{
            total = $itemsByType.pickaxe.Count + $itemsByType.axe.Count + $itemsByType.shovel.Count + $itemsByType.hoe.Count + $itemsByType.shears.Count + $itemsByType.paxel.Count
            pickaxes = $itemsByType.pickaxe.Count
            axes = $itemsByType.axe.Count
            shovels = $itemsByType.shovel.Count
            hoes = $itemsByType.hoe.Count
            shears = $itemsByType.shears.Count
            paxels = $itemsByType.paxel.Count
        }
        weaponItems = $itemsByType.weapon.Count
        techItems = $itemsByType.tech.Count
        magicItems = $itemsByType.magic.Count
        otherItems = $itemsByType.other.Count
    }
    
    tierDistribution = @{}
    modDistribution = @{}
    
    # Item category details
    armorItems = @()
    pickaxeItems = @()
    weaponItems = @()
    paxelItems = @()
    techItems = @()
    magicItems = @()
}

# Populate tier distribution
for ($i = 0; $i -le 10; $i++) {
    $reportObject.tierDistribution["tier$i"] = @{
        count = $itemsByTier[$i].Count
        exampleItems = ($itemsByTier[$i] | Select-Object -First 5 | ForEach-Object { $_.Name })
    }
}

# Populate mod distribution
foreach ($mod in ($modStats.Keys | Sort-Object -Property { $modStats[$_] } -Descending)) {
    $reportObject.modDistribution[$mod] = $modStats[$mod]
}

# Populate item category details (limit to 25 items per category for efficiency)
$reportObject.armorItems = $itemsByType.armor | 
    Sort-Object -Property Tier -Descending | 
    Select-Object -First 25 | 
    ForEach-Object { 
        @{
            name = $_.Name
            mod = $_.Mod
            tier = $_.Tier
            isTech = $_.IsTech
            isMagic = $_.IsMagic
        }
    }

$reportObject.pickaxeItems = $itemsByType.pickaxe | 
    Sort-Object -Property Tier -Descending | 
    Select-Object -First 25 | 
    ForEach-Object { 
        @{
            name = $_.Name
            mod = $_.Mod
            tier = $_.Tier
            isTech = $_.IsTech
            isMagic = $_.IsMagic
        }
    }

$reportObject.weaponItems = $itemsByType.weapon | 
    Sort-Object -Property Tier -Descending | 
    Select-Object -First 25 | 
    ForEach-Object { 
        @{
            name = $_.Name
            mod = $_.Mod
            tier = $_.Tier
            isTech = $_.IsTech
            isMagic = $_.IsMagic
        }
    }

$reportObject.paxelItems = $itemsByType.paxel | 
    Sort-Object -Property Tier -Descending | 
    Select-Object -First 25 | 
    ForEach-Object { 
        @{
            name = $_.Name
            mod = $_.Mod
            tier = $_.Tier
            isTech = $_.IsTech
            isMagic = $_.IsMagic
        }
    }

$reportObject.techItems = $itemsByType.tech | 
    Sort-Object -Property Tier -Descending | 
    Select-Object -First 25 | 
    ForEach-Object { 
        @{
            name = $_.Name
            mod = $_.Mod
            type = $_.Type
            tier = $_.Tier
        }
    }

$reportObject.magicItems = $itemsByType.magic | 
    Sort-Object -Property Tier -Descending | 
    Select-Object -First 25 | 
    ForEach-Object { 
        @{
            name = $_.Name
            mod = $_.Mod
            type = $_.Type
            tier = $_.Tier
        }
    }

# Add skill requirements metadata
$reportObject.skillRequirements = @{
    tools = @{
        pickaxe = @("smithing", "mining")
        axe = @("smithing", "woodcutting")
        shovel = @("smithing", "excavation")
        hoe = @("smithing", "farming")
        shears = @("smithing", "farming")
        paxel = @("smithing", "mining", "woodcutting", "excavation")
    }
    armor = @("smithing", "endurance")
    weapons = @{
        melee = @("smithing", "combat")
        ranged = @("smithing", "archery")
    }
    special = @{
        tech = "technology"
        magic = "magic"
    }
}

# Generate JSON file path
$reportFile = Join-Path -Path "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo" -ChildPath "ItemAnalysisReport.json"

# Save as JSON
$reportObject | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportFile -Encoding utf8

# Also create a detailed export with all items for data processing
$detailedReportFile = Join-Path -Path "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo" -ChildPath "ItemAnalysisReportDetailed.json"

# Create an object with all items in each category
$detailedReportObject = @{
    allItems = @{
        armor = $itemsByType.armor | ForEach-Object { @{ name = $_.Name; mod = $_.Mod; tier = $_.Tier; isTech = $_.IsTech; isMagic = $_.IsMagic } }
        pickaxes = $itemsByType.pickaxe | ForEach-Object { @{ name = $_.Name; mod = $_.Mod; tier = $_.Tier; isTech = $_.IsTech; isMagic = $_.IsMagic } }
        axes = $itemsByType.axe | ForEach-Object { @{ name = $_.Name; mod = $_.Mod; tier = $_.Tier; isTech = $_.IsTech; isMagic = $_.IsMagic } }
        shovels = $itemsByType.shovel | ForEach-Object { @{ name = $_.Name; mod = $_.Mod; tier = $_.Tier; isTech = $_.IsTech; isMagic = $_.IsMagic } }
        hoes = $itemsByType.hoe | ForEach-Object { @{ name = $_.Name; mod = $_.Mod; tier = $_.Tier; isTech = $_.IsTech; isMagic = $_.IsMagic } }
        shears = $itemsByType.shears | ForEach-Object { @{ name = $_.Name; mod = $_.Mod; tier = $_.Tier; isTech = $_.IsTech; isMagic = $_.IsMagic } }
        paxels = $itemsByType.paxel | ForEach-Object { @{ name = $_.Name; mod = $_.Mod; tier = $_.Tier; isTech = $_.IsTech; isMagic = $_.IsMagic } }
        weapons = $itemsByType.weapon | ForEach-Object { @{ name = $_.Name; mod = $_.Mod; tier = $_.Tier; isTech = $_.IsTech; isMagic = $_.IsMagic } }
    }
    
    itemsByTier = @{}
    itemsByMod = @{}
}

# Add items by tier
for ($i = 0; $i -le 10; $i++) {
    $detailedReportObject.itemsByTier["tier$i"] = $itemsByTier[$i] | ForEach-Object { 
        @{ 
            name = $_.Name
            mod = $_.Mod
            type = $_.Type
            isTech = $_.IsTech
            isMagic = $_.IsMagic
        }
    }
}

# Add items by mod
foreach ($mod in $modStats.Keys) {
    $modItems = @()
    foreach ($type in $itemsByType.Keys) {
        $modItems += $itemsByType[$type] | Where-Object { $_.Mod -eq $mod } | ForEach-Object {
            @{
                name = $_.Name
                type = $_.Type
                tier = $_.Tier
                isTech = $_.IsTech
                isMagic = $_.IsMagic
            }
        }
    }
    $detailedReportObject.itemsByMod[$mod] = $modItems
}

# Save detailed report
$detailedReportObject | ConvertTo-Json -Depth 4 -Compress:$false | Out-File -FilePath $detailedReportFile -Encoding utf8

# Display results
Write-Host "`nItem Analysis Complete!" -ForegroundColor Cyan
Write-Host "Total items analyzed: $itemCount" -ForegroundColor White
Write-Host "JSON report saved to: $reportFile" -ForegroundColor Green
Write-Host "Detailed JSON report saved to: $detailedReportFile" -ForegroundColor Green
Write-Host "`nItem types found:" -ForegroundColor Yellow
Write-Host "  Armor: $($itemsByType.armor.Count)" -ForegroundColor Magenta
Write-Host "  Pickaxes: $($itemsByType.pickaxe.Count)" -ForegroundColor Blue
Write-Host "  Axes: $($itemsByType.axe.Count)" -ForegroundColor Blue
Write-Host "  Shovels: $($itemsByType.shovel.Count)" -ForegroundColor Blue
Write-Host "  Hoes: $($itemsByType.hoe.Count)" -ForegroundColor Blue
Write-Host "  Shears: $($itemsByType.shears.Count)" -ForegroundColor Blue
Write-Host "  Paxels: $($itemsByType.paxel.Count)" -ForegroundColor Cyan
Write-Host "  Weapons: $($itemsByType.weapon.Count)" -ForegroundColor Red
Write-Host "  Tech items: $($itemsByType.tech.Count)" -ForegroundColor Yellow
Write-Host "  Magic items: $($itemsByType.magic.Count)" -ForegroundColor Magenta