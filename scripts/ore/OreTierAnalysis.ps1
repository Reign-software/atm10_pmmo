# PowerShell script to analyze ore files and organize them into our expanded 11-tier system
$rootPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data"

# Get all mod directories
$modDirs = Get-ChildItem -Path $rootPath -Directory

# Define keyword patterns for ore identification
$orePatterns = @(
    "ore",
    "deepslate_.*ore",
    "raw_.*",
    "block_of_raw_.*",
    "vein",
    "deposit",
    "cluster",
    "shard",
    "dust_.*",
    "_metal",   # Additional patterns to catch more potential ores
    "_gem",
    "_crystal",
    "_mineral"
)

# New pattern for block files that might be ores but aren't named conventionally
$blockPattern = ".*\.json$"
$deepScanForOres = $false  # Set to $true to scan ALL block files (warning: will be slow)

# Additional properties to check in JSON to identify if a block might be an ore
$oreJsonProperties = @(
    "vein_data",      # PMMO vein data suggests it's an ore
    "material.metal", # Material properties that suggest ore
    "material.gem",
    "hardness",       # High hardness often indicates ore
    "tags.forge:ores" # Forge ore tags
)

# Create a hash table to store ore frequencies
$oreFrequency = @{}

# Initialize tier groups for all 11 tiers (0-10)
$tierGroups = @{}
for ($i = 0; $i -le 10; $i++) {
    $tierGroups[$i] = @()
}
$unclassified = @()

# Define tiered ore patterns based on our new 11-tier system
$tierPatterns = @{
    # Tier 0 - Stone and Common Materials (Level 0)
    0 = @("stone", "granite", "diorite", "andesite", "deepslate", "tuff", "gravel", "dirt", "sand", "sandstone", "netherrack")
    
    # Tier 1 - Basic Ores (Level 50)
    1 = @("coal_ore", "iron_ore", "copper_ore", "tin_ore", "clay")
    
    # Tier 2 - Intermediate Ores (Level 100)
    2 = @("gold_ore", "redstone_ore", "lead_ore", "zinc_ore", "bauxite")
    
    # Tier 3 - Advanced Overworld Ores (Level 150)
    3 = @("lapis_ore", "aluminum_ore", "silver_ore", "nickel_ore", "quartz_ore", "apatite_ore", "sulfur_ore", "niter_ore")
    
    # Tier 4 - Nether Resources (Level 200)
    4 = @("nether_gold_ore", "nether_quartz_ore", "glowstone", "cinnabar_ore", "bitumen", "fluorite_ore", "certus_quartz", "charged_certus")
    
    # Tier 5 - Precious Materials (Level 250)
    5 = @("diamond_ore", "emerald_ore", "sapphire_ore", "ruby_ore", "amethyst")
    
    # Tier 6 - Industrial Resources (Level 300)
    6 = @("uranium_ore", "platinum_ore", "osmium_ore", "iridium_ore", "fluix")
    
    # Tier 7 - Exotic Materials (Level 350)
    7 = @("ancient_debris", "crimson_iron", "azure_silver", "cobalt_ore", "resource_")
    
    # Tier 8 - End and Dimensional Resources (Level 400)
    8 = @("end_stone", "draconium_ore", "allthemodium_ore", "allthemodium", "yellorite_ore")
    
    # Tier 9 - Rare Dimensional Materials (Level 450)
    9 = @("vibranium_ore", "vibranium", "resonant_end_stone", "benitoite", "anglesite_ore", "mithril_ore", "adamantite_ore")
    
    # Tier 10 - Mythical Materials (Level 500)
    10 = @("unobtainium_ore", "unobtainium", "infinity_ore", "nether_star_ore", "awakened_draconium_ore", "chaotic_ore", "creative", "netherstar", "dragon_egg")
}

# Define modifiers and their effect on tier
$modifiers = @{
    "deepslate_" = 1       # Deepslate variants are one tier higher
    "raw_" = 0             # No change for raw variants
    "nether_" = 1          # Higher tier for nether variants
    "end_" = 2             # Even higher for end variants
    "_cluster" = 1         # Clusters one tier higher
    "_deposit" = 0         # Deposits same tier
    "_shard" = -1          # Shards one tier lower
    "_dust" = -2           # Dusts two tiers lower
    "poor_" = -1           # Lower quality ores one tier lower
    "rich_" = 2            # Rich ore variants two tiers higher
    "dense_" = 1           # Dense ore variants one tier higher
    "normal_" = 0          # Normal quality no change
}

# Define XP and level values per tier
$tierLevels = @(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500)
$tierXP = @(10, 15, 20, 30, 40, 60, 80, 100, 120, 150, 200)
$tierNames = @(
    "Stone and Common Materials",
    "Basic Ores",
    "Intermediate Ores",
    "Advanced Overworld Ores",
    "Nether Resources",
    "Precious Materials",
    "Industrial Resources",
    "Exotic Materials",
    "End and Dimensional Resources",
    "Rare Dimensional Materials",
    "Mythical Materials"
)

# Search through all mod directories
foreach ($mod in $modDirs) {
    $modName = $mod.Name
    Write-Host "Scanning $modName..." -ForegroundColor Cyan
    
    # Get .json files that might contain ore data
    if ($deepScanForOres) {
        $jsonFiles = Get-ChildItem -Path $mod.FullName -Filter "*.json" -Recurse
    } else {
        # First get files that match our ore patterns
        $jsonFiles = Get-ChildItem -Path $mod.FullName -Filter "*.json" -Recurse | 
            Where-Object { 
                $fileName = $_.Name.ToLower()
                $orePatterns | ForEach-Object { $fileName -match $_ } | Where-Object { $_ -eq $true } | Select-Object -First 1
            }
        
        # Add blocks directory for special handling
        $blocksDir = Join-Path -Path $mod.FullName -ChildPath "pmmo\blocks"
        if (Test-Path $blocksDir) {
            $blockFiles = Get-ChildItem -Path $blocksDir -Filter "*.json"
            $jsonFiles += $blockFiles
        }
    }
    
    foreach ($file in $jsonFiles) {
        $fileName = $file.Name.ToLower()
        $baseName = $file.BaseName.ToLower()
        $isOre = $false
        $tier = -1
        $tierModifier = 0
        
        # Check if file name matches any ore pattern
        foreach ($pattern in $orePatterns) {
            if ($fileName -match $pattern) {
                $isOre = $true
                
                # Extract ore name
                $oreName = $baseName
                
                # Update frequency counter
                if ($oreFrequency.ContainsKey($oreName)) {
                    $oreFrequency[$oreName]++
                } else {
                    $oreFrequency[$oreName] = 1
                }
                
                # First check for base tier by pattern matching
                for ($t = 0; $t -le 10; $t++) {
                    $patterns = $tierPatterns[$t]
                    foreach ($p in $patterns) {
                        if ($oreName -match $p) {
                            $tier = $t
                            break
                        }
                    }
                    if ($tier -ne -1) {
                        break
                    }
                }
                
                # Check for modifiers
                foreach ($mod in $modifiers.Keys) {
                    if ($oreName -match $mod) {
                        $tierModifier += $modifiers[$mod]
                    }
                }
                
                # Apply tier modifier but keep within valid range
                if ($tier -ne -1) {
                    $adjustedTier = [Math]::Max(0, [Math]::Min(10, $tier + $tierModifier))
                    $fullOreName = "$modName`:$oreName"
                    $tierGroups[$adjustedTier] += $fullOreName
                } else {
                    # Unclassified ore - try to identify properties from the JSON
                    $fullOreName = "$modName`:$oreName"
                    
                    # Try to read the JSON file to look for clues about its tier
                    try {
                        $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
                        
                        # Check for specific properties that might indicate tier
                        $suggestedTier = -1
                        
                        # Look for hardness value as a hint
                        if ($jsonContent.PSObject.Properties["hardness"]) {
                            $hardness = $jsonContent.hardness
                            if ($hardness -ge 50) {
                                $suggestedTier = 10
                            } elseif ($hardness -ge 30) {
                                $suggestedTier = 8
                            } elseif ($hardness -ge 20) {
                                $suggestedTier = 6
                            } elseif ($hardness -ge 10) {
                                $suggestedTier = 4
                            } elseif ($hardness -ge 5) {
                                $suggestedTier = 2
                            } else {
                                $suggestedTier = 0
                            }
                        }
                        
                        # Store additional metadata about the unclassified ore
                        $unclassified += [PSCustomObject]@{
                            Name = $fullOreName
                            FilePath = $file.FullName
                            SuggestedTier = $suggestedTier
                            Hardness = if ($jsonContent.PSObject.Properties["hardness"]) { $jsonContent.hardness } else { "Unknown" }
                            HasVeinData = if ($jsonContent.PSObject.Properties["vein_data"]) { $true } else { $false }
                            CurrentMiningLevel = if ($jsonContent.PSObject.Properties["requirements"] -and 
                                                      $jsonContent.requirements.PSObject.Properties["BREAK"] -and
                                                      $jsonContent.requirements.BREAK.PSObject.Properties["mining"]) 
                                                { $jsonContent.requirements.BREAK.mining } else { "None" }
                            CurrentMiningXP = if ($jsonContent.PSObject.Properties["xp_values"] -and 
                                                   $jsonContent.xp_values.PSObject.Properties["BLOCK_BREAK"] -and
                                                   $jsonContent.xp_values.BLOCK_BREAK.PSObject.Properties["mining"]) 
                                             { $jsonContent.xp_values.BLOCK_BREAK.mining } else { "None" }
                        }
                    }
                    catch {
                        # If we can't read the JSON, just add the name
                        $unclassified += [PSCustomObject]@{
                            Name = $fullOreName
                            FilePath = $file.FullName
                            SuggestedTier = -1
                            Hardness = "Unknown"
                            HasVeinData = $false
                            CurrentMiningLevel = "Unknown"
                            CurrentMiningXP = "Unknown"
                        }
                    }
                }
                
                break
            }
        }
    }
}

# Output the tier lists with corresponding levels and XP values
Write-Host "`n=== ORE TIER ANALYSIS ===`n" -ForegroundColor Yellow

for ($i = 0; $i -le 10; $i++) {
    $level = $tierLevels[$i]
    $xp = $tierXP[$i]
    $name = $tierNames[$i]
    $count = $tierGroups[$i].Count
    
    Write-Host "Tier $i - $name (Level $level, $xp XP) - Found: $count" -ForegroundColor Cyan
    $tierGroups[$i] | Sort-Object | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    Write-Host ""
}

# Enhanced unclassified ore reporting
Write-Host "Unclassified Ores - Found: $($unclassified.Count)" -ForegroundColor Red
if ($unclassified.Count -gt 0) {
    # Create a file with suggested classifications
    $suggestionsFile = Join-Path -Path "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo" -ChildPath "UnclassifiedOreSuggestions.ps1"
    
    $suggestionsContent = "# Suggested classifications for unclassified ores`n"
    $suggestionsContent += "# Add these to your oreTiers hashtable in EnhancedMiningOrePMMO.ps1`n`n"
    $suggestionsContent += "`$additionalOreTiers = @{`n"
    
    $unclassified | Sort-Object -Property SuggestedTier | ForEach-Object {
        Write-Host "  $($_.Name)" -ForegroundColor Gray
        
        # Add to suggestions file with comments
        if ($_.SuggestedTier -ge 0) {
            $tierName = $tierNames[$_.SuggestedTier]
            $suggestionsContent += "    # Suggested Tier $($_.SuggestedTier) ($tierName)`n"
            $suggestionsContent += "    # Hardness: $($_.Hardness), Current Mining Level: $($_.CurrentMiningLevel), Current XP: $($_.CurrentMiningXP)`n"
            $suggestionsContent += "    `"$($_.Name.Split(':')[1])`" = $($_.SuggestedTier)`n`n"
        } else {
            $suggestionsContent += "    # Unable to suggest tier - needs manual classification`n"
            $suggestionsContent += "    # Hardness: $($_.Hardness), Current Mining Level: $($_.CurrentMiningLevel), Current XP: $($_.CurrentMiningXP)`n"
            $suggestionsContent += "    `"$($_.Name.Split(':')[1])`" = 0 # TODO: Assign appropriate tier`n`n"
        }
        
        # Display detailed information in console
        Write-Host "    File: $($_.FilePath)" -ForegroundColor DarkGray
        Write-Host "    Hardness: $($_.Hardness)" -ForegroundColor DarkGray
        if ($_.HasVeinData) { Write-Host "    Has Vein Data: Yes" -ForegroundColor Green }
        Write-Host "    Current Mining Level: $($_.CurrentMiningLevel)" -ForegroundColor DarkGray
        Write-Host "    Current Mining XP: $($_.CurrentMiningXP)" -ForegroundColor DarkGray
        
        if ($_.SuggestedTier -ge 0) {
            $tierName = $tierNames[$_.SuggestedTier]
            Write-Host "    Suggested Tier: $($_.SuggestedTier) - $tierName" -ForegroundColor Yellow
        } else {
            Write-Host "    Suggested Tier: Unable to determine" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    $suggestionsContent += "}`n"
    $suggestionsContent | Out-File -FilePath $suggestionsFile -Encoding utf8
    
    Write-Host "`nSuggested classifications saved to: $suggestionsFile" -ForegroundColor Green
}

# Generate a list of all mods that contain ores
$modsWithOres = @{}
for ($i = 0; $i -le 10; $i++) {
    foreach ($ore in $tierGroups[$i]) {
        $modName = $ore.Split(':')[0]
        if (-not $modsWithOres.ContainsKey($modName)) {
            $modsWithOres[$modName] = @()
        }
        $modsWithOres[$modName] += $i
    }
}

# Output the mods that have ores, sorted by name
Write-Host "`n=== MODS WITH ORES ===`n" -ForegroundColor Yellow
$modsWithOres.GetEnumerator() | Sort-Object -Property Name | ForEach-Object {
    $tiers = $_.Value | Sort-Object -Unique
    Write-Host "$($_.Key): Tiers $($tiers -join ', ')" -ForegroundColor Cyan
}

# Create updated ore tiers hash table for use in the mining script
Write-Host "`nGenerating updated ore tiers configuration..." -ForegroundColor Cyan

# Output the configuration to a file
$outputFile = Join-Path -Path "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo" -ChildPath "UpdatedOreTiers.ps1"

$output = "# Updated ore tiers configuration - Auto-generated based on analysis`n"
$output += "# Use these definitions in your EnhancedMiningOrePMMO.ps1 script`n`n"
$output += "# Define keyword-to-tier mapping for ores with 11 tiers (0-10)`n"
$output += "`$oreTiers = @{`n"

# Add tiers and keywords
for ($i = 0; $i -le 10; $i++) {
    $output += "    # Tier $i - $($tierNames[$i]) (Level $($tierLevels[$i]), $($tierXP[$i]) XP)`n"
    
    foreach ($pattern in $tierPatterns[$i]) {
        $output += "    `"$pattern`" = $i`n"
    }
    $output += "    `n"
}

# Add modifiers at the end
$output += "    # Quality and variant modifiers`n"
foreach ($mod in $modifiers.Keys) {
    if ($mod -match "^(poor_|normal_|dense_|rich_)$") {
        $output += "    `"$mod`" = $($modifiers[$mod])              # $mod variant (adjust tier by $($modifiers[$mod]))`n"
    }
}

$output += "}`n`n"

# Add prefix and suffix modifiers
$output += "# Add support for variants with these prefixes/suffixes - they directly adjust tiers`n"
$output += "`$prefixModifiers = @{`n"
foreach ($mod in $modifiers.Keys) {
    if ($mod -match "^(deepslate_|raw_|nether_|end_)") {
        $output += "    `"$mod`" = $($modifiers[$mod])       # $mod variants (adjust tier by $($modifiers[$mod]))`n"
    }
}
$output += "}`n`n"

$output += "`$suffixModifiers = @{`n"
foreach ($mod in $modifiers.Keys) {
    if ($mod -match "^(_cluster|_deposit|_shard|_dust)$") {
        $output += "    `"$mod`" = $($modifiers[$mod])         # $mod variants (adjust tier by $($modifiers[$mod]))`n"
    }
}
$output += "}`n`n"

# Add XP values array
$output += "# Define XP values for each tier - increasing in a more balanced way`n"
$output += "`$tierXPValues = @($($tierXP -join ", "))"

# Add a section to the output file for special cases
$output += "`n# Special case handling for mod-specific ores`n"
$output += "`$modSpecificOres = @{`n"
foreach ($modName in ($modsWithOres.Keys | Sort-Object)) {
    $output += "    # $modName specific ore handling`n"
    $output += "    `"$($modName)_ore`" = 1 # Default to tier 1, adjust as needed`n"
}
$output += "}`n`n"

# Save to file
$output | Out-File -FilePath $outputFile -Encoding utf8

# Also export the JSON structure that might be helpful for future analysis
$outputJsonFile = Join-Path -Path "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo" -ChildPath "OreTierAnalysis.json"
$outputJson = @{
    TierGroups = $tierGroups
    UnclassifiedOres = $unclassified
    ModsWithOres = $modsWithOres
    TierLevels = $tierLevels
    TierXP = $tierXP
    TierNames = $tierNames
    OreFrequency = $oreFrequency
}
$outputJson | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputJsonFile -Encoding utf8

Write-Host "`nDetailed ore analysis exported to: $outputJsonFile" -ForegroundColor Green

Write-Host "`nUpdated ore tiers configuration saved to: $outputFile" -ForegroundColor Green
Write-Host "You can include this file in your EnhancedMiningOrePMMO.ps1 script." -ForegroundColor Yellow
