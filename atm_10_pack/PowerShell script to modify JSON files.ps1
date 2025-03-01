# PowerShell script to modify JSON files
$directoryPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data\railcraft\pmmo\items"

# Get all JSON files in the directory and subdirectories
$jsonFiles = Get-ChildItem -Path $directoryPath -Filter "*.json" -Recurse

# Base configuration values
$baseCraftExp = 10  # Base craft XP value
$craftExpPerLevel = 30  # Additional craft XP per level
$basePlaceExp = 0
$baseInteractExp = 0
$baseWearExp = 0
$baseUseExp = 0
$baseToolExp = 0  # Base tool requirement
$baseWeaponExp = 0  # Base weapon requirement
$expPerLevel = 40

# Define keyword-to-level mapping
$keywordLevels = @{
    # Tier 0 - Basic components (0 XP)
    "track" = 0           # Basic tracks
    "wooden" = 0          # Wooden components
    "iron" = 0            # Iron items (basic tier)
    "standard" = 0        # Standard rail items
    "tie" = 0             # Track ties
    
    # Tier 1 - Basic railways (40 XP)
    "switch" = 1          # Track switches
    "junction" = 1        # Track junctions
    "crossing" = 1        # Track crossings
    "detector" = 1        # Detector tracks
    "locomotive" = 1      # Basic locomotives
    "cart" = 1            # Basic carts
    "buffer" = 1          # Buffers
    
    # Tier 2 - Intermediate railway systems (80 XP) 
    "boiler" = 2          # Boilers
    "tank" = 2            # Tanks
    "firebox" = 2         # Fireboxes
    "steam" = 2           # Steam components
    "fluid" = 2           # Fluid handling
    "feed" = 2            # Feed stations
    "boarding" = 2        # Boarding tracks
    
    # Tier 3 - Advanced railways (120 XP)
    "electric" = 3        # Electric components
    "control" = 3         # Control systems
    "signal" = 3          # Signal blocks
    "locking" = 3         # Locking track
    "coupler" = 3         # Couplers
    "embarking" = 3       # Embarking tracks
    "disembarking" = 3    # Disembarking tracks
    "force" = 3           # Force tracks
    
    # Tier 4 - Advanced automation (160 XP)
    "routing" = 4         # Routing systems
    "loader" = 4          # Loaders/Unloaders
    "manipulator" = 4     # Cart manipulators
    "steel" = 4           # Steel components
    "advanced" = 4        # Advanced components
    "block" = 4           # Block signals
    "distant" = 4         # Distant signals
    
    # Tier 5 - End-game railcraft (200 XP)
    "high_speed" = 5      # High speed rails
    "reinforced" = 5      # Reinforced components
    "automated" = 5       # Automated systems
    "worldspike" = 5      # Worldspikes
    "tunnel" = 5          # Tunnel components
    "admin" = 5           # Admin components
    "powered" = 5         # Powered components
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
    $placeExp = $basePlaceExp + ($level * $expPerLevel)
    $interactExp = $baseInteractExp + ($level * $expPerLevel)
    $wearExp = $baseWearExp + ($level * $expPerLevel)
    $useExp = $baseUseExp + ($level * $expPerLevel)
    $toolExp = $baseToolExp + ($level * $expPerLevel)
    $weaponExp = $baseWeaponExp + ($level * $expPerLevel)
    $craftExp = $baseCraftExp + ($level * $craftExpPerLevel)
    
    if ($level -gt 0) {
        Write-Host "  Setting tech level $level (Place: $placeExp, Interact: $interactExp, Use: $useExp, Tool: $toolExp, Weapon: $weaponExp, Craft: $craftExp)" -ForegroundColor Magenta
    } else {
        Write-Host "  Using base requirements" -ForegroundColor Blue
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
    
    # Ensure all requirement categories exist
    $requirementNodes = @("TOOL", "WEAPON", "PLACE", "BREAK", "USE_ENCHANTMENT", "WEAR", "INTERACT", "USE")
    
    foreach ($node in $requirementNodes) {
        if (-not $jsonContent.requirements.PSObject.Properties[$node]) {
            $jsonContent.requirements | Add-Member -NotePropertyName $node -NotePropertyValue @{}
            $modified = $true
        }
    }
    
    # Set technology values for nodes that need them
    if ($placeExp -ne 0) {
        if (-not $jsonContent.requirements.PLACE.PSObject.Properties["technology"] -or 
            $jsonContent.requirements.PLACE.technology -ne $placeExp) {
            $jsonContent.requirements.PLACE | Add-Member -NotePropertyName "technology" -NotePropertyValue $placeExp -Force
            $modified = $true
        }
    }
    
    if ($interactExp -ne 0) {
        if (-not $jsonContent.requirements.INTERACT.PSObject.Properties["technology"] -or 
            $jsonContent.requirements.INTERACT.technology -ne $interactExp) {
            $jsonContent.requirements.INTERACT | Add-Member -NotePropertyName "technology" -NotePropertyValue $interactExp -Force
            $modified = $true
        }   
    }
    
    if ($wearExp -ne 0) {
        if (-not $jsonContent.requirements.WEAR.PSObject.Properties["technology"] -or 
            $jsonContent.requirements.WEAR.technology -ne $wearExp) {
            $jsonContent.requirements.WEAR | Add-Member -NotePropertyName "technology" -NotePropertyValue $wearExp -Force
            $modified = $true
        }   
    }
    
    if ($useExp -ne 0) {
        if (-not $jsonContent.requirements.USE.PSObject.Properties["technology"] -or 
            $jsonContent.requirements.USE.technology -ne $useExp) {
            $jsonContent.requirements.USE | Add-Member -NotePropertyName "technology" -NotePropertyValue $useExp -Force
            $modified = $true
        }   
    }
    
    # Add TOOL requirement logic
    if ($toolExp -ne 0) {
        if (-not $jsonContent.requirements.TOOL.PSObject.Properties["technology"] -or 
            $jsonContent.requirements.TOOL.technology -ne $toolExp) {
            $jsonContent.requirements.TOOL | Add-Member -NotePropertyName "technology" -NotePropertyValue $toolExp -Force
            $modified = $true
        }   
    }
    
    # Add WEAPON requirement logic
    if ($weaponExp -ne 0) {
        if (-not $jsonContent.requirements.WEAPON.PSObject.Properties["technology"] -or 
            $jsonContent.requirements.WEAPON.technology -ne $weaponExp) {
            $jsonContent.requirements.WEAPON | Add-Member -NotePropertyName "technology" -NotePropertyValue $weaponExp -Force
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