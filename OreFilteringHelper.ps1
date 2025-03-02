# This script helps filter ore blocks from furniture/decorative blocks in UnknownOreSuggestions

# Load the UnknownOreSuggestions file content
$suggestionsFile = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\UnknownOreSuggestions.ps1"
$suggestionsContent = Get-Content -Path $suggestionsFile -Raw

# Extract block names
$pattern = '\"([^\"]+)\"'
$matches = [regex]::Matches($suggestionsContent, $pattern)
$blockNames = $matches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

# Keywords that indicate a block is an ore or mining-related
$oreKeywords = @(
    "ore", "metal", "gem", "mineral", "crystal", "quartz", "deepslate_", 
    "raw_", "block_of_raw_", "uranium", "platinum", "mithril", "inferium",
    "prosperity", "fluorite", "anglesite", "benitoite", "time_crystal",
    "gold", "iron", "copper", "emerald", "diamond", "silver", "lead", "tin",
    "saltpeter", "sulfur", "zinc", "nickel", "antimony", "bauxite", "monazite",
    "salt", "tungsten", "titanium", "iesnium", "arcane_crystal", "soulium",
    "xychorium", "celestigem", "eclipsealloy", "void_crystal", "ancient_metal",
    "nitro_crystal", "atalphaite", "spirited_crystal", "starlight_crystal"
)

# Keywords that indicate a block is furniture or decorative
$furnitureKeywords = @(
    "seat", "bookcase", "display_case", "table", "shelf", "grandfather_clock",
    "fancy_clock", "tool_rack", "potion_shelf", "label", "armor_stand", "crafter",
    "chair", "sofa", "bench", "bed", "lamp", "banner", "carpet", "curtain", "wool"
)

# Filter blocks that match ore keywords but not furniture keywords
$possibleOres = @()
$possibleFurniture = @()

foreach ($block in $blockNames) {
    $isOreMatch = $false
    $isFurnitureMatch = $false
    
    # Check if the block matches any ore keywords
    foreach ($keyword in $oreKeywords) {
        if ($block -match $keyword) {
            $isOreMatch = $true
            break
        }
    }
    
    # Check if the block matches any furniture keywords
    foreach ($keyword in $furnitureKeywords) {
        if ($block -match $keyword) {
            $isFurnitureMatch = $true
            break
        }
    }
    
    # Categorize the block
    if ($isOreMatch -and -not $isFurnitureMatch) {
        $possibleOres += $block
    } elseif ($isFurnitureMatch) {
        $possibleFurniture += $block
    } else {
        # Blocks that don't match either set of keywords need manual review
        $possibleFurniture += $block
    }
}

# Generate code for the filtered ore blocks
$outputFile = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\FilteredOreBlocks.ps1"

$outputContent = "# Filtered ore blocks from UnknownOreSuggestions`n"
$outputContent += "# Add these to your oreTiers hashtable in EnhancedMiningOrePMMO.ps1`n`n"
$outputContent += "# Possible ore blocks to add to your tiers:`n"

foreach ($ore in ($possibleOres | Sort-Object)) {
    $outputContent += "    `"$ore`" = 2 # Adjust tier as needed`n"
}

$outputContent | Out-File -FilePath $outputFile -Encoding utf8

# Display results
Write-Host "Analysis complete!" -ForegroundColor Green
Write-Host "Possible ore blocks found: $($possibleOres.Count)" -ForegroundColor Cyan
Write-Host "Furniture/decorative blocks: $($possibleFurniture.Count)" -ForegroundColor Yellow
Write-Host "Results saved to: $outputFile" -ForegroundColor Magenta
