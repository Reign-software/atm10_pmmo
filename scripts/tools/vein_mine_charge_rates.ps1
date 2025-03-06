# Script to add vein_data configuration to all gathering tools

# Define root path for data
$rootPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data"

# Define tool patterns to identify gathering tools
$gatheringToolPatterns = @(
    "pickaxe", "_pick", "pick_",
    "_axe", "axe_", 
    "shovel", "spade", "excavator",
    "_hoe", "hoe_",
    "mattock", "paxel", "hammer", "multitool",
    "saw", "mallet", "chisel", "drill", "sickle"
)

# Define tool tier patterns and their corresponding vein_data values
$toolTiers = @{
    # Vanilla tiers
    "wooden_|wood_|_wood|_wooden" = @{ chargeCap = 10; chargeRate = 0.05 }
    "stone_|_stone" = @{ chargeCap = 15; chargeRate = 0.075 }
    "iron_|_iron" = @{ chargeCap = 20; chargeRate = 0.085 }
    "gold_|_gold|golden_|_golden" = @{ chargeCap = 15; chargeRate = 0.1 }
    "diamond_|_diamond" = @{ chargeCap = 30; chargeRate = 0.1 }
    "netherite_|_netherite" = @{ chargeCap = 40; chargeRate = 0.125 }
    
    # Common modded low tiers
    "copper_|_copper|tin_|_tin|bronze_|_bronze|silver_|_silver|aluminum_|_aluminum|lead_|_lead|nickel_|_nickel|zinc_|_zinc" = 
        @{ chargeCap = 18; chargeRate = 0.08 }
    
    # Common modded mid tiers
    "steel_|_steel|invar_|_invar|electrum_|_electrum|constantan_|_constantan|lumium_|_lumium|signalum_|_signalum|brass_|_brass" = 
        @{ chargeCap = 25; chargeRate = 0.09 }
    
    # Common modded high tiers
    "mithril_|_mithril|titanium_|_titanium|platinum_|_platinum|osmium_|_osmium|cobalt_|_cobalt|adamantite_|_adamantite|manyullyn_|_manyullyn|enderium_|_enderium|vibranium_|_vibranium" = 
        @{ chargeCap = 35; chargeRate = 0.11 }
    
    # End-game modded tiers
    "dragon_|_dragon|wyvern_|_wyvern|awakened_|_awakened|chaotic_|_chaotic|ultimate_|_ultimate|infinity_|_infinity|creative_|_creative" = 
        @{ chargeCap = 40; chargeRate = 0.15 }
    
    # Default values for unrecognized tiers
    "default" = @{ chargeCap = 20; chargeRate = 0.08 }
}

# Stats counters
$processedCount = 0
$addedCount = 0
$updatedCount = 0
$skippedCount = 0
$modsWithModifiedTools = @{}

# Process all JSON files in mod data directories
Write-Host "Adding vein mining capabilities to gathering tools..." -ForegroundColor Cyan

foreach ($mod in (Get-ChildItem -Path $rootPath -Directory)) {
    $modName = $mod.Name
    $itemsPath = Join-Path -Path $mod.FullName -ChildPath "pmmo\items"
    
    # Skip if items directory doesn't exist
    if (-not (Test-Path $itemsPath)) {
        continue
    }
    
    # Get all JSON files in the items directory
    $itemFiles = Get-ChildItem -Path $itemsPath -Filter "*.json" -Recurse
    $modToolCount = 0
    
    foreach ($file in $itemFiles) {
        $fileName = $file.BaseName.ToLower()
        $processedCount++
        
        # Check if this is a gathering tool
        $isGatheringTool = $false
        foreach ($pattern in $gatheringToolPatterns) {
            if ($fileName -match $pattern) {
                $isGatheringTool = $true
                break
            }
        }
        
        # Skip if not a gathering tool
        if (-not $isGatheringTool) {
            continue
        }
        
        try {
            # Read the JSON content
            $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $modified = $false
            
            # Determine tool tier from filename
            $tierData = $toolTiers["default"]
            foreach ($tierPattern in $toolTiers.Keys) {
                if ($tierPattern -eq "default") { continue }
                $patterns = $tierPattern.Split('|')
                foreach ($pattern in $patterns) {
                    if ($fileName -match $pattern) {
                        $tierData = $toolTiers[$tierPattern]
                        break
                    }
                }
                if ($tierData -ne $toolTiers["default"]) { break }
            }
            
            # Check if vein_data already exists
            if ($jsonContent.PSObject.Properties["vein_data"]) {
                # Update existing vein_data with new values, but only if values are lower
                $currentChargeCap = $jsonContent.vein_data.chargeCap
                $currentChargeRate = $jsonContent.vein_data.chargeRate
                
                $updateNeeded = $false
                
                # Only update if existing values are missing or lower
                if (-not $currentChargeCap -or $currentChargeCap -lt $tierData.chargeCap) {
                    $updateNeeded = $true
                }
                
                if (-not $currentChargeRate -or $currentChargeRate -lt $tierData.chargeRate) {
                    $updateNeeded = $true
                }
                
                if ($updateNeeded) {
                    $jsonContent.vein_data.chargeCap = $tierData.chargeCap
                    $jsonContent.vein_data.chargeRate = $tierData.chargeRate
                    $modified = $true
                    $updatedCount++
                    Write-Host "  Updated vein_data for $modName`:$fileName" -ForegroundColor Yellow
                } else {
                    $skippedCount++
                }
            }
            else {
                # Add new vein_data node
                $veinDataObject = [PSCustomObject]@{
                    chargeCap = $tierData.chargeCap
                    chargeRate = $tierData.chargeRate
                }
                
                # Create a new property for vein_data with the object as its value
                $jsonContent | Add-Member -MemberType NoteProperty -Name "vein_data" -Value $veinDataObject
                $modified = $true
                $addedCount++
                Write-Host "  Added vein_data to $modName`:$fileName" -ForegroundColor Green
            }
            
            # Save the modified JSON if changes were made
            if ($modified) {
                $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $file.FullName
                $modToolCount++
                
                # Track mods with modifications
                if (-not $modsWithModifiedTools.ContainsKey($modName)) {
                    $modsWithModifiedTools[$modName] = 0
                }
                $modsWithModifiedTools[$modName]++
            }
        }
        catch {
            Write-Host "  Error processing $fileName : $_" -ForegroundColor Red
        }
    }
    
    if ($modToolCount -gt 0) {
        Write-Host "Modified $modToolCount tools in mod $modName" -ForegroundColor Cyan
    }
}

# Display results
Write-Host "`nProcessing complete!" -ForegroundColor Green
Write-Host "Tool items processed: $processedCount" -ForegroundColor White
Write-Host "New vein_data added: $addedCount" -ForegroundColor Green
Write-Host "Existing vein_data updated: $updatedCount" -ForegroundColor Yellow
Write-Host "Existing vein_data kept (higher values): $skippedCount" -ForegroundColor Blue

# Report on mods that had tools modified
if ($modsWithModifiedTools.Count -gt 0) {
    Write-Host "`nMods With Tools Modified:" -ForegroundColor Magenta
    foreach ($mod in ($modsWithModifiedTools.Keys | Sort-Object)) {
        $count = $modsWithModifiedTools[$mod]
        Write-Host "  - $mod : $count item(s)" -ForegroundColor White
    }
}

Write-Host "`nTool Tier Configuration:" -ForegroundColor Cyan
foreach ($tierPattern in $toolTiers.Keys) {
    $tier = $toolTiers[$tierPattern]
    Write-Host "  - $tierPattern" -ForegroundColor White
    Write-Host "      chargeCap: $($tier.chargeCap), chargeRate: $($tier.chargeRate)" -ForegroundColor Gray
}