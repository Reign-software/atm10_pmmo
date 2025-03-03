# Script to remove combat requirements from tools that shouldn't be weapons

# Define root path for data
$rootPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data"

# Define tool patterns to identify tool items
$toolPatterns = @(
    "pickaxe", "_pick", "pick_",
    "_axe", "axe_",
    "shovel", "spade", "excavator",
    "_hoe", "hoe_",
    "shears", "cutter", "clipper",
    "mattock", "multitool"
)

# Define actual weapon-tool patterns (tools that can reasonably be used as weapons)
# These will keep their combat requirements
$weaponToolPatterns = @(
    "battle_axe", "battleaxe", "war_axe", "waraxe",
    "tomahawk", "hatchet", "cleaver",
    "hammer", # Only if it's a weapon hammer, not a crafting hammer
    "paxel", "mace", "aiot"
)

# Stats counters
$processedCount = 0
$modifiedCount = 0
$modsWithModifiedTools = @{}

# Process all JSON files in mod data directories
Write-Host "Scanning for tool items with combat requirements..." -ForegroundColor Cyan

foreach ($mod in (Get-ChildItem -Path $rootPath -Directory)) {
    $modName = $mod.Name
    $itemsPath = Join-Path -Path $mod.FullName -ChildPath "pmmo\items"
    
    # Skip if items directory doesn't exist
    if (-not (Test-Path $itemsPath)) {
        continue
    }
    
    # Get all JSON files in the items directory
    $itemFiles = Get-ChildItem -Path $itemsPath -Filter "*.json"
    $modToolCount = 0
    
    foreach ($file in $itemFiles) {
        $fileName = $file.BaseName.ToLower()
        $processedCount++
        
        # First check if this is a tool
        $isTool = $false
        foreach ($pattern in $toolPatterns) {
            if ($fileName -match $pattern) {
                $isTool = $true
                break
            }
        }
        
        # Skip if not a tool
        if (-not $isTool) {
            continue
        }
        
        # Next, check if it's a legitimate weapon-tool that should keep combat requirements
        $isWeaponTool = $false
        foreach ($pattern in $weaponToolPatterns) {
            if ($fileName -match $pattern) {
                $isWeaponTool = $true
                break
            }
        }
        
        # Skip if it's a legitimate weapon-tool
        if ($isWeaponTool) {
            Write-Host "  Keeping combat requirement for weapon-tool: $modName`:$fileName" -ForegroundColor Blue
            continue
        }
        
        try {
            # Read the JSON content
            $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            
            # Check if the item has a WEAPON requirement with combat
            $hasCombatRequirement = $false
            
            if ($jsonContent.PSObject.Properties["requirements"] -and
                $jsonContent.requirements.PSObject.Properties["WEAPON"] -and
                $jsonContent.requirements.WEAPON.PSObject.Properties["combat"]) {
                $hasCombatRequirement = $true
            }
            
            # Only process items with combat requirements
            if ($hasCombatRequirement) {
                # Remove the combat requirement
                $jsonContent.requirements.WEAPON.PSObject.Properties.Remove("combat")
                
                # If WEAPON section is now empty, remove it too
                if (-not $jsonContent.requirements.WEAPON.PSObject.Properties.MemberNames) {
                    $jsonContent.requirements.PSObject.Properties.Remove("WEAPON")
                }
                
                # Save the modified JSON
                $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $file.FullName
                Write-Host "  Removed combat requirement from $modName`:$fileName" -ForegroundColor Yellow
                $modifiedCount++
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
Write-Host "Tool items modified (combat requirement removed): $modifiedCount" -ForegroundColor Cyan

# Report on mods that had tools modified
if ($modsWithModifiedTools.Count -gt 0) {
    Write-Host "`nMods With Tools Modified:" -ForegroundColor Magenta
    foreach ($mod in ($modsWithModifiedTools.Keys | Sort-Object)) {
        $count = $modsWithModifiedTools[$mod]
        Write-Host "  - $mod : $count item(s)" -ForegroundColor White
    }
}

Write-Host "`nNote: Combat requirements were preserved for the following types of weapon-tools:" -ForegroundColor Yellow
foreach ($pattern in ($weaponToolPatterns | Sort-Object)) {
    Write-Host "  - $pattern" -ForegroundColor White
}
