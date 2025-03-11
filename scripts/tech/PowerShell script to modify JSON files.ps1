# Script to configure AE2 mod technology progression
$directoryPath = "c:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data\ae2\pmmo"
$logPath = "c:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\scripts\ae2_tech_adjustments_log.txt"

# Start log file
"AE2 Mod Technology Adjustments started at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath

# Get all JSON files for items and blocks
$itemFiles = Get-ChildItem -Path "$directoryPath\items" -Filter "*.json" -Recurse -ErrorAction SilentlyContinue
$blockFiles = Get-ChildItem -Path "$directoryPath\blocks" -Filter "*.json" -Recurse -ErrorAction SilentlyContinue
$jsonFiles = $itemFiles + $blockFiles

Write-Host "Found $($jsonFiles.Count) total JSON files to process" -ForegroundColor Cyan
"Found $($jsonFiles.Count) total JSON files to process" | Out-File -FilePath $logPath -Append

# Initialize statistics
$stats = @{
    "filesModified" = 0
    "standardItems" = 0
    "advancedItems" = 0
    "endgameItems" = 0
}

# Base configuration values
$baseRequirement = 200  # Base technology requirement (most items)
$advancedRequirement = 250  # Advanced items
$endgameRequirement = 400  # End-game items

# Base XP values
$baseCraftExp = 800  # Base craft XP value
$advancedCraftExp = 1200  # Advanced items craft XP
$endgameCraftExp = 2000  # End-game items craft XP

# Define AE2 keyword-to-level mapping
$keywordLevels = @{
    # Standard items (Level 1 - 200 requirement)
    "guide" = 1
    "certus" = 1
    "quartz" = 1
    "press" = 1
    "cable" = 1
    "glass" = 1
    "fluix" = 1
    "sky_stone" = 1
    "interface" = 1
    "terminal" = 1
    "formation" = 1
    "annihilation" = 1
    "energy" = 1
    "cell" = 1
    "storage" = 1
    "crafting" = 1
    "inscriber" = 1
    "pattern" = 1
    "processor" = 1
    "printed" = 1
    "silicon" = 1
    "charger" = 1
    "chest" = 1
    "monitor" = 1
    
    # Advanced items (Level 2 - 300 requirement)
    "me_controller" = 1
    "controller" = 1
    "drive" = 1
    "network" = 1
    "64k" = 2
    "accelerator" = 2
    "p2p" = 2
    "molecular" = 1
    "assembler" = 1
    "auto_crafting" = 1
    "level_emitter" = 1
    "export_bus" = 1
    "import_bus" = 1
    "storage_bus" = 1
    
    # End-game items (Level 3 - 400 requirement)
    "wireless" = 3
    "quantum" = 3
    "spatial" = 3
    "256k" = 3
    "1m" = 3
    "4m" = 3
    "16m" = 3
    "security" = 3
    "creative" = 3
}

# Process each JSON file
Write-Host "Beginning processing of AE2 mod files..." -ForegroundColor Cyan
"Beginning processing of AE2 mod files..." | Out-File -FilePath $logPath -Append

foreach ($file in $jsonFiles) {
    $fileName = $file.BaseName.ToLower()
    
    # Determine technology level based on filename
    $level = 1  # Default to standard level (200 requirement)
    $matchedKeyword = ""
    
    foreach ($keyword in $keywordLevels.Keys) {
        if ($fileName -match $keyword) {
            $keywordLevel = $keywordLevels[$keyword]
            if ($keywordLevel -gt $level) {
                $level = $keywordLevel
                $matchedKeyword = $keyword
            }
        }
    }
    
    # Determine tech requirement and XP based on level
    switch ($level) {
        1 { 
            $techRequirement = $baseRequirement 
            $craftExp = $baseCraftExp
            $stats.standardItems++
        }
        2 { 
            $techRequirement = $advancedRequirement
            $craftExp = $advancedCraftExp
            $stats.advancedItems++
        }
        3 { 
            $techRequirement = $endgameRequirement 
            $craftExp = $endgameCraftExp
            $stats.endgameItems++
        }
    }
    
    # Read the JSON content
    try {
        $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        $modified = $false
        
        # Check if requirements exists
        if (-not $jsonContent.PSObject.Properties["requirements"]) {
            $jsonContent | Add-Member -NotePropertyName "requirements" -NotePropertyValue @{}
            $modified = $true
        }
        
        # Ensure all requirement categories exist
        $requirementNodes = @("USE", "PLACE", "INTERACT", "BREAK")
        
        foreach ($node in $requirementNodes) {
            if (-not $jsonContent.requirements.PSObject.Properties[$node]) {
                $jsonContent.requirements | Add-Member -NotePropertyName $node -NotePropertyValue @{}
                $modified = $true
            }
        }
        
        # Set technology requirements based on item type
        if ($file.FullName -match "\\items\\") {
            # For items, set USE requirement
            $jsonContent.requirements.USE | Add-Member -NotePropertyName "technology" -NotePropertyValue $techRequirement -Force
            $jsonContent.requirements.PLACE | Add-Member -NotePropertyName "technology" -NotePropertyValue $techRequirement -Force
            $jsonContent.requirements.INTERACT | Add-Member -NotePropertyName "technology" -NotePropertyValue $techRequirement -Force
            $modified = $true
        }
        
        if ($file.FullName -match "\\blocks\\") {
            # For blocks, set PLACE and INTERACT requirements
            $jsonContent.requirements.PLACE | Add-Member -NotePropertyName "technology" -NotePropertyValue $techRequirement -Force
            $jsonContent.requirements.INTERACT | Add-Member -NotePropertyName "technology" -NotePropertyValue $techRequirement -Force
            $jsonContent.requirements.BREAK | Add-Member -NotePropertyName "technology" -NotePropertyValue $techRequirement -Force
            $modified = $true
        }
        
        # Add XP values for crafting
        if (-not $jsonContent.PSObject.Properties["xp_values"]) {
            $jsonContent | Add-Member -NotePropertyName "xp_values" -NotePropertyValue @{} -Force
            $modified = $true
        }
        
        if (-not $jsonContent.xp_values.PSObject.Properties["CRAFT"]) {
            $jsonContent.xp_values | Add-Member -NotePropertyName "CRAFT" -NotePropertyValue @{} -Force
            $modified = $true
        }
        
        # Set technology XP for crafting
        $jsonContent.xp_values.CRAFT = @{ "technology" = $craftExp }
        $modified = $true
        
        # Save changes if any modifications were made
        if ($modified) {
            $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $file.FullName -Encoding UTF8
            $stats.filesModified++
            
            $levelName = switch ($level) {
                1 { "Standard" }
                2 { "Advanced" }
                3 { "End-game" }
            }
            
            $logMessage = "[$levelName] $fileName - Set tech level to $techRequirement (craft XP: $craftExp)"
            $logMessage | Out-File -FilePath $logPath -Append
            
            Write-Host "  Updated: $fileName ($levelName, Tech: $techRequirement)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  Error processing $($file.FullName): $_" -ForegroundColor Red
        "Error processing $($file.FullName): $_" | Out-File -FilePath $logPath -Append
    }
}

# Write summary to log
"AE2 Mod Technology Adjustments completed at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath -Append
"Statistics:" | Out-File -FilePath $logPath -Append
"  Total files modified: $($stats.filesModified)" | Out-File -FilePath $logPath -Append
"  Standard items (Tech 200): $($stats.standardItems)" | Out-File -FilePath $logPath -Append
"  Advanced items (Tech 300): $($stats.advancedItems)" | Out-File -FilePath $logPath -Append
"  End-game items (Tech 400): $($stats.endgameItems)" | Out-File -FilePath $logPath -Append

# Output stats to console
Write-Host "`nAE2 Mod Technology Adjustments completed!" -ForegroundColor Green
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  Total files modified: $($stats.filesModified)" -ForegroundColor White
Write-Host "  Standard items (Tech 200): $($stats.standardItems)" -ForegroundColor White
Write-Host "  Advanced items (Tech 300): $($stats.advancedItems)" -ForegroundColor White
Write-Host "  End-game items (Tech 400): $($stats.endgameItems)" -ForegroundColor White
Write-Host "`nLog file saved to: $logPath" -ForegroundColor Yellow