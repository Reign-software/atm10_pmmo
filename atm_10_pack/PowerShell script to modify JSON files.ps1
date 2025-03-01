# PowerShell script to modify JSON files
# Set the directory path to scan - change this to your target directory
$directoryPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data\powah\pmmo\items"

# Get all JSON files in the directory and subdirectories
$jsonFiles = Get-ChildItem -Path $directoryPath -Filter "*.json" -Recurse

# Set to 0 if you dont want anything to be set.
# Base configuration values
$baseCraftExp = 10  # Base craft XP value
$craftExpPerLevel = 30  # Additional craft XP per level
$basePlaceExp = 150
$baseInteractExp = 0
$expPerLevel = 50


# Define keyword-to-level mapping
$keywordLevels = @{
#    "starter" = 1    # Tier 1
#    "basic" = 2      # Tier 2
#    "hardened" = 3   # Tier 3
#    "blazing" = 4    # Tier 4 
#    "niotic" = 5     # Tier 5
#    "spirited" = 6   # Tier 6
#    "nitro" = 7      # Tier 7
}

foreach ($file in $jsonFiles) {
    Write-Host "Processing: $($file.FullName)"
    
    # Determine technology level based on filename
    $fileName = $file.BaseName.ToLower()
    $level = 0
    
    foreach ($keyword in $keywordLevels.Keys) {
        if ($fileName -match $keyword) {
            $keywordLevel = $keywordLevels[$keyword]
            Write-Host "  Found keyword '$keyword' (Level $keywordLevel) in $fileName" -ForegroundColor Cyan
            $level = [Math]::Max($level, $keywordLevel)
        }
    }
    
    # Calculate requirement values based on level
    # Always use at least base level, even when no keywords are found
    $placeExp = $basePlaceExp + ($level * $expPerLevel)
    $interactExp = $baseInteractExp + ($level * $expPerLevel)
    $craftExp = $baseCraftExp + ($level * $craftExpPerLevel)
    
    if ($level -gt 0) {
        Write-Host "  Setting technology level to $level (Craft: $craftExp, Place: $placeExp, Interact: $interactExp)" -ForegroundColor Magenta
    } else {
        Write-Host "  Using base requirements (Craft: $craftExp, Place: $placeExp, Interact: $interactExp)" -ForegroundColor Blue
    }
    
    # Read the JSON content
    $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
    
    $modified = $false
    
    # Check if xp_values exists
    if (-not $jsonContent.PSObject.Properties["xp_values"]) {
        $jsonContent | Add-Member -NotePropertyName "xp_values" -NotePropertyValue @{}
        $modified = $true
    }
    
    # Check if xp_values.CRAFT exists
    if (-not $jsonContent.xp_values.PSObject.Properties["CRAFT"]) {
        $jsonContent.xp_values | Add-Member -NotePropertyName "CRAFT" -NotePropertyValue @{}
        $modified = $true
    }
    
    # Add/set technology with scaled value in xp_values.CRAFT
    if (-not $jsonContent.xp_values.CRAFT.PSObject.Properties["technology"] -or 
        $jsonContent.xp_values.CRAFT.technology -ne $craftExp) {
        $jsonContent.xp_values.CRAFT | Add-Member -NotePropertyName "technology" -NotePropertyValue $craftExp -Force
        $modified = $true
    }
     
    # Check if requirements exists
    if (-not $jsonContent.PSObject.Properties["requirements"]) {
        $jsonContent | Add-Member -NotePropertyName "requirements" -NotePropertyValue @{}
        $modified = $true
    }
    
    if ($placeExp -ne 0) {

        # Check if requirements.PLACE exists
        if (-not $jsonContent.requirements.PSObject.Properties["PLACE"]) {
            $jsonContent.requirements | Add-Member -NotePropertyName "PLACE" -NotePropertyValue @{}
            $modified = $true
        }
        
        # Add/set technology in requirements.PLACE
        if (-not $jsonContent.requirements.PLACE.PSObject.Properties["technology"] -or 
            $jsonContent.requirements.PLACE.technology -ne $placeExp) {
            $jsonContent.requirements.PLACE | Add-Member -NotePropertyName "technology" -NotePropertyValue $placeExp -Force
            $modified = $true
        }
    }

    # Only apply interact exp if it's not zero
    if ($interactExp -ne 0) {
        # Check if requirements.INTERACT exists
        if (-not $jsonContent.requirements.PSObject.Properties["INTERACT"]) {
            $jsonContent.requirements | Add-Member -NotePropertyName "INTERACT" -NotePropertyValue @{}
            $modified = $true
        }
        
        # Add/set technology in requirements.INTERACT
        if (-not $jsonContent.requirements.INTERACT.PSObject.Properties["technology"] -or 
            $jsonContent.requirements.INTERACT.technology -ne $interactExp) {
            $jsonContent.requirements.INTERACT | Add-Member -NotePropertyName "technology" -NotePropertyValue $interactExp -Force
            $modified = $true
        }   
    }   
    
    # Save changes if any modifications were made
    if ($modified) {
        $jsonContent | ConvertTo-Json -Depth 20 | Set-Content -Path $file.FullName
        Write-Host "Updated: $($file.Name)" -ForegroundColor Green
    } else {
        Write-Host "No changes needed for: $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host "Processing complete!" -ForegroundColor Cyan