# Script to reduce excavation and woodcutting XP values for BLOCK_BREAK by dividing by 4

# Root directory containing mod data
$rootPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data"

# Divisor to apply to XP values
$divisor = 4
$minValue = 10 # Minimum value to ensure XP isn't reduced to 0

# Stats tracking
$processedFiles = 0
$modifiedFiles = 0
$excavationXpBefore = 0
$excavationXpAfter = 0
$woodcuttingXpBefore = 0
$woodcuttingXpAfter = 0
$modStats = @{}

Write-Host "Starting excavation and woodcutting XP reduction script (dividing by ${divisor})..." -ForegroundColor Cyan

# Get all mod directories
$modDirs = Get-ChildItem -Path $rootPath -Directory

foreach ($mod in $modDirs) {
    $modName = $mod.Name
    $modExcavationBefore = 0
    $modExcavationAfter = 0
    $modWoodcuttingBefore = 0
    $modWoodcuttingAfter = 0
    $modFilesModified = 0
    
    # Process both blocks and items directories
    foreach ($dirType in @("blocks", "items")) {
        $dirPath = Join-Path -Path $mod.FullName -ChildPath "pmmo\$dirType"
        
        # Skip if the directory doesn't exist
        if (-not (Test-Path $dirPath)) {
            continue
        }
        
        Write-Host "Processing $modName $dirType..." -ForegroundColor Yellow
        
        # Get all JSON files in the directory
        $files = Get-ChildItem -Path $dirPath -Filter "*.json" -Recurse
        
        foreach ($file in $files) {
            $processedFiles++
            
            try {
                # Read the JSON content
                $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                $modified = $false
                
                # Check if the file has xp_values.BLOCK_BREAK node
                if ($jsonContent.PSObject.Properties["xp_values"] -and 
                    $jsonContent.xp_values.PSObject.Properties["BLOCK_BREAK"]) {
                    
                    # Process excavation XP
                    if ($jsonContent.xp_values.BLOCK_BREAK.PSObject.Properties["excavation"]) {
                        $currentValue = $jsonContent.xp_values.BLOCK_BREAK.excavation
                        
                        # Skip if not a number
                        if ($currentValue -is [int] -or $currentValue -is [long] -or $currentValue -is [decimal] -or $currentValue -is [double]) {
                            $excavationXpBefore += $currentValue
                            $modExcavationBefore += $currentValue
                            
                            # Calculate new value (divide by 4 and round down, ensure minimum value)
                            $newValue = [Math]::Floor($currentValue / $divisor)
                            if ($newValue -lt $minValue) {
                                $newValue = $minValue
                            }
                            
                            # Update the value in the JSON
                            $jsonContent.xp_values.BLOCK_BREAK.excavation = $newValue
                            $modified = $true
                            
                            $excavationXpAfter += $newValue
                            $modExcavationAfter += $newValue
                            
                            Write-Host "  Updated excavation in $($file.Name): $currentValue -> $newValue" -ForegroundColor Green
                        }
                    }
                    
                    # Process woodcutting XP
                    if ($jsonContent.xp_values.BLOCK_BREAK.PSObject.Properties["woodcutting"]) {
                        $currentValue = $jsonContent.xp_values.BLOCK_BREAK.woodcutting
                        
                        # Skip if not a number
                        if ($currentValue -is [int] -or $currentValue -is [long] -or $currentValue -is [decimal] -or $currentValue -is [double]) {
                            $woodcuttingXpBefore += $currentValue
                            $modWoodcuttingBefore += $currentValue
                            
                            # Calculate new value (divide by 4 and round down, ensure minimum value)
                            $newValue = [Math]::Floor($currentValue / $divisor)
                            if ($newValue -lt $minValue) {
                                $newValue = $minValue
                            }
                            
                            # Update the value in the JSON
                            $jsonContent.xp_values.BLOCK_BREAK.woodcutting = $newValue
                            $modified = $true
                            
                            $woodcuttingXpAfter += $newValue
                            $modWoodcuttingAfter += $newValue
                            
                            Write-Host "  Updated woodcutting in $($file.Name): $currentValue -> $newValue" -ForegroundColor Green
                        }
                    }
                    
                    # Save changes if modified
                    if ($modified) {
                        $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $file.FullName -Encoding UTF8
                        $modifiedFiles++
                        $modFilesModified++
                    }
                }
            }
            catch {
                Write-Host "  Error processing $($file.Name): $_" -ForegroundColor Red
            }
        }
    }
    
    # Save mod stats if any files were modified
    if ($modFilesModified -gt 0) {
        $modStats[$modName] = @{
            FilesModified = $modFilesModified
            ExcavationBefore = $modExcavationBefore
            ExcavationAfter = $modExcavationAfter
            WoodcuttingBefore = $modWoodcuttingBefore
            WoodcuttingAfter = $modWoodcuttingAfter
        }
    }
}

# Calculate totals
$totalXpBefore = $excavationXpBefore + $woodcuttingXpBefore
$totalXpAfter = $excavationXpAfter + $woodcuttingXpAfter

# Generate a summary report
Write-Host "`n=== Excavation and Woodcutting XP Reduction Summary ===" -ForegroundColor Cyan
Write-Host "Files processed: $processedFiles" -ForegroundColor White
Write-Host "Files modified: $modifiedFiles" -ForegroundColor Green
Write-Host "Excavation XP before: $excavationXpBefore, after: $excavationXpAfter" -ForegroundColor Yellow
Write-Host "Woodcutting XP before: $woodcuttingXpBefore, after: $woodcuttingXpAfter" -ForegroundColor Yellow
Write-Host "Total XP before: $totalXpBefore, after: $totalXpAfter" -ForegroundColor Yellow
Write-Host "Percentage reduction: $([Math]::Round(100 - ($totalXpAfter / $totalXpBefore * 100), 2))%" -ForegroundColor Magenta

# Show stats by mod
Write-Host "`nModified files by mod:" -ForegroundColor Cyan
foreach ($mod in ($modStats.Keys | Sort-Object -Property { $modStats[$_].FilesModified } -Descending)) {
    $stats = $modStats[$mod]
    Write-Host "  $mod : $($stats.FilesModified) files" -ForegroundColor White
    Write-Host "    Excavation XP: $($stats.ExcavationBefore) -> $($stats.ExcavationAfter)" -ForegroundColor White
    Write-Host "    Woodcutting XP: $($stats.WoodcuttingBefore) -> $($stats.WoodcuttingAfter)" -ForegroundColor White
}

Write-Host "`nProcessing complete!" -ForegroundColor Green