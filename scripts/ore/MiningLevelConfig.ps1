# Mining level configuration for PMMO
# This file documents the mining level requirements for different ore tiers

$MiningTiers = @(
    [PSCustomObject]@{
        Tier = 0
        Name = "Stone and Common Materials"
        Level = 0
        XP = 10
        Description = "Basic blocks like stone, dirt, gravel"
        Examples = "stone, gravel, dirt, sand"
    },
    [PSCustomObject]@{
        Tier = 1
        Name = "Basic Ores"
        Level = 50
        XP = 15
        Description = "First mining progression ores"
        Examples = "coal_ore, iron_ore, copper_ore, tin_ore"
    },
    [PSCustomObject]@{
        Tier = 2
        Name = "Intermediate Ores"
        Level = 100
        XP = 20
        Description = "Secondary overworld resources"
        Examples = "gold_ore, redstone_ore, lead_ore"
    },
    [PSCustomObject]@{
        Tier = 3
        Name = "Advanced Overworld Ores"
        Level = 150
        XP = 30
        Description = "Later-game overworld materials"
        Examples = "lapis_ore, aluminum_ore, silver_ore, nickel_ore"
    },
    [PSCustomObject]@{
        Tier = 4
        Name = "Nether Resources"
        Level = 200
        XP = 40
        Description = "Basic Nether ores and resources"
        Examples = "nether_gold_ore, nether_quartz_ore, glowstone"
    },
    [PSCustomObject]@{
        Tier = 5
        Name = "Precious Materials"
        Level = 250
        XP = 60
        Description = "Rare and valuable gems"
        Examples = "diamond_ore, emerald_ore, sapphire_ore, ruby_ore"
    },
    [PSCustomObject]@{
        Tier = 6
        Name = "Industrial Resources" 
        Level = 300
        XP = 80
        Description = "Advanced industrial materials"
        Examples = "uranium_ore, platinum_ore, osmium_ore, iridium_ore"
    },
    [PSCustomObject]@{
        Tier = 7
        Name = "Exotic Materials"
        Level = 350
        XP = 100
        Description = "Exotic and mysterious ores"
        Examples = "ancient_debris, crimson_iron, azure_silver, cobalt_ore"
    },
    [PSCustomObject]@{
        Tier = 8
        Name = "End and Dimensional Resources"
        Level = 400
        XP = 120
        Description = "End dimension and rare dimensional resources"
        Examples = "end_stone, draconium_ore, allthemodium_ore, yellorite_ore"
    },
    [PSCustomObject]@{
        Tier = 9
        Name = "Rare Dimensional Materials"
        Level = 450
        XP = 150
        Description = "Very rare end and dimensional ores"
        Examples = "vibranium_ore, resonant_end_stone, benitoite"
    },
    [PSCustomObject]@{
        Tier = 10
        Name = "Mythical Materials"
        Level = 500
        XP = 200
        Description = "Endgame and creative-tier resources"
        Examples = "unobtainium_ore, infinity_ore, awakened_draconium_ore, nether_star_ore"
    }
)

# Display the mining tier information
Write-Host "Mining Level Requirements Overview:" -ForegroundColor Cyan
foreach ($tier in $MiningTiers) {
    Write-Host "`nTier $($tier.Tier): $($tier.Name)" -ForegroundColor Yellow
    Write-Host "  Required Level: $($tier.Level)" -ForegroundColor Green
    Write-Host "  XP Reward: $($tier.XP) per block" -ForegroundColor Magenta
    Write-Host "  Description: $($tier.Description)" -ForegroundColor White
    Write-Host "  Examples: $($tier.Examples)" -ForegroundColor Gray
}

# This function can be used to get level requirement for a specific tier
function Get-MiningLevelForTier {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Tier
    )
    
    if ($Tier -ge 0 -and $Tier -le 10) {
        return $MiningTiers[$Tier].Level
    } else {
        throw "Invalid tier: $Tier. Must be between 0 and 10."
    }
}

# This function can be used to get XP reward for a specific tier
function Get-MiningXPForTier {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Tier
    )
    
    if ($Tier -ge 0 -and $Tier -le 10) {
        return $MiningTiers[$Tier].XP
    } else {
        throw "Invalid tier: $Tier. Must be between 0 and 10."
    }
}

Write-Host "`nThis configuration file can be sourced in other scripts to ensure consistent mining tier values." -ForegroundColor Cyan
