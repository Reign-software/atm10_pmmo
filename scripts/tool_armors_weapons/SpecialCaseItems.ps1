# Script for handling special case items with custom requirements

# Define items that need special handling - these override normal detection
$specialCaseItems = @{
    # Mekanism special tools
    "atomic_disassembler" = @{
        Type = "multi-tool"
        Tier = 6
        Skills = @{
            "mining" = 300
            "woodcutting" = 300
            "excavation" = 300
            "farming" = 300
            "smithing" = 300
            "technology" = 350
        }
        Requirements = @("TOOL", "USE")
    }
    
    # Special tech armor
    "mekasuit" = @{
        Type = "tech-armor"
        Tier = 8
        Skills = @{
            "endurance" = 400
            "technology" = 450
            "smithing" = 400
        }
        Requirements = @("WEAR", "USE")
    }
    
    # Special magic weapons
    "spell_book" = @{
        Type = "magic-weapon"
        Tier = 5
        Skills = @{
            "combat" = 250
            "magic" = 300
        }
        Requirements = @("WEAPON", "USE")
    }
    
    # Special tools with dual functionality
    "cleaver" = @{
        Type = "dual-tool"
        Tier = 3
        Skills = @{
            "combat" = 150
            "woodcutting" = 150
            "smithing" = 150
        }
        Requirements = @("TOOL", "WEAPON", "USE")
    }
    
    # Special food/potion items
    "golden_apple" = @{
        Type = "special-food"
        Tier = 3
        Skills = @{
            "endurance" = 100
            "magic" = 75
        }
        Requirements = @("USE", "CONSUME")
    }
}

# Function to check if an item is a special case and get its data
function Get-SpecialCaseItem {
    param([string]$itemName)
    
    foreach ($specialItem in $specialCaseItems.Keys) {
        if ($itemName -match $specialItem) {
            return @{
                IsSpecialCase = $true
                Data = $specialCaseItems[$specialItem]
            }
        }
    }
    
    return @{
        IsSpecialCase = $false
        Data = $null
    }
}
