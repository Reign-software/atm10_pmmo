$skillLevels = @{
    0 = 0
    1 = 38
    2 = 77
    3 = 115
    4 = 154
    5 = 192
    6 = 231
    7 = 269
    8 = 308
    9 = 346
    10 = 385
    11 = 423
    12 = 462
    13 = 500
}

$skills = @(
    "magic", "fishing", "combat", "alchemy", "mining", "endurance",
    "building", "smithing", "swimming", "woodcutting", "crafting",
    "excavation", "farming", "cooking", "agility", "archery"
)

$enchantSkillMap = @{
    "sanctified" = 2
    "respiration" = 8
    "wind_burst" = 0
    "purification" = 0
    "aqua_affinity" = 8
    "magic_siphon" = 0
    "curse_of_bones" = 5
    "chromatic" = 12
    "mana_regen" = 0
    "binding_curse" = -1
    "flame" = 15
    "incurable_wounds" = 15
    "mana_boost" = 0
    "mirror_shield" = 2
    "channeling" = 0
    "sculk_smite" = 2
    "lure" = 1
    "soul_speed" = 14
    "silk_touch" = -1
    "infusion" = -1
    "chainsaw" = 9
    "catalysis" = -1
    "blast_protection" = -1
    "power" = -1
    "depth_strider" = -1
    "piercing" = -1
    "soulbound" = -1
    "fire_react" = -1
    "chill_aura" = -1
    "fire_protection" = -1
    "thorns" = -1
    "quick_charge" = -1
    "berserkers_fury" = -1
    "soul_looting" = -1
    "neurotoxins" = -1
    "punch" = -1
    "poisoning" = -1
    "spectral_bite" = -1
    "infinity" = -1
    "fearless" = -1
    "feather_falling" = -1
    "poison_tip" = -1
    "projectile_protection" = -1
    "impaling" = -1
    "luck_of_the_sea" = -1
    "protection" = -1
    "vengeance" = -1
    "quarry_pickaxe" = -1
    "severing" = -1
    "crescendo_of_bolts" = 15
    "knowledge_of_the_ages" = -1
    "unusing" = -1
    "smite" = -1
    "comb_cutter" = -1
    "ruthless_strike" = -1
    "frost_walker" = -1
    "voltaic_shot" = -1
    "life_mending" = -1
    "riptide" = -1
    "raider_damage_enchant" = -1
    "breach" = -1
    "backstabbing" = -1
    "decrepitude" = -1
    "bane_of_arthropods" = -1
    "sharpness" = 2
    "density" = -1
    "mending" = -1
    "soul_siphoner" = -1
    "implosion" = -1
    "growth_serum" = -1
    "ensnaring" = -1
    "smack" = -1
    "icy_thorns" = -1
    "wrecking" = -1
    "efficiency" = -1
    "natures_blessing" = -1
    "reactive" = -1
    "life_stealing" = -1
    "capturing" = -1
    "endless_quiver" = -1
    "ricochet" = -1
    "blessing" = -1
    "scavenger" = -1
    "shield_bash" = -1
    "lolths_curse" = -1
    "frostbite" = -1
    "boon_of_the_earth" = 4
    "soul_snatcher" = -1
    "reflective_defenses" = -1
    "self_sling" = -1
    "mystical_enlightenment" = -1
    "spectral_conjurer" = -1
    "miners_fervor" = -1
    "rebounding" = -1
    "multishot" = -1
    "worker_exploitation" = -1
    "tempting" = -1
    "swift_sneak" = -1
    "fire_aspect" = -1
    "unbreaking" = 7
    "fortune" = 0
    "longevity" = -1
    "renewal" = -1
    "plague_bringer" = -1
    "destruction" = -1
    "stasis" = -1
    "breaking" = -1
    "sweeping_edge" = -1
    "vanishing_curse" = -1
    "loyalty" = -1
    "stable_footing" = -1
    "potent_poison" = -1
    "looting" = -1
    "knockback" = -1
    "discharge" = -1
}

$enchantTierMap = @{
    "sanctified" = 12
    "respiration" = 7
    "wind_burst" = 8
    "purification" = 4
    "aqua_affinity" = 1
    "magic_siphon" = 13
    "curse_of_bones" = 13
    "chromatic" = 1
    "mana_regen" = 7
    "binding_curse" = 1
    "flame" = 1
    "incurable_wounds" = 13
    "mana_boost" = 7
    "mirror_shield" = 7
    "channeling" = 1
    "sculk_smite" = 10
    "lure" = 8
    "soul_speed" = 7
    "silk_touch" = 1
    "infusion" = 1
    "chainsaw" = 1
    "catalysis" = 1
    "blast_protection" = 1
    "power" = 1
    "depth_strider" = 1
    "piercing" = 1
    "soulbound" = 1
    "fire_react" = 1
    "chill_aura" = 1
    "fire_protection" = 1
    "thorns" = 1
    "quick_charge" = 1
    "berserkers_fury" = 2
    "soul_looting" = 1
    "neurotoxins" = 1
    "punch" = 1
    "poisoning" = 1
    "spectral_bite" = 1
    "infinity" = 1
    "fearless" = 1
    "feather_falling" = 1
    "poison_tip" = 1
    "projectile_protection" = 1
    "impaling" = 1
    "luck_of_the_sea" = 1
    "protection" = 1
    "vengeance" = 1
    "quarry_pickaxe" = 1
    "severing" = 1
    "crescendo_of_bolts" = 5
    "knowledge_of_the_ages" = 1
    "unusing" = 1
    "smite" = 1
    "comb_cutter" = 1
    "ruthless_strike" = 1
    "frost_walker" = 1
    "voltaic_shot" = 1
    "life_mending" = 1
    "riptide" = 1
    "raider_damage_enchant" = 1
    "breach" = 1
    "backstabbing" = 1
    "decrepitude" = 1
    "bane_of_arthropods" = 1
    "sharpness" = 9
    "density" = 1
    "mending" = 1
    "soul_siphoner" = 1
    "implosion" = 1
    "growth_serum" = 1
    "ensnaring" = 1
    "smack" = 1
    "icy_thorns" = 1
    "wrecking" = 1
    "efficiency" = 1
    "natures_blessing" = 1
    "reactive" = 1
    "life_stealing" = 1
    "capturing" = 1
    "endless_quiver" = 1
    "ricochet" = 1
    "blessing" = 1
    "scavenger" = 1
    "shield_bash" = 1
    "lolths_curse" = 1
    "frostbite" = 1
    "boon_of_the_earth" = 4
    "soul_snatcher" = 1
    "reflective_defenses" = 1
    "self_sling" = 1
    "mystical_enlightenment" = 1
    "spectral_conjurer" = 1
    "miners_fervor" = 1
    "rebounding" = 1
    "multishot" = 1
    "worker_exploitation" = 1
    "tempting" = 1
    "swift_sneak" = 1
    "fire_aspect" = 1
    "unbreaking" =8
    "fortune" = 8
    "longevity" = 1
    "renewal" = 1
    "plague_bringer" = 1
    "destruction" = 1
    "stasis" = 1
    "breaking" = 1
    "sweeping_edge" = 1
    "vanishing_curse" = 1
    "loyalty" = 1
    "stable_footing" = 1
    "potent_poison" = 1
    "looting" = 1
    "knockback" = 1
    "discharge" = 1
}

$basePath = "E:\Projects\Minecraft\atm10_pmmo\atm_10_pack\src\main\resources\data"

Get-ChildItem -Path $basePath -Directory | ForEach-Object {
    $modName = $_.Name
    $enchantmentsPath = Join-Path -Path $_.FullName -ChildPath "pmmo\enchantments"

    if (Test-Path -Path $enchantmentsPath) {
        Get-ChildItem -Path $enchantmentsPath -Filter "*.json" | ForEach-Object {
            $enchantmentFile = $_.FullName
            $enchantmentName = $_.BaseName

            # Determine the tier for the enchantment
            $tier = $enchantTierMap[$enchantmentName]

            # Generate the levels array
            $levels = @()
            for ($i = 0; $i -le $tier; $i++) {
                if ($i -eq 0) {
                    $levels += @{}
                } else {
                    $mappedSkill = $enchantSkillMap[$enchantmentName]

                    if ($mappedSkill == -1) {
                        $levels += @{ "enchanting" = $skillLevels[$i] }
                    } else {
                        $skill = $skills[$mappedSkill]
                        $levels += @{ "enchanting" = $skillLevels[$i]; $skill = $skillLevels[$i] }
                    }
                }
            }

            # Create the JSON content
            $jsonContent = @{
                "override" = $true
                "levels"   = $levels
            } | ConvertTo-Json -Depth 3

            # Write the JSON content to the file
            Set-Content -Path $enchantmentFile -Value $jsonContent
        }
    }
}
