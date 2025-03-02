# Script to multiply technology XP values for crafting by 20x

# Root directory containing mod data
$rootPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data"

# Multiplier to apply to technology XP values
$multiplier = 40
$minValue = 400

# Stats tracking
$processedFiles = 0
$modifiedFiles = 0
$totalXpBefore = 0
$totalXpAfter = 0
$modStats = @{}

Write-Host "Starting technology XP multiplier script (${multiplier}x)..." -ForegroundColor Cyan

# Get all mod directories
$modDirs = Get-ChildItem -Path $rootPath -Directory

foreach ($mod in $modDirs) {
    $modName = $mod.Name
    $itemsPath = Join-Path -Path $mod.FullName -ChildPath "pmmo\items"
    $modXpBefore = 0
    $modXpAfter = 0
    $modFilesModified = 0
    
    # Skip if the mod doesn't have an items directory
    if (-not (Test-Path $itemsPath)) {
        continue
    }
    
    Write-Host "Processing $modName items..." -ForegroundColor Yellow
    
    # Get all JSON files in the items directory
    $itemFiles = Get-ChildItem -Path $itemsPath -Filter "*.json" -Recurse
    
    foreach ($file in $itemFiles) {
        $processedFiles++
        
        try {
            # Read the JSON content
            $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $modified = $false
            
            # Check if the file has xp_values.CRAFT.technology node
            if ($jsonContent.PSObject.Properties["xp_values"] -and 
                $jsonContent.xp_values.PSObject.Properties["CRAFT"] -and 
                $jsonContent.xp_values.CRAFT.PSObject.Properties["technology"]) {
                
                # Get the current value
                $currentValue = $jsonContent.xp_values.CRAFT.technology
                
                # Skip if not a number
                if ($currentValue -is [int] -or $currentValue -is [long] -or $currentValue -is [decimal] -or $currentValue -is [double]) {
                    $totalXpBefore += $currentValue
                    $modXpBefore += $currentValue
                    
                    # Calculate new value
                    $newValue = $currentValue * $multiplier
                    
                    if ($newValue -lt $minValue)
                    {
                        $newValue = $minValue
                    }

                    # Update the value in the JSON
                    $jsonContent.xp_values.CRAFT.technology = $newValue
                    $modified = $true
                    
                    $totalXpAfter += $newValue
                    $modXpAfter += $newValue
                    
                    Write-Host "  Updated $($file.Name): $currentValue -> $newValue" -ForegroundColor Green
                }
            }
            
            # Save changes if modified
            if ($modified) {
                $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $file.FullName -Encoding UTF8
                $modifiedFiles++
                $modFilesModified++
            }
        }
        catch {
            Write-Host "  Error processing $($file.Name): $_" -ForegroundColor Red
        }
    }
    
    # Save mod stats if any files were modified
    if ($modFilesModified -gt 0) {
        $modStats[$modName] = @{
            FilesModified = $modFilesModified
            XpBefore = $modXpBefore
            XpAfter = $modXpAfter
        }
    }
}

# Generate a summary report
Write-Host "`n=== Technology XP Multiplier Summary ===" -ForegroundColor Cyan
Write-Host "Files processed: $processedFiles" -ForegroundColor White
Write-Host "Files modified: $modifiedFiles" -ForegroundColor Green
Write-Host "Total tech XP before: $totalXpBefore" -ForegroundColor Yellow
Write-Host "Total tech XP after: $totalXpAfter" -ForegroundColor Yellow
Write-Host "Percentage increase: $(($totalXpAfter / $totalXpBefore * 100) - 100)%" -ForegroundColor Magenta

# Show stats by mod
Write-Host "`nModified files by mod:" -ForegroundColor Cyan
foreach ($mod in ($modStats.Keys | Sort-Object -Property { $modStats[$_].FilesModified } -Descending)) {
    $stats = $modStats[$mod]
    Write-Host "  $mod : $($stats.FilesModified) files, XP $($stats.XpBefore) -> $($stats.XpAfter)" -ForegroundColor White
}

Write-Host "`nProcessing complete!" -ForegroundColor Green
