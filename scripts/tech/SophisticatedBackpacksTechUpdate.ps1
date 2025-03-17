# Script to configure Sophisticated Backpacks mod technology progression
$directoryPath = "c:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data\sophisticatedbackpacks\pmmo"
$logPath = "c:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\scripts\sophisticated_backpacks_tech_adjustments_log.txt"

# Start log file
"Sophisticated Backpacks Mod Technology Adjustments started at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath

# Get all JSON files for items
$jsonFiles = Get-ChildItem -Path "$directoryPath" -Filter "*.json" -Recurse -ErrorAction SilentlyContinue

Write-Host "Found $($jsonFiles.Count) total JSON files to process" -ForegroundColor Cyan
"Found $($jsonFiles.Count) total JSON files to process" | Out-File -FilePath $logPath -Append

# Initialize statistics
$stats = @{
    "filesModified" = 0
    "requirementsUpdated" = 0
    "requirementsRemoved" = 0
}

# Backpack tier definitions (0-15 scale)
$backpackTiers = @{
    # Base values for different backpack types
    "backpack" = 0             # Basic backpack - no requirement
    "iron_backpack" = 3        # Iron tier
    "gold_backpack" = 6        # Gold tier
    "diamond_backpack" = 10    # Diamond tier
    "netherite_backpack" = 15  # Netherite tier
    
    # Special variants
    "void_upgrade" = 10        # Void upgrade is advanced
    "stack_upgrade" = 8        # Stack upgrade
    "pickup_upgrade" = 5       # Pickup upgrade
    "advanced_" = 8            # Any advanced upgrades
    "magnet_upgrade" = 7       # Magnet upgrade
    "feeding_upgrade" = 6      # Feeding upgrade
    "compacting_upgrade" = 7   # Compacting upgrade
    "tool_swapper_upgrade" = 5 # Tool swapper
    "tank_upgrade" = 8         # Tank upgrade
    "battery_upgrade" = 8      # Battery upgrade
    "deposit_upgrade" = 6      # Deposit upgrade
    "restock_upgrade" = 6      # Restock upgrade
    "refill_upgrade" = 6       # Refill upgrade
    "inception_upgrade" = 12   # Inception (backpack in backpack) is near top tier
    "everlasting_upgrade" = 13 # Everlasting is very advanced
}

# Process each JSON file
Write-Host "Beginning processing of Sophisticated Backpacks mod files..." -ForegroundColor Cyan
"Beginning processing of Sophisticated Backpacks mod files..." | Out-File -FilePath $logPath -Append

foreach ($file in $jsonFiles) {
    $fileName = $file.BaseName
    
    # Determine the technology tier for this backpack/upgrade
    $techValue = 0  # Default to zero if not found
    foreach ($backpackType in $backpackTiers.Keys) {
        if ($fileName -match $backpackType) {
            $potentialValue = $backpackTiers[$backpackType]
            # Use the highest matching value if multiple matches
            if ($potentialValue -gt $techValue) {
                $techValue = $potentialValue
            }
        }
    }

    # Read the JSON content
    try {
        $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        $modified = $false
        
        # Process requirements if they exist
        if ($jsonContent.PSObject.Properties["requirements"]) {
            $requirementCategories = @("PLACE", "BREAK", "WEAR", "INTERACT", "USE")
            
            foreach ($category in $requirementCategories) {
                if ($jsonContent.requirements.PSObject.Properties[$category]) {
                    if ($jsonContent.requirements.$category.PSObject.Properties["technology"]) {
                        $originalValue = $jsonContent.requirements.$category.technology
                        
                        if ($techValue -eq 0) {
                            # Remove technology requirement if tier value is 0
                            $jsonContent.requirements.$category.PSObject.Properties.Remove("technology")
                            $stats.requirementsRemoved++
                            $modified = $true
                            $logMessage = "[$fileName] Removed technology requirement from $category (original: $originalValue)"
                        } else {
                            # Update to new hardcoded value
                            $jsonContent.requirements.$category.technology = $techValue
                            $stats.requirementsUpdated++
                            $modified = $true
                            $logMessage = "[$fileName] Updated $category technology requirement: $originalValue -> $techValue"
                        }
                        
                        $logMessage | Out-File -FilePath $logPath -Append
                        Write-Host "  $logMessage" -ForegroundColor Green
                        
                        # Remove the category if it's empty after removing technology
                        if ($jsonContent.requirements.$category.PSObject.Properties.Count -eq 0) {
                            $jsonContent.requirements.PSObject.Properties.Remove($category)
                        }
                    }
                }
            }
        }
        
        # Save changes if any modifications were made
        if ($modified) {
            $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $file.FullName -Encoding UTF8
            $stats.filesModified++
        }
    }
    catch {
        Write-Host "  Error processing $($file.FullName): $_" -ForegroundColor Red
        "Error processing $($file.FullName): $_" | Out-File -FilePath $logPath -Append
    }
}

# Write summary to log
"Sophisticated Backpacks Mod Technology Adjustments completed at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -FilePath $logPath -Append
"Statistics:" | Out-File -FilePath $logPath -Append
"  Total files modified: $($stats.filesModified)" | Out-File -FilePath $logPath -Append
"  Requirements updated: $($stats.requirementsUpdated)" | Out-File -FilePath $logPath -Append
"  Requirements removed (value 0): $($stats.requirementsRemoved)" | Out-File -FilePath $logPath -Append

# Output stats to console
Write-Host "`nSophisticated Backpacks Mod Technology Adjustments completed!" -ForegroundColor Green
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  Total files modified: $($stats.filesModified)" -ForegroundColor White
Write-Host "  Requirements updated: $($stats.requirementsUpdated)" -ForegroundColor White
Write-Host "  Requirements removed (value 0): $($stats.requirementsRemoved)" -ForegroundColor White
Write-Host "`nLog file saved to: $logPath" -ForegroundColor Yellow
