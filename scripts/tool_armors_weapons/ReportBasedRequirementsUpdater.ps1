# Script to update item requirements using the ItemAnalysisReport.json as input

# Define paths
$reportPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\ItemAnalysisReportDetailed.json"
$rootPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data"

# Load the analysis report
Write-Host "Loading item analysis data..." -ForegroundColor Cyan
$itemData = Get-Content -Path $reportPath -Raw | ConvertFrom-Json

# Define tier levels and their requirements
$tierLevels = @(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500)

# Set up counters for stats
$processedCount = 0
$modifiedCount = 0
$itemStats = @{
    "armor" = 0
    "tools" = 0
    "weapons" = 0
    "tech" = 0
    "magic" = 0
    "other" = 0
}

# Helper function to get item requirements based on type and tier
function Get-ItemRequirements {
    param(
        [string]$itemType,
        [int]$tier,
        [bool]$isTech,
        [bool]$isMagic,
        [bool]$isArchery = $false
    )
    
    $baseLevel = $tierLevels[$tier]
    $requirements = @{}
    
    # Apply base requirements based on item type
    switch ($itemType) {
        "pickaxe" {
            $requirements["smithing"] = $baseLevel
            $requirements["mining"] = $baseLevel
        }
        "axe" {
            $requirements["smithing"] = $baseLevel
            $requirements["woodcutting"] = $baseLevel
        }
        "shovel" {
            $requirements["smithing"] = $baseLevel
            $requirements["excavation"] = $baseLevel
        }
        "hoe" {
            $requirements["smithing"] = $baseLevel
            $requirements["farming"] = $baseLevel
        }
        "shears" {
            $requirements["smithing"] = $baseLevel
            $requirements["farming"] = [Math]::Max(0, $baseLevel - 50)
        }
        "paxel" {
            $requirements["smithing"] = $baseLevel
            $requirements["mining"] = $baseLevel
            $requirements["woodcutting"] = $baseLevel
            $requirements["excavation"] = $baseLevel
        }
        "armor" {
            $requirements["smithing"] = $baseLevel
            $requirements["endurance"] = $baseLevel
        }
        "weapon" {
            $requirements["smithing"] = $baseLevel
            if ($isArchery) {
                $requirements["archery"] = $baseLevel
            } else {
                $requirements["combat"] = $baseLevel
            }
        }
        default {
            $requirements["smithing"] = $baseLevel
        }
    }
    
    # Add tech/magic requirements if applicable
    if ($isTech) {
        $requirements["technology"] = $baseLevel
    }
    
    if ($isMagic) {
        $requirements["magic"] = $baseLevel
    }
    
    return $requirements
}

# Process all items from the report
Write-Host "Processing items based on analysis report..." -ForegroundColor Yellow

# First gather all items into a lookup dictionary for quick access
$itemLookup = @{}

# Process all tool categories
foreach ($toolType in @("pickaxes", "axes", "shovels", "hoes", "shears", "paxels")) {
    foreach ($item in $itemData.allItems.$toolType) {
        $key = "$($item.mod):$($item.name)"
        $itemLookup[$key] = @{
            Type = $toolType -replace "s$", "" # Remove trailing 's'
            Tier = $item.tier
            IsTech = $item.isTech
            IsMagic = $item.isMagic
            IsArchery = $false
        }
    }
}

# Process armor
foreach ($item in $itemData.allItems.armor) {
    $key = "$($item.mod):$($item.name)"
    $itemLookup[$key] = @{
        Type = "armor"
        Tier = $item.tier
        IsTech = $item.isTech
        IsMagic = $item.isMagic
        IsArchery = $false
    }
}

# Process weapons, checking for archery weapons
foreach ($item in $itemData.allItems.weapons) {
    $key = "$($item.mod):$($item.name)"
    $isArchery = $item.name -match "bow|arrow|bolt|quiver"
    $itemLookup[$key] = @{
        Type = "weapon"
        Tier = $item.tier
        IsTech = $item.isTech
        IsMagic = $item.isMagic
        IsArchery = $isArchery
    }
}

# Now process all JSON files in mod data directories
foreach ($mod in (Get-ChildItem -Path $rootPath -Directory)) {
    $modName = $mod.Name
    $itemsPath = Join-Path -Path $mod.FullName -ChildPath "pmmo\items"
    
    # Skip if items directory doesn't exist
    if (-not (Test-Path $itemsPath)) {
        continue
    }
    
    Write-Host "Processing $modName items..." -ForegroundColor Magenta
    
    # Get all JSON files in the items directory
    $itemFiles = Get-ChildItem -Path $itemsPath -Filter "*.json"
    
    foreach ($file in $itemFiles) {
        $fileName = $file.BaseName
        $key = "$modName`:$fileName"
        $processedCount++
        
        if ($itemLookup.ContainsKey($key)) {
            $itemInfo = $itemLookup[$key]
            
            # Get appropriate requirements
            $requirements = Get-ItemRequirements `
                -itemType $itemInfo.Type `
                -tier $itemInfo.Tier `
                -isTech $itemInfo.IsTech `
                -isMagic $itemInfo.IsMagic `
                -isArchery $itemInfo.IsArchery
                
            try {
                $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                $modified = $false
                
                # Ensure requirements node exists
                if (-not $jsonContent.PSObject.Properties["requirements"]) {
                    $jsonContent | Add-Member -NotePropertyName "requirements" -NotePropertyValue @{} -Force
                    $modified = $true
                }
                
                # Determine requirement types based on item type
                $requirementTypes = @("USE")  # All items should have USE
                
                switch ($itemInfo.Type) {
                    "armor" { $requirementTypes += "WEAR" }
                    { $_ -in @("pickaxe", "axe", "shovel", "hoe", "shears", "paxel") } { $requirementTypes += "TOOL" }
                    "weapon" { $requirementTypes += "WEAPON" }
                }
                
                # Create requirement type nodes if they don't exist
                foreach ($reqType in $requirementTypes) {
                    if (-not $jsonContent.requirements.PSObject.Properties[$reqType]) {
                        $jsonContent.requirements | Add-Member -NotePropertyName $reqType -NotePropertyValue @{} -Force
                        $modified = $true
                    }
                    
                    # Apply requirements for each skill
                    foreach ($skill in $requirements.Keys) {
                        $reqValue = $requirements[$skill]
                        
                        # Only overwrite if current value is lower or doesn't exist
                        $currentValue = 0
                        if ($jsonContent.requirements.$reqType.PSObject.Properties[$skill]) {
                            $currentValue = $jsonContent.requirements.$reqType.$skill
                        }
                        
                        if ($currentValue -lt $reqValue) {
                            $jsonContent.requirements.$reqType | Add-Member -NotePropertyName $skill -NotePropertyValue $reqValue -Force
                            $modified = $true
                        }
                    }
                }
                
                # Save changes if modifications were made
                if ($modified) {
                    $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $file.FullName
                    Write-Host "  Updated: $fileName (${modName}:$($itemInfo.Type), Tier $($itemInfo.Tier))" -ForegroundColor Green
                    $modifiedCount++
                    
                    # Update stats
                    switch ($itemInfo.Type) {
                        "armor" { $itemStats.armor++ }
                        { $_ -in @("pickaxe", "axe", "shovel", "hoe", "shears", "paxel") } { $itemStats.tools++ }
                        "weapon" { $itemStats.weapons++ }
                    }
                    
                    if ($itemInfo.IsTech) { $itemStats.tech++ }
                    if ($itemInfo.IsMagic) { $itemStats.magic++ }
                }
            }
            catch {
                Write-Host "  Error processing $fileName : $_" -ForegroundColor Red
            }
        }
        else {
            # Item not found in report - might be a new item or not categorized
            $itemStats.other++
        }
    }
}

# Display results
Write-Host "`nItem Requirements Update Complete!" -ForegroundColor Cyan
Write-Host "Files processed: $processedCount" -ForegroundColor White
Write-Host "Files modified: $modifiedCount" -ForegroundColor Green
Write-Host "`nItems modified by type:" -ForegroundColor Yellow
Write-Host "  Armor: $($itemStats.armor)" -ForegroundColor Magenta
Write-Host "  Tools: $($itemStats.tools)" -ForegroundColor Blue
Write-Host "  Weapons: $($itemStats.weapons)" -ForegroundColor Red
Write-Host "  Tech items: $($itemStats.tech)" -ForegroundColor Cyan
Write-Host "  Magic items: $($itemStats.magic)" -ForegroundColor Yellow
Write-Host "  Uncategorized items: $($itemStats.other)" -ForegroundColor Gray
