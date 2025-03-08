# Script to remove INTERACT requirements from storage containers
$dataPath = "d:\src\atm10_pmmo\atm_10_pack\src\main\resources\data\"
$logPath = "d:\src\atm10_pmmo\scripts\container_requirement_removal_log.txt"

# Initialize statistics
$stats = @{
    "containersProcessed" = 0
    "containersUpdated" = 0
    "requirementsRemoved" = 0
    "modsAffected" = @()
}

# Start log file
"Container INTERACT requirement removal started at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath
"Task: Remove all INTERACT requirements from storage containers (chests, crates, barrels, etc.)" | Out-File -FilePath $logPath -Append

# Define patterns for identifying storage containers
$containerPatterns = @(
    "*chest*", 
    "*crate*", 
    "*barrel*", 
    "*drawer*", 
    "*storage*", 
    "*container*",
    "*coffer*",
    "*box*",
    "*cache*",
    "*trunk*",
    "*safe*",
    "*locker*",
    "*vault*",
    "*stockpile*",
    "*shulker*"
)

# Get all mod directories
$modDirs = Get-ChildItem -Path $dataPath -Directory

foreach ($modDir in $modDirs) {
    $modName = $modDir.Name
    $modPmmoPath = Join-Path -Path $modDir.FullName -ChildPath "pmmo"
    $modUpdated = $false
    
    # Skip if no PMMO data
    if (-not (Test-Path $modPmmoPath)) {
        continue
    }
    
    # Process blocks
    $blocksPath = Join-Path -Path $modPmmoPath -ChildPath "blocks"
    if (Test-Path $blocksPath) {
        # Find container-like blocks using the patterns
        $containerFiles = @()
        
        foreach ($pattern in $containerPatterns) {
            $containerFiles += Get-ChildItem -Path $blocksPath -Filter $pattern
        }
        
        # Remove duplicates
        $containerFiles = $containerFiles | Sort-Object FullName -Unique
        
        Write-Host "Found $($containerFiles.Count) potential container blocks in $modName" -ForegroundColor Cyan
        
        foreach ($blockFile in $containerFiles) {
            $blockName = $blockFile.BaseName
            $stats.containersProcessed++
            
            # Load the JSON
            $blockJson = Get-Content -Path $blockFile.FullName -Raw | ConvertFrom-Json
            $modified = $false
            $requirementsRemoved = 0
            
            # Check if there are INTERACT requirements
            if ($blockJson.PSObject.Properties["requirements"] -and 
                $blockJson.requirements.PSObject.Properties["INTERACT"]) {
                
                # Count how many requirements will be removed
                $requirementsRemoved = ($blockJson.requirements.INTERACT.PSObject.Properties | Measure-Object).Count
                
                if ($requirementsRemoved -gt 0) {
                    # Replace with empty object
                    $blockJson.requirements.INTERACT = New-Object PSObject
                    $modified = $true
                    
                    Write-Host "  Removed $requirementsRemoved INTERACT requirements from $blockName" -ForegroundColor Yellow
                    "$blockName - Removed $requirementsRemoved INTERACT requirements" | Out-File -FilePath $logPath -Append
                    $stats.requirementsRemoved += $requirementsRemoved
                }
            }
            
            # Save changes if modified
            if ($modified) {
                $blockJson | ConvertTo-Json -Depth 10 | Set-Content -Path $blockFile.FullName -Encoding UTF8
                $stats.containersUpdated++
                $modUpdated = $true
                
                Write-Host "  Updated container: $blockName" -ForegroundColor Green
            }
        }
    }
    
    # Add mod to affected list if any updates occurred
    if ($modUpdated) {
        $stats.modsAffected += $modName
    }
}

# Get unique count of affected mods
$stats.modsAffected = ($stats.modsAffected | Select-Object -Unique).Count

# Write completion stats to log
"Container requirement removal completed at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath -Append
"Statistics:" | Out-File -FilePath $logPath -Append
"  Containers processed: $($stats.containersProcessed)" | Out-File -FilePath $logPath -Append
"  Containers updated: $($stats.containersUpdated)" | Out-File -FilePath $logPath -Append
"  Skill requirements removed: $($stats.requirementsRemoved)" | Out-File -FilePath $logPath -Append
"  Mods affected: $($stats.modsAffected)" | Out-File -FilePath $logPath -Append

# Output stats to console
Write-Host "`nContainer requirement removal completed!" -ForegroundColor Green
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  Containers processed: $($stats.containersProcessed)" -ForegroundColor White
Write-Host "  Containers updated: $($stats.containersUpdated)" -ForegroundColor White
Write-Host "  Skill requirements removed: $($stats.requirementsRemoved)" -ForegroundColor White
Write-Host "  Mods affected: $($stats.modsAffected)" -ForegroundColor White
Write-Host "`nLog file saved to: $logPath" -ForegroundColor Yellow