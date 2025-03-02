# Script to identify and categorize unknown ores in the modpack

$rootPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data"

# Get all mod directories
$modDirs = Get-ChildItem -Path $rootPath -Directory

# Track stats
$totalFiles = 0
$totalBlockFiles = 0
$possibleOres = @()
$modOreStats = @{}

Write-Host "=== UNKNOWN ORE DETECTION TOOL ===" -ForegroundColor Cyan
Write-Host "This tool will search for potential ores that aren't yet in our tier system" -ForegroundColor Yellow
Write-Host "Searching in $rootPath..." -ForegroundColor Gray

# Define patterns that suggest a block might be an ore
$oreIndicators = @(
    "ore",
    "vein",
    "mineral",
    "gem",
    "crystal",
    "metal",
    "deposit"
)

# Define common non-ore blocks that might otherwise match our patterns
$nonOreBlocks = @(
    "storage_block",
    "block_of_",
    "door",
    "trapdoor",
    "slab",
    "stairs",
    "fence",
    "wall",
    "log",
    "planks",
    "chest",
    "barrel",
    "machine",
    "engine",
    "core",
    "cable",
    "pipe",
    "tank",
    "gear",
    "plate"
)

# Define known ores
$knownOrePatterns = @(
    # Base materials
    "stone",
    "granite",
    "diorite", 
    "andesite",
    "coal_ore",
    "iron_ore",
    "gold_ore", 
    "copper_ore",
    "tin_ore",
    "lead_ore",
    "silver_ore",
    "redstone_ore",
    "lapis_ore",
    "quartz_ore",
    "diamond_ore",
    "emerald_ore",
    "nether_gold_ore",
    "nether_quartz_ore",
    "ancient_debris",
    "uranium_ore",
    "platinum_ore",
    "osmium_ore",
    "iridium_ore",
    "yellorite_ore",
    "draconium_ore",
    "allthemodium_ore",
    "vibranium_ore",
    "unobtainium_ore"
)

foreach ($mod in $modDirs) {
    $modName = $mod.Name
    $modOreCount = 0
    $pmmoPath = Join-Path -Path $mod.FullName -ChildPath "pmmo"
    
    if (Test-Path $pmmoPath) {
        Write-Host "Checking $modName..." -ForegroundColor Magenta
        
        # Check blocks directory first
        $blocksPath = Join-Path -Path $pmmoPath -ChildPath "blocks"
        if (Test-Path $blocksPath) {
            $blockFiles = Get-ChildItem -Path $blocksPath -Filter "*.json"
            $totalBlockFiles += $blockFiles.Count
            
            foreach ($file in $blockFiles) {
                $totalFiles++
                $fileName = $file.BaseName.ToLower()
                
                # Check if this might be an ore
                $isKnownOre = $false
                foreach ($pattern in $knownOrePatterns) {
                    if ($fileName -match $pattern) {
                        $isKnownOre = $true
                        break
                    }
                }
                
                if ($isKnownOre) {
                    continue # Skip known ores
                }
                
                # Check for ore indicators
                $isPossibleOre = $false
                foreach ($indicator in $oreIndicators) {
                    if ($fileName -match $indicator) {
                        $isPossibleOre = $true
                        break
                    }
                }
                
                # Check for non-ore blocks that we should exclude
                if ($isPossibleOre) {
                    foreach ($nonOre in $nonOreBlocks) {
                        if ($fileName -match $nonOre) {
                            $isPossibleOre = $false
                            break
                        }
                    }
                }
                
                # If it seems like an ore, check the JSON
                if ($isPossibleOre) {
                    $possibleOreInfo = @{
                        Name = $fileName
                        Mod = $modName
                        FilePath = $file.FullName
                        Confidence = "Medium" # Default confidence
                        Hardness = "Unknown"
                        HasMiningXP = $false
                        HasMiningRequirement = $false
                        SuggestedTier = 0
                    }
                    
                    # Try to analyze the JSON
                    try {
                        $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                        
                        # Check for mining XP in JSON
                        if ($jsonContent.PSObject.Properties["xp_values"] -and 
                            $jsonContent.xp_values.PSObject.Properties["BLOCK_BREAK"] -and
                            $jsonContent.xp_values.BLOCK_BREAK.PSObject.Properties["mining"]) {
                            $possibleOreInfo.HasMiningXP = $true
                            $possibleOreInfo.Confidence = "High"
                        }
                        
                        # Check for mining requirement in JSON
                        if ($jsonContent.PSObject.Properties["requirements"] -and 
                            $jsonContent.requirements.PSObject.Properties["BREAK"] -and
                            $jsonContent.requirements.BREAK.PSObject.Properties["mining"]) {
                            $possibleOreInfo.HasMiningRequirement = $true
                            $possibleOreInfo.Confidence = "High"
                            
                            # Use existing requirement to suggest tier
                            $requiredLevel = $jsonContent.requirements.BREAK.mining
                            if ($requiredLevel -ge 500) {
                                $possibleOreInfo.SuggestedTier = 10
                            } elseif ($requiredLevel -ge 450) {
                                $possibleOreInfo.SuggestedTier = 9
                            } elseif ($requiredLevel -ge 400) {
                                $possibleOreInfo.SuggestedTier = 8
                            } elseif ($requiredLevel -ge 350) {
                                $possibleOreInfo.SuggestedTier = 7
                            } elseif ($requiredLevel -ge 300) {
                                $possibleOreInfo.SuggestedTier = 6
                            } elseif ($requiredLevel -ge 250) {
                                $possibleOreInfo.SuggestedTier = 5
                            } elseif ($requiredLevel -ge 200) {
                                $possibleOreInfo.SuggestedTier = 4
                            } elseif ($requiredLevel -ge 150) {
                                $possibleOreInfo.SuggestedTier = 3
                            } elseif ($requiredLevel -ge 100) {
                                $possibleOreInfo.SuggestedTier = 2
                            } elseif ($requiredLevel -ge 50) {
                                $possibleOreInfo.SuggestedTier = 1
                            } else {
                                $possibleOreInfo.SuggestedTier = 0
                            }
                        }
                        
                        # Check for vein data which strongly indicates an ore
                        if ($jsonContent.PSObject.Properties["vein_data"]) {
                            $possibleOreInfo.Confidence = "Very High"
                        }
                        
                        # Check for hardness property
                        if ($jsonContent.PSObject.Properties["hardness"]) {
                            $possibleOreInfo.Hardness = $jsonContent.hardness
                            
                            # Suggest tier based on hardness if we don't have a requirement
                            if (-not $possibleOreInfo.HasMiningRequirement) {
                                $hardness = $jsonContent.hardness
                                if ($hardness -ge 50) {
                                    $possibleOreInfo.SuggestedTier = 10
                                } elseif ($hardness -ge 30) {
                                    $possibleOreInfo.SuggestedTier = 8
                                } elseif ($hardness -ge 20) {
                                    $possibleOreInfo.SuggestedTier = 6
                                } elseif ($hardness -ge 10) {
                                    $possibleOreInfo.SuggestedTier = 4
                                } elseif ($hardness -ge 5) {
                                    $possibleOreInfo.SuggestedTier = 2
                                } else {
                                    $possibleOreInfo.SuggestedTier = 0
                                }
                            }
                        }
                    }
                    catch {
                        # If JSON parsing fails, just keep the default values
                    }
                    
                    $possibleOres += [PSCustomObject]$possibleOreInfo
                    $modOreCount++
                }
            }
        }
    }
    
    if ($modOreCount -gt 0) {
        $modOreStats[$modName] = $modOreCount
    }
}

# Generate suggestions file
$suggestionsFile = Join-Path -Path "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo" -ChildPath "UnknownOreSuggestions.ps1"

$suggestionsContent = "# Suggested classifications for unknown potential ores`n"
$suggestionsContent += "# Add these entries to your oreTiers hashtable in EnhancedMiningOrePMMO.ps1`n`n"
$suggestionsContent += "`$additionalOreTiers = @{`n"

# Group by confidence level
$highConfidence = $possibleOres | Where-Object { $_.Confidence -eq "Very High" -or $_.Confidence -eq "High" }
$mediumConfidence = $possibleOres | Where-Object { $_.Confidence -eq "Medium" }

# Process high confidence items first
$suggestionsContent += "    # HIGH CONFIDENCE ORE CANDIDATES`n"
foreach ($ore in ($highConfidence | Sort-Object -Property SuggestedTier)) {
    $suggestionsContent += "    `"$($ore.Name)`" = $($ore.SuggestedTier) # $($ore.Mod) - Confidence: $($ore.Confidence), Mining XP: $($ore.HasMiningXP), Requirement: $($ore.HasMiningRequirement)`n"
}

# Then medium confidence
$suggestionsContent += "`n    # MEDIUM CONFIDENCE ORE CANDIDATES`n"
foreach ($ore in ($mediumConfidence | Sort-Object -Property Mod)) {
    $suggestionsContent += "    `"$($ore.Name)`" = $($ore.SuggestedTier) # $($ore.Mod) - Confidence: $($ore.Confidence)`n"
}

$suggestionsContent += "}`n"
$suggestionsContent | Out-File -FilePath $suggestionsFile -Encoding utf8

# Generate detailed report
$reportFile = Join-Path -Path "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo" -ChildPath "UnknownOreReport.md"

$reportContent = "# Unknown Ore Analysis Report\n\n"
$reportContent += "This report identifies potential ore blocks that aren't yet classified in our tier system.\n\n"
$reportContent += "## Summary\n\n"
$reportContent += "- Total files scanned: $totalFiles\n"
$reportContent += "- Total block files: $totalBlockFiles\n"
$reportContent += "- Potential unclassified ores found: $($possibleOres.Count)\n\n"

$reportContent += "## Mods with Potential Unclassified Ores\n\n"
$reportContent += "| Mod | Potential Ores |\n"
$reportContent += "|-----|---------------|\n"
foreach ($mod in ($modOreStats.Keys | Sort-Object)) {
    $reportContent += "| $mod | $($modOreStats[$mod]) |\n"
}

$reportContent += "\n## High Confidence Ore Candidates\n\n"
$reportContent += "These blocks have strong indicators of being ores (mining XP, requirements, vein data).\n\n"
$reportContent += "| Name | Mod | Suggested Tier | Mining XP | Mining Req | Hardness |\n"
$reportContent += "|------|-----|---------------|-----------|------------|----------|\n"
foreach ($ore in ($highConfidence | Sort-Object -Property SuggestedTier)) {
    $reportContent += "| $($ore.Name) | $($ore.Mod) | $($ore.SuggestedTier) | $($ore.HasMiningXP) | $($ore.HasMiningRequirement) | $($ore.Hardness) |\n"
}

$reportContent += "\n## Medium Confidence Ore Candidates\n\n"
$reportContent += "These blocks match ore naming patterns but may need manual verification.\n\n"
$reportContent += "| Name | Mod | Suggested Tier | Hardness |\n"
$reportContent += "|------|-----|---------------|----------|\n"
foreach ($ore in ($mediumConfidence | Sort-Object -Property Mod)) {
    $reportContent += "| $($ore.Name) | $($ore.Mod) | $($ore.SuggestedTier) | $($ore.Hardness) |\n"
}

$reportContent | Out-File -FilePath $reportFile -Encoding utf8

# Display results
Write-Host "`nScan Complete!" -ForegroundColor Green
Write-Host "Files scanned: $totalFiles" -ForegroundColor White
Write-Host "Potential unclassified ores found: $($possibleOres.Count)" -ForegroundColor Yellow

Write-Host "`nMods with potential unclassified ores:" -ForegroundColor Cyan
foreach ($mod in ($modOreStats.Keys | Sort-Object)) {
    Write-Host "  $mod : $($modOreStats[$mod]) potential ores" -ForegroundColor Gray
}

Write-Host "`nHigh confidence ore candidates:" -ForegroundColor Green
foreach ($ore in ($highConfidence | Sort-Object -Property SuggestedTier)) {
    Write-Host "  $($ore.Name) ($($ore.Mod)) - Tier $($ore.SuggestedTier)" -ForegroundColor White
}

Write-Host "`nOrganized suggestions file created at: $suggestionsFile" -ForegroundColor Magenta
Write-Host "Detailed report created at: $reportFile" -ForegroundColor Magenta
