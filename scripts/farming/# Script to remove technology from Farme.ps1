# Script to remove technology from Farmer's Delight and increase farming block break XP
$dataPath = "d:\src\atm10_pmmo\atm_10_pack\src\main\resources\data\"
$logPath = "d:\src\atm10_pmmo\scripts\farmers_delight_adjustments_log.txt"

# Initialize statistics
$stats = @{
    "techRemoved" = 0
    "farmingXpIncreased" = 0
    "totalFilesModified" = 0
}

# Start log file
"Farmer's Delight adjustments started at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath
"Tasks:" | Out-File -FilePath $logPath -Append
" - Remove all technology requirements and XP from Farmer's Delight" | Out-File -FilePath $logPath -Append
" - Multiply farming BLOCK_BREAK XP by 10x for all blocks with farming XP under 10" | Out-File -FilePath $logPath -Append

# Process Farmer's Delight items and blocks
$modName = "farmersdelight"
$modPmmoPath = Join-Path -Path $dataPath -ChildPath "$modName\pmmo"

# Check if the mod directory exists
if (-not (Test-Path $modPmmoPath)) {
    Write-Host "Farmer's Delight PMMO directory not found at: $modPmmoPath" -ForegroundColor Yellow
    "Farmer's Delight PMMO directory not found at: $modPmmoPath" | Out-File -FilePath $logPath -Append
} else {
    Write-Host "Processing Farmer's Delight..." -ForegroundColor Cyan
    "Processing Farmer's Delight..." | Out-File -FilePath $logPath -Append
    
    # Process blocks
    $blocksPath = Join-Path -Path $modPmmoPath -ChildPath "blocks"
    if (Test-Path $blocksPath) {
        $blockFiles = Get-ChildItem -Path $blocksPath -Filter "*.json"
        Write-Host "  Found $($blockFiles.Count) block files" -ForegroundColor White
        
        foreach ($blockFile in $blockFiles) {
            $blockName = $blockFile.BaseName
            $modified = $false
            $techRemoved = $false
            $farmingIncreased = $false
            
            # Load the JSON
            $blockJson = Get-Content -Path $blockFile.FullName -Raw | ConvertFrom-Json
            
            # Process requirements - remove technology
            if ($blockJson.PSObject.Properties["requirements"]) {
                foreach ($reqType in @("PLACE", "BREAK", "INTERACT", "USE")) {
                    if ($blockJson.requirements.PSObject.Properties[$reqType] -and 
                        $blockJson.requirements.$reqType.PSObject.Properties["technology"]) {
                        
                        $techValue = $blockJson.requirements.$reqType.technology
                        $blockJson.requirements.$reqType.PSObject.Properties.Remove("technology")
                        $modified = $true
                        $techRemoved = $true
                        
                        "$blockName - Removed $reqType technology requirement: $techValue" | Out-File -FilePath $logPath -Append
                    }
                }
            }
            
            # Process XP values - remove technology and multiply farming
            if ($blockJson.PSObject.Properties["xp_values"]) {
                # Remove technology from all XP sections
                foreach ($xpType in ($blockJson.xp_values.PSObject.Properties | Select-Object -ExpandProperty Name)) {
                    if ($blockJson.xp_values.$xpType.PSObject.Properties["technology"]) {
                        $techValue = $blockJson.xp_values.$xpType.technology
                        $blockJson.xp_values.$xpType.PSObject.Properties.Remove("technology")
                        $modified = $true
                        $techRemoved = $true
                        
                        "$blockName - Removed $xpType technology XP: $techValue" | Out-File -FilePath $logPath -Append
                    }
                }
                
                # Multiply farming BLOCK_BREAK XP by 10x if it exists AND is under 10
                if ($blockJson.xp_values.PSObject.Properties["BLOCK_BREAK"] -and 
                    $blockJson.xp_values.BLOCK_BREAK.PSObject.Properties["farming"]) {
                    
                    $oldValue = $blockJson.xp_values.BLOCK_BREAK.farming
                    
                    # Only multiply if value is less than 10
                    if ($oldValue -lt 10) {
                        $newValue = $oldValue * 10
                        
                        $blockJson.xp_values.BLOCK_BREAK | Add-Member -NotePropertyName "farming" -NotePropertyValue $newValue -Force
                        $modified = $true
                        $farmingIncreased = $true
                        
                        "$blockName - Increased farming BLOCK_BREAK XP from $oldValue to $newValue" | Out-File -FilePath $logPath -Append
                    }
                }
            }
            
            # Save changes if modified
            if ($modified) {
                $blockJson | ConvertTo-Json -Depth 10 | Set-Content -Path $blockFile.FullName -Encoding UTF8
                $stats.totalFilesModified++
                
                if ($techRemoved) { $stats.techRemoved++ }
                if ($farmingIncreased) { $stats.farmingXpIncreased++ }
                
                $statusMsg = ""
                if ($techRemoved) { $statusMsg += "tech removed, " }
                if ($farmingIncreased) { $statusMsg += "farming XP ×10, " }
                $statusMsg = $statusMsg.TrimEnd(", ")
                
                Write-Host "    Updated block: $blockName ($statusMsg)" -ForegroundColor Green
            }
        }
    }
    
    # Process items
    $itemsPath = Join-Path -Path $modPmmoPath -ChildPath "items"
    if (Test-Path $itemsPath) {
        $itemFiles = Get-ChildItem -Path $itemsPath -Filter "*.json"
        Write-Host "  Found $($itemFiles.Count) item files" -ForegroundColor White
        
        foreach ($itemFile in $itemFiles) {
            $itemName = $itemFile.BaseName
            $modified = $false
            $techRemoved = $false
            
            # Load the JSON
            $itemJson = Get-Content -Path $itemFile.FullName -Raw | ConvertFrom-Json
            
            # Process requirements - remove technology
            if ($itemJson.PSObject.Properties["requirements"]) {
                foreach ($reqType in @("PLACE", "BREAK", "INTERACT", "USE", "TOOL", "WEAPON", "WEAR")) {
                    if ($itemJson.requirements.PSObject.Properties[$reqType] -and 
                        $itemJson.requirements.$reqType.PSObject.Properties["technology"]) {
                        
                        $techValue = $itemJson.requirements.$reqType.technology
                        $itemJson.requirements.$reqType.PSObject.Properties.Remove("technology")
                        $modified = $true
                        $techRemoved = $true
                        
                        "$itemName - Removed $reqType technology requirement: $techValue" | Out-File -FilePath $logPath -Append
                    }
                }
            }
            
            # Process XP values - remove technology
            if ($itemJson.PSObject.Properties["xp_values"]) {
                foreach ($xpType in ($itemJson.xp_values.PSObject.Properties | Select-Object -ExpandProperty Name)) {
                    if ($itemJson.xp_values.$xpType.PSObject.Properties["technology"]) {
                        $techValue = $itemJson.xp_values.$xpType.technology
                        $itemJson.xp_values.$xpType.PSObject.Properties.Remove("technology")
                        $modified = $true
                        $techRemoved = $true
                        
                        "$itemName - Removed $xpType technology XP: $techValue" | Out-File -FilePath $logPath -Append
                    }
                }
            }
            
            # Save changes if modified
            if ($modified) {
                $itemJson | ConvertTo-Json -Depth 10 | Set-Content -Path $itemFile.FullName -Encoding UTF8
                $stats.totalFilesModified++
                
                if ($techRemoved) { $stats.techRemoved++ }
                
                Write-Host "    Updated item: $itemName (tech removed)" -ForegroundColor Green
            }
        }
    }
}

# Process ALL blocks to increase farming XP (even outside Farmer's Delight)
Write-Host "`nProcessing all mods for farming XP multiplication..." -ForegroundColor Cyan
"Processing all mods for farming XP multiplication..." | Out-File -FilePath $logPath -Append

$modDirs = Get-ChildItem -Path $dataPath -Directory

foreach ($modDir in $modDirs) {
    $currentModName = $modDir.Name
    $currentModPmmoPath = Join-Path -Path $modDir.FullName -ChildPath "pmmo"
    
    # Skip if no PMMO data
    if (-not (Test-Path $currentModPmmoPath)) {
        continue
    }
    
    # Process blocks
    $blocksPath = Join-Path -Path $currentModPmmoPath -ChildPath "blocks"
    if (Test-Path $blocksPath) {
        $blockFiles = Get-ChildItem -Path $blocksPath -Filter "*.json"
        
        foreach ($blockFile in $blockFiles) {
            $blockName = $blockFile.BaseName
            $modified = $false
            $farmingIncreased = $false
            
            # Skip if this is a Farmer's Delight block (already processed)
            if ($currentModName -eq "farmersdelight") {
                continue
            }
            
            # Load the JSON
            $blockJson = Get-Content -Path $blockFile.FullName -Raw | ConvertFrom-Json
            
            # Multiply farming BLOCK_BREAK XP by 10x if it exists AND is under 10
            if ($blockJson.PSObject.Properties["xp_values"] -and
                $blockJson.xp_values.PSObject.Properties["BLOCK_BREAK"] -and 
                $blockJson.xp_values.BLOCK_BREAK.PSObject.Properties["farming"]) {
                
                $oldValue = $blockJson.xp_values.BLOCK_BREAK.farming
                
                # Only multiply if value is less than 10
                if ($oldValue -lt 10) {
                    $newValue = $oldValue * 10
                    
                    $blockJson.xp_values.BLOCK_BREAK | Add-Member -NotePropertyName "farming" -NotePropertyValue $newValue -Force
                    $modified = $true
                    $farmingIncreased = $true
                    
                    "$currentModName : $blockName - Increased farming BLOCK_BREAK XP from $oldValue to $newValue" | Out-File -FilePath $logPath -Append
                }
            }
            
            # Save changes if modified
            if ($modified) {
                $blockJson | ConvertTo-Json -Depth 10 | Set-Content -Path $blockFile.FullName -Encoding UTF8
                $stats.totalFilesModified++
                
                if ($farmingIncreased) { $stats.farmingXpIncreased++ }
                
                Write-Host "    Updated block: $currentModName : $blockName (farming XP ×10)" -ForegroundColor Green
            }
        }
    }
}

# Write completion stats to log
"Adjustments completed at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath -Append
"Statistics:" | Out-File -FilePath $logPath -Append
"  Files with technology removed: $($stats.techRemoved)" | Out-File -FilePath $logPath -Append
"  Files with farming XP increased: $($stats.farmingXpIncreased)" | Out-File -FilePath $logPath -Append
"  Total files modified: $($stats.totalFilesModified)" | Out-File -FilePath $logPath -Append

# Output stats to console
Write-Host "`nAdjustments completed!" -ForegroundColor Green
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  Files with technology removed: $($stats.techRemoved)" -ForegroundColor White
Write-Host "  Files with farming XP increased: $($stats.farmingXpIncreased)" -ForegroundColor White
Write-Host "  Total files modified: $($stats.totalFilesModified)" -ForegroundColor White
Write-Host "`nLog file saved to: $logPath" -ForegroundColor Yellow