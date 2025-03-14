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
# Auto-discover all mod folders (same as your original script)
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

# PMMO Level XP Formula Parameters
$xpMin = 300
$xpBase = 1.075
$perLevel = 0.4

# Function to calculate XP required for a given level based on PMMO formula
function Get-LevelXP {
    param (
        [int]$level
    )
    
    return $xpMin * [Math]::Pow($xpBase, $level) * (1 + $perLevel * $level)
}

# Function to generate appropriate XP reward based on level requirement
function Get-AppropriateXP {
    param (
        [int]$requiredLevel
    )
    
    if ($requiredLevel -le 0) {
        return 10 # Minimum XP for tier 0
    }
    
    # Calculate total XP needed to reach level
    $xpNeeded = Get-LevelXP -level $requiredLevel
    
    # Calculate XP reward as a percentage of what's needed for that level
    # Lower percentage for lower levels, higher for higher levels
    $percentageOfLevel = switch ($requiredLevel) {
        {$_ -lt 100} { 0.1 }    # 0.1% of level XP for early game (levels < 100)
        {$_ -lt 200} { 0.15 }   # 0.15% of level XP for mid game (levels 100-199)
        {$_ -lt 300} { 0.2 }    # 0.2% of level XP for late game (levels 200-299)
        {$_ -lt 400} { 0.25 }   # 0.25% of level XP for very late game (levels 300-399)
        default { 0.3 }         # 0.3% of level XP for endgame (levels 400+)
    }
    
    # Calculate reward, round to nearest 5 for cleaner numbers
    $reward = [Math]::Max(10, [Math]::Round(($xpNeeded * $percentageOfLevel / 100) / 5) * 5)
    
    # Ensure the value is reasonable
    return [Math]::Min(100000, [Math]::Max(10, $reward))
}

# Calculate XP values for each tier based on required level
$tierLevels = @(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500)
$tierXPValues = @()

for ($i = 0; $i -lt $tierLevels.Count; $i++) {
    $xp = Get-AppropriateXP -requiredLevel $tierLevels[$i]
    $tierXPValues += $xp
}

Write-Host "`nCalculated XP values per tier:" -ForegroundColor Cyan
for ($i = 0; $i -lt $tierLevels.Count; $i++) {
    Write-Host "Tier $i (Level $($tierLevels[$i])): $($tierXPValues[$i]) XP" -ForegroundColor Yellow
}

# Define your keyword-to-tier mapping and other parts of the script as before
$oreTiers = @{
    # Tier 0 - Stone and Common Materials (Level 0)
    "stone" = 0
    "granite" = 0
    "diorite" = 0
    # Add the rest of your tier definitions here just as in the original script
}

# Add your prefix/suffix modifiers as in the original script
$prefixModifiers = @{
    "deepslate_" = 1
    "raw_" = 0
    "nether_" = 1
    "end_" = 2
}

$suffixModifiers = @{
    "_cluster" = 1
    "_deposit" = 0
    "_shard" = -1
    "_dust" = -2
}

# Special case handling as in the original script
$crystalBlocks = @{
    # Your crystal block definitions here
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

# Mining Level and XP Summary
Write-Host "`nMining Level Requirements and XP Rewards:" -ForegroundColor Cyan
for ($i = 0; $i -le 10; $i++) {
    $level = $baseMiningLevel + ($i * $levelIncreasePerTier)
    $xp = $tierXPValues[$i]
    
    # Calculate how many ore breaks needed for one level
    $xpForNextLevel = Get-LevelXP -level ($level + 1)
    $oresForLevel = [Math]::Ceiling($xpForNextLevel / $xp)
    
    Write-Host "Tier $i : Level $level required, $xp XP per ore (Found: $($statsPerTier[$i]))" -ForegroundColor Yellow
    Write-Host "   - Approximately $oresForLevel ore breaks needed for a player at level $level to level up" -ForegroundColor Gray
}

# Display XP needed for key level thresholds
Write-Host "`nXP Required for Key Level Thresholds:" -ForegroundColor Cyan
@(50, 100, 200, 300, 400, 500) | ForEach-Object {
    $xpNeeded = Get-LevelXP -level $_
    Write-Host "Level $_`: $([Math]::Round($xpNeeded).ToString('N0')) XP" -ForegroundColor White
}