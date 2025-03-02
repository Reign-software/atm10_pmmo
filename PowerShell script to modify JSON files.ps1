# PowerShell script to modify JSON files
$directoryPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data\bigreactors\pmmo\items"

# Get all JSON files in the directory and subdirectories
$jsonFiles = Get-ChildItem -Path $directoryPath -Filter "*.json" -Recurse

# Base configuration values
$baseCraftExp = 100  # Base craft XP value
$craftExpPerLevel = 300  # Additional craft XP per level
$basePlaceExp = 300
$baseInteractExp = 0
$baseWearExp = 0
$baseUseExp = 0
$baseToolExp = 0  # Base tool requirement
$baseWeaponExp = 0  # Base weapon requirement
$expPerLevel = 40

# Define keyword-to-level mapping for Big Reactors/Extreme Reactors
$keywordLevels = @{
    # Tier 0 - Basic components (300 + 0 = 300 XP)
    "casing" = 0             # Reactor casing
    "glass" = 0              # Reactor glass
    "frame" = 0              # Basic frames
    "ingot" = 0              # Basic ingots
    "dust" = 0               # Reactor dust materials
    "graphite" = 0           # Graphite components
    "block_graphite" = 0     # Graphite blocks
    "basic" = 0              # Basic components
    
    # Tier 1 - Core reactor parts (300 + 40 = 340 XP)
    "reactor_casing" = 1     # Reactor casing
    "reactor_glass" = 1      # Reactor glass
    "reactor_controller" = 1 # Reactor controller
    "reactor_fuel_rod" = 1   # Fuel rods
    "reactor_control_rod" = 1 # Control rods
    "fuel" = 1               # Fuel components
    "yellorium" = 1          # Yellorium components
    "blutonium" = 1          # Blutonium components
    "access_port" = 1        # Access ports
    "moderator" = 1          # Moderator elements
    
    # Tier 2 - Turbine components (300 + 80 = 380 XP)
    "turbine_housing" = 2    # Turbine housing
    "turbine_glass" = 2      # Turbine glass
    "turbine_controller" = 2 # Turbine controller
    "turbine_bearing" = 2    # Turbine bearings
    "turbine_rotor" = 2      # Rotor components
    "turbine_blade" = 2      # Turbine blades
    "power_tap" = 2          # Power tap
    "coolant_port" = 2       # Coolant ports
    "rotor" = 2              # Rotor shaft
    
    # Tier 3 - Advanced reactor control (300 + 120 = 420 XP)
    "computer_port" = 3      # Computer interface
    "redstone_port" = 3      # Redstone port
    "reactor_redstone_port" = 3 # Reactor redstone port
    "turbine_redstone_port" = 3 # Turbine redstone port
    "controller" = 3         # Advanced controllers
    "creative_controller" = 3 # Creative controller
    "ludicrite" = 3          # Ludicrite components
    "fluid_port" = 3         # Fluid ports
    
    # Tier 4 - High-efficiency systems (300 + 160 = 460 XP)
    "multiblock" = 4         # Advanced multiblock structures
    "cyanite" = 4            # Cyanite components
    "extreme" = 4            # Extreme components
    "advanced" = 4           # Advanced systems
    "efficiency" = 4         # Efficiency upgrades
    "cyanite_reprocessor" = 4 # Cyanite reprocessor
    
    # Tier 5 - End-game reactor technology (300 + 200 = 500 XP)
    "creative" = 5           # Creative components
    "ultimate" = 5           # Ultimate components
    "reinforced" = 5         # Reinforced components
    "enderium" = 5           # Enderium enhancements
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