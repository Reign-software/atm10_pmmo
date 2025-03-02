# Script to visualize and analyze item data from JSON report

# Import item analysis data
$jsonPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\ItemAnalysisReportDetailed.json"
$itemData = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json

# Define output folder for charts
$outputFolder = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\ItemAnalysisCharts"
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
}

Write-Host "Analyzing PMMO item data..." -ForegroundColor Cyan

# Summary of item types
$itemTypeCounts = @{
    "Armor" = $itemData.allItems.armor.Count
    "Pickaxes" = $itemData.allItems.pickaxes.Count
    "Axes" = $itemData.allItems.axes.Count
    "Shovels" = $itemData.allItems.shovels.Count
    "Hoes" = $itemData.allItems.hoes.Count
    "Shears" = $itemData.allItems.shears.Count
    "Paxels" = $itemData.allItems.paxels.Count
    "Weapons" = $itemData.allItems.weapons.Count
}

# Generate summary report
$summaryFile = Join-Path -Path $outputFolder -ChildPath "ItemSummary.txt"
$summaryContent = "=== PMMO Item Analysis Summary ===`n`n"
$totalItems = ($itemTypeCounts.Values | Measure-Object -Sum).Sum
$summaryContent += "Total items analyzed: $totalItems`n`n"
$summaryContent += "Item Type Distribution:`n"
foreach ($type in $itemTypeCounts.Keys | Sort-Object) {
    $percentage = [Math]::Round(($itemTypeCounts[$type] / $totalItems) * 100, 1)
    $summaryContent += "- $type : $($itemTypeCounts[$type]) ($percentage%)`n"
}

# Calculate tier distribution
$tierDistribution = @{}
for ($i = 0; $i -le 10; $i++) {
    $tierDistribution["Tier $i"] = $itemData.itemsByTier."tier$i".Count
}
$summaryContent += "`nTier Distribution:`n"
foreach ($tier in $tierDistribution.Keys | Sort-Object) {
    $percentage = [Math]::Round(($tierDistribution[$tier] / $totalItems) * 100, 1)
    $summaryContent += "- $tier : $($tierDistribution[$tier]) ($percentage%)`n"
}

# Calculate mod distribution (top 10)
$modCounts = @{}
foreach ($mod in $itemData.itemsByMod.PSObject.Properties.Name) {
    $modCounts[$mod] = $itemData.itemsByMod.$mod.Count
}
$top10Mods = $modCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10
$summaryContent += "`nTop 10 Mods by Item Count:`n"
foreach ($mod in $top10Mods) {
    $percentage = [Math]::Round(($mod.Value / $totalItems) * 100, 1)
    $summaryContent += "- $($mod.Name) : $($mod.Value) ($percentage%)`n"
}

# Add tech vs magic stats
$techCount = ($itemData.allItems.PSObject.Properties.Name | ForEach-Object { $itemData.allItems.$_.Where({$_.isTech -eq $true}).Count } | Measure-Object -Sum).Sum
$magicCount = ($itemData.allItems.PSObject.Properties.Name | ForEach-Object { $itemData.allItems.$_.Where({$_.isMagic -eq $true}).Count } | Measure-Object -Sum).Sum
$summaryContent += "`nTechnology vs Magic Items:`n"
$summaryContent += "- Technology items: $techCount ($([Math]::Round(($techCount / $totalItems) * 100, 1))%)`n"
$summaryContent += "- Magic items: $magicCount ($([Math]::Round(($magicCount / $totalItems) * 100, 1))%)`n"

# Generate skill requirement impact stats
$summaryContent += "`nSkill Requirement Impact (approximate):`n"
$summaryContent += "- Smithing: $totalItems items`n"
$summaryContent += "- Endurance: $($itemData.allItems.armor.Count) items`n"
$summaryContent += "- Mining: $($itemData.allItems.pickaxes.Count + $itemData.allItems.paxels.Count) items`n"
$summaryContent += "- Woodcutting: $($itemData.allItems.axes.Count + $itemData.allItems.paxels.Count) items`n"
$summaryContent += "- Excavation: $($itemData.allItems.shovels.Count + $itemData.allItems.paxels.Count) items`n"
$summaryContent += "- Farming: $($itemData.allItems.hoes.Count + $itemData.allItems.shears.Count) items`n"
$summaryContent += "- Combat: $($itemData.allItems.weapons.Where({$_.name -notmatch "bow" -and $_.name -notmatch "arrow"}).Count) items`n"
$archeryItems = $itemData.allItems.weapons.Where({$_.name -match "bow" -or $_.name -match "arrow"}).Count
$summaryContent += "- Archery: $archeryItems items`n"
$summaryContent += "- Technology: $techCount items`n"
$summaryContent += "- Magic: $magicCount items`n"

# Save the summary report
$summaryContent | Out-File -FilePath $summaryFile -Encoding utf8

# Generate a CSV export of all items for Excel analysis
$csvFile = Join-Path -Path $outputFolder -ChildPath "AllItems.csv"
$csvData = @()

foreach ($type in $itemData.allItems.PSObject.Properties.Name) {
    foreach ($item in $itemData.allItems.$type) {
        $csvData += [PSCustomObject]@{
            Name = $item.name
            Mod = $item.mod
            Type = $type
            Tier = $item.tier
            IsTech = $item.isTech
            IsMagic = $item.isMagic
        }
    }
}

$csvData | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8

# Display completion message
Write-Host "`nItem Analysis Visualization Complete!" -ForegroundColor Green
Write-Host "Summary report created: $summaryFile" -ForegroundColor Yellow
Write-Host "CSV data export created: $csvFile" -ForegroundColor Yellow
Write-Host "`nTotal items analyzed: $totalItems" -ForegroundColor Cyan

# Show quick stats
Write-Host "`nQuick Stats:" -ForegroundColor Magenta
Write-Host "- Most common tier: $(($tierDistribution.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1).Key)" -ForegroundColor White
Write-Host "- Most items from: $(($top10Mods | Select-Object -First 1).Name)" -ForegroundColor White
Write-Host "- Tech vs Magic: $techCount vs $magicCount" -ForegroundColor White
