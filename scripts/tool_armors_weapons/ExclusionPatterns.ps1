# Script containing exclusion patterns for item requirement assignment

# Items that contain tool keywords but aren't tools
$toolExclusions = @(
    # Food items that might match tool patterns
    "pickle", "beetroot", "sweet", "sandwich", "food",
    "soup", "stew", "meal", "dish", "recipe",
    
    # Components/crafting ingredients that might match tool patterns
    "component", "part", "head", "handle", "blueprint",
    "template", "schematic", "pattern", "mold",
    
    # Decoration/furniture items that might match tool patterns
    "decoration", "display", "showcase", "stand", "rack",
    "holder", "pedestal", "model", "dummy", "ornament"
)

# Items that match armor patterns but aren't armor
$armorExclusions = @(
    # Parts and components
    "armor_part", "armor_plate", "armor_trim", 
    "armor_stand", "armor_station", "armor_frame",

    # Decorative/display items
    "display", "showcase", "dummy", "mannequin",
    
    # Processing/crafting items
    "armor_forge", "armor_table", "armor_anvil"
)

# Items that might be falsely identified as weapons
$weaponExclusions = @(
    # Tools/components with weapon keywords
    "tool_axe", "lumber_axe", "tree_axe", "felling_axe",
    "sword_blueprint", "sword_mold", "sword_handle",
    
    # Food/decoration items
    "knife_set", "kitchen_knife", "butter_knife",
    "display_sword", "ornamental", "decorative"
)

# Items that should never have requirements regardless of name matches
$globalExclusions = @(
    # Pure cosmetic items
    "cosmetic", "skin", "trophy", "souvenir", "collectible",
    
    # UI/interface items
    "gui", "interface", "menu", "button", "screen",
    
    # Creative mode items
    "creative_only", "debug", "test"
)

# Helper functions to check exclusions
function Test-ExcludedTool {
    param([string]$itemName)
    
    foreach ($pattern in $toolExclusions) {
        if ($itemName -match $pattern) {
            return $true
        }
    }
    
    return $false
}

function Test-ExcludedArmor {
    param([string]$itemName)
    
    foreach ($pattern in $armorExclusions) {
        if ($itemName -match $pattern) {
            return $true
        }
    }
    
    return $false
}

function Test-ExcludedWeapon {
    param([string]$itemName)
    
    foreach ($pattern in $weaponExclusions) {
        if ($itemName -match $pattern) {
            return $true
        }
    }
    
    return $false
}

function Test-GloballyExcluded {
    param([string]$itemName)
    
    foreach ($pattern in $globalExclusions) {
        if ($itemName -match $pattern) {
            return $true
        }
    }
    
    return $false
}
