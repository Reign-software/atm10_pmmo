# Script to find all bow and crossbow items and add them to archery perks in perks.json

# Define root path for data
$rootPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data"

# Define path to perks.json
$perksJsonPath = Join-Path -Path $rootPath -ChildPath "pmmo\config\perks.json"

# Define patterns to identify bows and crossbows (case insensitive)
$bowPatterns = @(
    "bow", "crossbow", "longbow", "shortbow", "flatbow", "recurve", "arbalest"
)

# Exclusion patterns - items containing these are NOT bows despite matching patterns
$exclusionPatterns = @(
    "bowl", "elbow", "rainbow", "window", "willow", "below", "pillow", "shadow",
    "oxbow", "eyebrow", "arbor", "bowl", "blow", "bollard", "bough", "arrow",
    "crossblock", "crowbar", "flowing", "following", "showroom", "oxbow", "crow"
)



# Stats counters
$modsProcessed = 0
$itemsProcessed = 0
$bowsFound = 0
$newBowsAdded = 0

Write-Host "Starting search for bow and crossbow items..." -ForegroundColor Cyan

# Collect all bow/crossbow items
$allBows = [System.Collections.ArrayList]::new()

# Process all mods to find bow items
foreach ($mod in (Get-ChildItem -Path $rootPath -Directory)) {
    $modName = $mod.Name
    $modsProcessed++
    
    # Search for json files that might contain item information
    $jsonFiles = Get-ChildItem -Path $mod.FullName -Filter "*.json" -Recurse
    
    foreach ($file in $jsonFiles) {
        $itemsProcessed++
        $filePath = $file.FullName
        $fileName = $file.BaseName.ToLower()
        
        # First check exclusions
        $excluded = $false
        foreach ($pattern in $exclusionPatterns) {
            if ($fileName -match $pattern) {
                $excluded = $true
                break
            }
        }
        if ($excluded) { continue }
        
        # Check for bow patterns in filename
        $isBow = $false
        foreach ($pattern in $bowPatterns) {
            if ($fileName -match $pattern) {
                $isBow = $true
                break
            }
        }
        
        # If it's a bow, add it to our list
        if ($isBow) {
            $itemId = "$modName`:$fileName"
            [void]$allBows.Add($itemId)
            $bowsFound++
        }
        
       
    }
}

Write-Host "Found $bowsFound potential bow/crossbow items across $modsProcessed mods" -ForegroundColor Green

# Additional known bow items that might be missed by the scan
$knownBows = @(
    "minecraft:bow",
    "minecraft:crossbow",
    "archers_paradox:phantasm_bow",
    "archers_paradox:thunder_bow",
    "archers_paradox:ghostbuster_bow",
    "silentgear:crossbow",
    "silentgear:longbow",
    "ars_nouveau:spell_bow",
    "supplementaries:crossbow_bolt",
    "twilightforest:triple_bow",
    "twilightforest:seeker_bow",
    "twilightforest:ice_bow",
    "twilightforest:ender_bow",
    "twilightforest:twilight_bow",
    "mekanism:electric_bow",
    "immersiveengineering:railgun",
    "immersiveengineering:revolver",
    "pneumaticcraft:minigun",
    "pneumaticcraft:air_cannon"
)

# Add known bow items to our list, avoiding duplicates
foreach ($bow in $knownBows) {
    if ($allBows -notcontains $bow) {
        [void]$allBows.Add($bow)
        $bowsFound++
    }
}

# Remove duplicate entries and sort
$uniqueBows = $allBows | Sort-Object -Unique

Write-Host "Total unique bow/crossbow items found: $($uniqueBows.Count)" -ForegroundColor Green

# Read and process perks.json file
Write-Host "Updating perks.json file with found bow items..." -ForegroundColor Cyan

try {
    $perksJson = Get-Content -Path $perksJsonPath -Raw | ConvertFrom-Json
    
    # Find the archery skill's DEAL_DAMAGE perk entry
    $archeryPerkFound = $false
    
    foreach ($perkEntry in $perksJson.perks.DEAL_DAMAGE) {
        if ($perkEntry.skill -eq "archery") {
            $archeryPerkFound = $true
            
            # Get current applies_to items
            $currentBows = @()
            if ($perkEntry.PSObject.Properties["applies_to"]) {
                $currentBows = $perkEntry.applies_to
            } else {
                # Create applies_to if it doesn't exist
                $perkEntry | Add-Member -NotePropertyName "applies_to" -NotePropertyValue @() -Force
            }
            
            Write-Host "Current bows in perk: $($currentBows.Count)" -ForegroundColor Yellow
            
            # Create a combined, deduplicated list
            $newBows = @()
            foreach ($bow in $currentBows) {
                if ($bow -ne $null -and $bow -ne "") {
                    $newBows += $bow
                }
            }
            
            foreach ($bow in $uniqueBows) {
                if ($newBows -notcontains $bow) {
                    $newBows += $bow
                    $newBowsAdded++
                }
            }
            
            # Update the perk with new list
            $perkEntry.applies_to = $newBows
            
            Write-Host "Added $newBowsAdded new bow/crossbow items to archery perk" -ForegroundColor Green
            break
        }
    }
    
    # If no archery perk was found, create one
    if (-not $archeryPerkFound) {
        $newArcheryPerk = [PSCustomObject]@{
            "applies_to" = $uniqueBows
            "perk" = "pmmo:damage_boost"
            "skill" = "archery"
        }
        
        # Add to DEAL_DAMAGE array
        $perksJson.perks.DEAL_DAMAGE += $newArcheryPerk
        
        $newBowsAdded = $uniqueBows.Count
        Write-Host "Created new archery perk with $newBowsAdded bow/crossbow items" -ForegroundColor Green
    }
    
    # Save the updated JSON back to the file
    $perksJson | ConvertTo-Json -Depth 10 | Set-Content -Path $perksJsonPath
    
    Write-Host "Successfully updated perks.json file" -ForegroundColor Green
}
catch {
    Write-Host "Error processing perks.json: $_" -ForegroundColor Red
}

# Summary
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "- Mods processed: $modsProcessed" -ForegroundColor White
Write-Host "- Items scanned: $itemsProcessed" -ForegroundColor White
Write-Host "- Bow/crossbow items found: $bowsFound" -ForegroundColor White
Write-Host "- Bows added to archery perk: $newBowsAdded" -ForegroundColor Green

# Save list of found bows to a file for reference
$uniqueBows | Out-File -FilePath (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "bow_items_list.txt")
Write-Host "`nBow item list saved to bow_items_list.txt" -ForegroundColor Yellow
