# Script to identify mods and assign technology skill level ranges
$dataPath = "d:\src\atm10_pmmo\atm_10_pack\src\main\resources\data\"
$outputPath = "d:\src\atm10_pmmo\scripts\tech\mod_tech_ranges.json"

# Initialize the categorized structure
$categorizedData = @{
    "high-tech" = @{}
    "mid-high-tech" = @{}
    "mid-tech" = @{}
    "low-mid-tech" = @{}
    "low-tech" = @{}
    "unknown" = @{}
    "none" = @{}
    "stats" = @{
        "generatedOn" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "categoryCounts" = @{
            "high-tech" = 0
            "mid-high-tech" = 0
            "mid-tech" = 0
            "low-mid-tech" = 0
            "low-tech" = 0
            "unknown" = 0
            "none" = 0
        }
    }
}

# Get all mod directories
$modDirectories = Get-ChildItem -Path $dataPath -Directory
$categorizedData.stats.totalModsAnalyzed = $modDirectories.Count

# Function to analyze mod tech level
function Get-ModTechRange {
    param ([string]$modName, [string]$modPath)
    
    # Define mod categories with their tech ranges
    $highTechMods = @(
        "ae2", "applied", "mekanism", "thermal", "rftools", "nuclearcraft", "biggerreactors", 
        "bigreactors", "reactor", "quantum", "computer", "computercraft", "flux", 
        "refinedstorage", "powah", "modernindustrialization", "industrial", "immersive", 
        "xycraft", "extreme", "ftb", "ultimate", "energy", "neoforge", "tech", "digital"
    )
    
    $midHighTechMods = @(
        "create", "botania", "tinkers", "productive", "ender", "factory", "steam", 
        "power", "pneumatic", "machines", "advanced", "xnet", "minecolony", 
        "minecolonies", "cable", "pipe", "conduit", "automation"
    )
    
    $midTechMods = @(
        "railcraft", "storage", "drawers", "chest", "ironfurnaces", "mechanisms", 
        "generators", "elevator", "backpack", "sophisticated", "cyclic", "pipeline", 
        "waystones", "travel", "allthemodium", "transport"
    )
    
    $lowMidTechMods = @(
        "farmersdelight", "cooking", "craft", "crafters", "food", "culinary", 
        "building", "furniture", "decoration", "chipped", "chisel", "architect", 
        "tool", "tools", "utility", "utilities", "constructors", "supplementaries", 
        "material", "materials", "resource", "resources"
    )
    
    $lowTechMods = @(
        "minecraft", "vanilla", "simple", "basic", "primitive", "nature"
    )
    
    # Check for tech-related files
    $hasPmmoFiles = Test-Path -Path (Join-Path -Path $modPath -ChildPath "pmmo")
    $hasBlocksOrItems = (Test-Path -Path (Join-Path -Path $modPath -ChildPath "pmmo\blocks")) -or 
                        (Test-Path -Path (Join-Path -Path $modPath -ChildPath "pmmo\items"))
    
    # Default to no tech range
    $min = 0
    $max = 0
    $category = "none"
    
    # Analyze mod name for tech level
    $modNameLower = $modName.ToLower()
    
    if ($highTechMods | Where-Object { $modNameLower -like "*$_*" }) {
        $min = 200
        $max = 500
        $category = "high-tech"
    }
    elseif ($midHighTechMods | Where-Object { $modNameLower -like "*$_*" }) {
        $min = 150
        $max = 400
        $category = "mid-high-tech"
    }
    elseif ($midTechMods | Where-Object { $modNameLower -like "*$_*" }) {
        $min = 100
        $max = 300
        $category = "mid-tech"
    }
    elseif ($lowMidTechMods | Where-Object { $modNameLower -like "*$_*" }) {
        $min = 50
        $max = 200
        $category = "low-mid-tech"
    }
    elseif ($lowTechMods | Where-Object { $modNameLower -like "*$_*" }) {
        $min = 1
        $max = 100
        $category = "low-tech"
    }
    elseif ($hasBlocksOrItems) {
        # If mod has PMMO files but no category match, mark as "unknown"
        $category = "unknown"
    }
    
    # Special cases by exact mod name
    switch ($modName) {
        "minecraft" { $min = 1; $max = 100; $category = "low-tech" }
        "pmmo" { $min = 0; $max = 0; $category = "none" } # Configuration mod, not a tech mod
        "ae2" { $min = 300; $max = 500; $category = "high-tech" }
        "mekanism" { $min = 250; $max = 500; $category = "high-tech" }
        "create" { $min = 150; $max = 350; $category = "mid-high-tech" }
        "industrialforegoing" { $min = 200; $max = 450; $category = "high-tech" }
        "sophisticatedbackpacks" { $min = 75; $max = 175; $category = "low-mid-tech" }
        "thermal" { $min = 200; $max = 400; $category = "high-tech" }
        "refinedstorage" { $min = 275; $max = 500; $category = "high-tech" }
    }
    
    # Return the range and category
    return @{
        "min" = $min
        "max" = $max
        "category" = $category
    }
}

# Process each mod directory
Write-Host "Analyzing mods and assigning technology ranges..." -ForegroundColor Cyan
$modsWithTech = 0
$modsUnknown = 0

foreach ($modDir in $modDirectories) {
    $modName = $modDir.Name
    $pmmoPath = Join-Path -Path $modDir.FullName -ChildPath "pmmo"
    
    # Check if mod has PMMO files
    $hasPmmoFiles = Test-Path -Path $pmmoPath
    
    # Get tech range
    $techRange = Get-ModTechRange -modName $modName -modPath $modDir.FullName
    $category = $techRange.category
    
    # Update stats
    if ($techRange.max -gt 0) { $modsWithTech++ }
    if ($category -eq "unknown") { $modsUnknown++ }
    $categorizedData.stats.categoryCounts[$category]++
    
    # Add mod to its category
    $categorizedData[$category][$modName] = @{
        "techMin" = $techRange.min
        "techMax" = $techRange.max
        "hasPmmoFiles" = $hasPmmoFiles
    }
    
    # Output progress with different colors based on category
    if ($category -eq "unknown") {
        Write-Host "$modName - Category: UNKNOWN (needs manual review)" -ForegroundColor Magenta
    }
    elseif ($category -eq "none") {
        Write-Host "$modName - No tech requirements" -ForegroundColor Gray
    }
    else {
        Write-Host "$modName - $category : $($techRange.min) to $($techRange.max)" -ForegroundColor Yellow
    }
}

# Add the final stats
$categorizedData.stats.modsWithTech = $modsWithTech
$categorizedData.stats.modsUnknown = $modsUnknown

# Convert to JSON and save
$jsonOutput = $categorizedData | ConvertTo-Json -Depth 5
$jsonOutput | Out-File -FilePath $outputPath -Encoding UTF8
Write-Host "`nAnalysis complete. JSON output saved to $outputPath" -ForegroundColor Green
Write-Host "Found $($modDirectories.Count) mods, $modsWithTech with technology requirements." -ForegroundColor Cyan

# Output a summary of tech tiers
Write-Host "`nTech Tier Summary:" -ForegroundColor Magenta
Write-Host "High Tech (200-500): $($categorizedData.stats.categoryCounts['high-tech']) mods" -ForegroundColor Yellow
Write-Host "Mid-High Tech (150-400): $($categorizedData.stats.categoryCounts['mid-high-tech']) mods" -ForegroundColor Yellow
Write-Host "Mid Tech (100-300): $($categorizedData.stats.categoryCounts['mid-tech']) mods" -ForegroundColor Yellow
Write-Host "Low-Mid Tech (50-200): $($categorizedData.stats.categoryCounts['low-mid-tech']) mods" -ForegroundColor Yellow
Write-Host "Low Tech (1-100): $($categorizedData.stats.categoryCounts['low-tech']) mods" -ForegroundColor Yellow
Write-Host "Unknown Tech Level: $($categorizedData.stats.categoryCounts['unknown']) mods" -ForegroundColor Magenta
Write-Host "No Tech: $($categorizedData.stats.categoryCounts['none']) mods" -ForegroundColor Gray

# Output the list of unknown mods for manual review
$unknownMods = @($categorizedData.unknown.Keys)
if ($unknownMods.Count -gt 0) {
    Write-Host "`nMods requiring manual tech level assignment:" -ForegroundColor Magenta
    foreach ($modName in $unknownMods) {
        Write-Host "- $modName" -ForegroundColor White
    }
}