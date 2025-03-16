# Script to increase mining XP values for BLOCK_BREAK by multiplying by 3

# Root directory containing mod data
$rootPath = "D:\src\atm10_pmmo\atm10_pmmo\atm_10_pack\src\main\resources\data"

# Multiplier to apply to XP values
$multiplier = 3

# Stats tracking
$processedFiles = 0
$modifiedFiles = 0
$miningXpBefore = 0
$miningXpAfter = 0
$modStats = @{}

Write-Host "Starting mining XP enhancement script (multiplying by ${multiplier})..." -ForegroundColor Cyan

# Get all mod directories
$modDirs = Get-ChildItem -Path $rootPath -Directory

foreach ($mod in $modDirs) {
    $modName = $mod.Name
    $modMiningBefore = 0
    $modMiningAfter = 0
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
                    
                    # Process mining XP
                    if ($jsonContent.xp_values.BLOCK_BREAK.PSObject.Properties["mining"]) {
                        $currentValue = $jsonContent.xp_values.BLOCK_BREAK.mining
                        
                        # Skip if not a number
                        if ($currentValue -is [int] -or $currentValue -is [long] -or $currentValue -is [decimal] -or $currentValue -is [double]) {
                            $miningXpBefore += $currentValue
                            $modMiningBefore += $currentValue
                            
                            # Calculate new value (multiply by 3)
                            $newValue = $currentValue * $multiplier

                            if($newValue -lt 30)
                            {
                                $newValue = 30
                            }
                            
                            # Update the value in the JSON
                            $jsonContent.xp_values.BLOCK_BREAK.mining = $newValue
                            $modified = $true
                            
                            $miningXpAfter += $newValue
                            $modMiningAfter += $newValue
                            
                            Write-Host "  Updated mining in $($file.Name): $currentValue -> $newValue" -ForegroundColor Green
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
            MiningBefore = $modMiningBefore
            MiningAfter = $modMiningAfter
        }
    }
}

# Generate a summary report
Write-Host "`n=== Mining XP Enhancement Summary ===" -ForegroundColor Cyan
Write-Host "Files processed: $processedFiles" -ForegroundColor White
Write-Host "Files modified: $modifiedFiles" -ForegroundColor Green
Write-Host "Mining XP before: $miningXpBefore, after: $miningXpAfter" -ForegroundColor Yellow
Write-Host "Percentage increase: $([Math]::Round(($miningXpAfter / $miningXpBefore * 100) - 100, 2))%" -ForegroundColor Magenta

# Show stats by mod
Write-Host "`nModified files by mod:" -ForegroundColor Cyan
foreach ($mod in ($modStats.Keys | Sort-Object -Property { $modStats[$_].FilesModified } -Descending)) {
    $stats = $modStats[$mod]
    Write-Host "  $mod : $($stats.FilesModified) files" -ForegroundColor White
    Write-Host "    Mining XP: $($stats.MiningBefore) -> $($stats.MiningAfter)" -ForegroundColor White
}

Write-Host "`nProcessing complete!" -ForegroundColor Green